/// Hierarchy:
///   Value (sealed)
///   └── NumberValue (sealed)
///       ├── ExactNumber   (Rational, e.g. 1/3, 0.1)
///       └── ApproxNumber  (double, e.g. sin(1), pi)
///   later: MatrixValue, FunctionValue
///
/// Rule: exact op exact = exact. As soon as one operand is approximate,
/// the result is approximate.
///
/// Value types know nothing about source positions (the evaluator adds them)
/// and nothing about display formatting (that belongs to the UI layer).
library;

import 'package:rational/rational.dart';
import 'errors.dart';

import 'dart:math' as math;

/// Maximum size (in bits) of numerator or denominator of an exact result.
/// Larger results throw a [MathError] instead of freezing the app.
const maxExactBits = 100000;

/// 2^63 as a double. Exactly representable, unlike 2^63 - 1.
/// The int range is [-2^63, 2^63 - 1], so valid doubles are in [-2^63, 2^63).
const double _twoPow63 = 9223372036854775808.0;

/// Base type of every value the engine can produce.
sealed class Value {}

/// A real number, either exact or approximate.
sealed class NumberValue extends Value {
  /// The value as a double. May lose precision for exact numbers.
  double toDouble();

  /// Whether the value is mathematically an integer (regardless of size).
  bool get isInteger;

  /// The value as an [int], or `null` if it is not an integer
  /// or does not fit into an [int].
  int? toIntOrNull();
}

/// An exact rational number.
///
/// Invariant: numerator and denominator never exceed [maxExactBits].
final class ExactNumber extends NumberValue {
  final Rational value;

  ExactNumber._(this.value);

  /// Creates an exact number. Throws a [MathError] if [value] is too large.
  factory ExactNumber(Rational value) {
    // abs() only for symmetry, denominator is always positive
    if (value.numerator.abs().bitLength > maxExactBits ||
        value.denominator.bitLength > maxExactBits) {
      throw MathError('Result too large');
    }

    return ExactNumber._(value);
  }

  factory ExactNumber.fromInt(int n) => ExactNumber(Rational.fromInt(n));

  /// Parses a number literal such as '0.1' or '1/3'.
  ///
  /// Goes through the public factory, so huge literals are rejected too.
  /// Rational.parse throws a FormatException (not a MathError)
  // for invalid input. Decide whether to wrap it. (decision no Wrap because no new Information can be given)
  factory ExactNumber.parse(String source) =>
      ExactNumber(Rational.parse(source));

  @override
  bool operator ==(Object other) =>
      other is ExactNumber && other.value == value;

  @override
  int get hashCode => value.hashCode;

  /// Debug representation only. Display formatting belongs to the UI layer.
  @override
  String toString() => 'ExactNumber($value)';

  @override
  double toDouble() => value.toDouble();

  @override
  bool get isInteger => value.isInteger;

  @override
  int? toIntOrNull() {
    if (!value.isInteger) return null;
    final big = value.toBigInt();
    if (!big.isValidInt) return null;
    return big.toInt();
  }
}

/// An approximate real number.
///
/// Invariant: the value is always finite (never NaN or infinite).
final class ApproxNumber extends NumberValue {
  final double value;

  ApproxNumber._(this.value);

  /// Creates an approximate number.
  ///
  /// Throws a [MathError] if [value] is NaN or infinite. Underflow to 0.0
  /// is accepted on purpose.
  factory ApproxNumber(double value) {
    if (value.isNaN) {
      throw MathError('Result is not a real number');
    }
    if (value.isInfinite) {
      throw MathError('Result too large');
    }
    return ApproxNumber._(value);
  }

  @override
  bool operator ==(Object other) =>
      other is ApproxNumber && other.value == value;

  @override
  int get hashCode => value.hashCode;

  /// Debug representation only. Display formatting belongs to the UI layer.
  @override
  String toString() => 'ApproxNumber($value)';

  @override
  double toDouble() => value;

  // Safe because of the invariant: NaN or infinity can never reach this.
  @override
  bool get isInteger => value == value.roundToDouble();

  @override
  int? toIntOrNull() {
    if (!isInteger) return null;
    if (value < -_twoPow63 || value >= _twoPow63) return null;
    return value.toInt();
  }
}

// ---------------------------------------------------------------------------
// Operations
// ---------------------------------------------------------------------------
//
// Operations are top-level functions instead of methods (decision of task 8),
// so binary operations can switch over both operands at once.

/// Applies [exactOp] if both operands are exact, otherwise [approxOp].
///
/// Only suitable for operations where exact op exact is always exact
/// (+, -, *, /). Not suitable for power.
NumberValue _combine(
  NumberValue a,
  NumberValue b,
  Rational Function(Rational, Rational) exactOp,
  double Function(double, double) approxOp,
) {
  return switch ((a, b)) {
    (ExactNumber(value: final x), ExactNumber(value: final y)) => ExactNumber(
      exactOp(x, y),
    ),
    _ => ApproxNumber(approxOp(a.toDouble(), b.toDouble())),
  };
}

/// Returns [a] + [b].
Value add(Value a, Value b) {
  return switch ((a, b)) {
    (NumberValue x, NumberValue y) => _combine(
      x,
      y,
      (l, r) => l + r,
      (l, r) => l + r,
    ),
  };
}

/// Returns [a] - [b].
Value subtract(Value a, Value b) {
  return switch ((a, b)) {
    (NumberValue x, NumberValue y) => _combine(
      x,
      y,
      (l, r) => l - r,
      (l, r) => l - r,
    ),
  };
}

/// Returns [a] * [b].
Value multiply(Value a, Value b) {
  return switch ((a, b)) {
    (NumberValue x, NumberValue y) => _combine(
      x,
      y,
      (l, r) => l * r,
      (l, r) => l * r,
    ),
  };
}

/// Returns [a] / [b]. Throws a [MathError] on division by zero,
/// for exact and approximate divisors alike.
Value divide(Value a, Value b) {
  return switch ((a, b)) {
    (NumberValue x, NumberValue y) => _combine(
      x,
      y,
      (l, r) =>
          r == Rational.zero ? throw MathError('Division by zero') : l / r,
      (l, r) => r == 0.0 ? throw MathError('Division by zero') : l / r,
    ),
  };
}

/// Returns [base] raised to [exponent].
///
/// Stays exact for an exact base with an exact integer exponent.
/// Everything else is computed approximately; NaN (e.g. (-8)^0.5) and
/// overflow are turned into a [MathError] by the [ApproxNumber] factory.
Value power(Value base, Value exponent) {
  return switch ((base, exponent)) {
    (ExactNumber b, ExactNumber e) when e.isInteger => _exactIntegerPower(
      b.value,
      e.value,
    ),
    // math.pow would return Infinity here, which would surface as
    // 'Result too large'. Catch it first to give the correct message.
    (NumberValue b, NumberValue e)
        when b.toDouble() == 0.0 && e.toDouble() < 0 =>
      throw MathError('Zero cannot be raised to a negative power'),
    (NumberValue b, NumberValue e) => ApproxNumber(
      math.pow(b.toDouble(), e.toDouble()).toDouble(),
    ),
  };
}

/// Raises an exact [base] to an exact integer [exponent].
///
/// The result stays exact. Throws a [MathError] for zero to a negative
/// power and when the result would exceed [maxExactBits].
Value _exactIntegerPower(Rational base, Rational exponent) {
  assert(
    exponent.isInteger,
    '_exactIntegerPower called with non-integer exponent',
  );

  // An integer Rational has denominator 1, so its numerator is the exponent.
  // Using the BigInt directly avoids overflow for huge exponents.
  final BigInt k = exponent.numerator;

  // x^0 = 1 for every x, including 0^0 (convention).
  if (k == BigInt.zero) {
    return ExactNumber.fromInt(1);
  }

  if (base == Rational.zero) {
    if (k.isNegative) {
      throw MathError('Zero cannot be raised to a negative power');
    }
    return ExactNumber.fromInt(0);
  }

  // 1 and -1 never grow, so any exponent is allowed.
  if (base == Rational.one) {
    return ExactNumber.fromInt(1);
  }
  if (base == -Rational.one) {
    return ExactNumber.fromInt(k.isEven ? 1 : -1);
  }

  // Estimate the result size before computing: log2(n^k) = k * log2(n).
  // The estimate can be up to 2x too low (e.g. base 3); the ExactNumber
  // factory catches the rest after computing.
  final BigInt absK = k.abs();
  final BigInt limit = BigInt.from(maxExactBits);
  final BigInt numeratorBits =
      BigInt.from(base.numerator.abs().bitLength - 1) * absK;
  final BigInt denominatorBits =
      BigInt.from(base.denominator.bitLength - 1) * absK;
  if (numeratorBits > limit || denominatorBits > limit) {
    throw MathError('Result too large');
  }

  // Safe now: base is not 0 or ±1, so at least one estimate is >= absK.
  // Therefore absK <= maxExactBits and fits into an int.
  final int n = absK.toInt();

  // Negative exponent: (a/b)^-n = (b/a)^n
  final (BigInt top, BigInt bottom) = k.isNegative
      ? (base.denominator, base.numerator)
      : (base.numerator, base.denominator);

  return ExactNumber(Rational(top.pow(n), bottom.pow(n)));
}

/// Returns -[a].
Value negate(Value a) => multiply(a, ExactNumber(Rational.fromInt(-1)));

/// Returns [x]! for non-negative integers.
///
/// Integer-valued approximate numbers (e.g. 5.0) are accepted.
/// Throws a [MathError] for negative or non-integer input and when the
/// result would exceed [maxExactBits].
Value factorial(Value x) {
  final BigInt n = switch ((x)) {
    (ExactNumber f) =>
      f.isInteger
          ? f.value >= Rational.zero
                ? f.value.numerator
                : throw MathError(
                    'Factorial is only defined for non-negative integers',
                  )
          : throw MathError(
              'Factorial is only defined for non-negative integers',
            ),
    (ApproxNumber f) =>
      f.isInteger
          ? f.value >= 0
                ? BigInt.from(f.value)
                : throw MathError(
                    'Factorial is only defined for non-negative integers',
                  )
          : throw MathError('Factorial requires an exact integer'),
  };

  // Upper bound: n! <= n^n, so bits(n!) <= n * bitLength(n).
  final BigInt bitsUpperBound = n * BigInt.from(n.bitLength);
  if (bitsUpperBound > BigInt.from(maxExactBits)) {
    throw MathError('Result too large');
  }

  // Safe now: bitsUpperBound >= n, so n <= maxExactBits fits into an int.
  BigInt fac = BigInt.one;
  final int count = n.toInt();

  for (int i = 1; i <= count; i++) {
    fac = fac * BigInt.from(i);
  }

  return ExactNumber(Rational(fac));
}
