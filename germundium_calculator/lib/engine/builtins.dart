// Skeleton: two entries are registered as examples, every other entry
// and every function body is yours to write.

import 'dart:math' as math;

import 'package:rational/rational.dart';

import 'errors.dart';
import 'registry.dart';
import 'value.dart';

/// Builds the registry with all built-in constants and functions.
FunctionRegistry standardRegistry() => FunctionRegistry([
  // --- Constants ---------------------------------------------------------
  ConstantEntry(name: 'pi', symbol: 'π', value: ApproxNumber(math.pi)),
  ConstantEntry(name: 'e', symbol: 'e', value: ApproxNumber(math.e)),

  // --- Basic -------------------------------------------------------------
  FunctionEntry(
    name: 'sqrt',
    symbol: '√',
    category: FunctionCategory.basic,
    arity: const Arity.exactly(1),
    evaluate: _sqrt,
  ),
  FunctionEntry(
    name: 'abs',
    symbol: '| |',
    category: FunctionCategory.basic,
    arity: const Arity.exactly(1),
    evaluate: _abs,
  ),

  // --- Logarithms --------------------------------------------------------
  FunctionEntry(
    name: 'ln',
    symbol: 'ln()',
    category: FunctionCategory.logarithm,
    arity: Arity.exactly(1),
    evaluate: _ln,
  ),
  FunctionEntry(
    name: 'log',
    symbol: 'log()',
    category: FunctionCategory.logarithm,
    arity: Arity.range(1, 2),
    evaluate: _log,
  ),

  // --- Trigonometry ------------------------------------------------------
  // TODO (stage 4): sin, cos, tan
]);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns argument [index] as a number.
///
/// Today every Value is a NumberValue. Once MatrixValue exists, this is
/// where "sin of a matrix" gets rejected.
NumberValue _numberArg(List<Value> args, int index) => switch (args[index]) {
  NumberValue n => n,
};

/// Converts [angle] to radians according to [mode].
double _toRadians(double angle, AngleMode mode) => throw UnimplementedError();

// ---------------------------------------------------------------------------
// Basic
// ---------------------------------------------------------------------------

//arity == 1
Value _sqrt(List<Value> args, EvalContext context) {
  final first = _numberArg(args, 0);
  final bool neg = switch (first) {
    ExactNumber n => n.value < Rational.zero,
    ApproxNumber n => n.value < 0.0,
  };

  if (neg) {
    throw MathError('the result is not real (sqirt) number');
  }

  return switch (first) {
    ExactNumber n => _exactSqrt(n),
    ApproxNumber n => ApproxNumber(math.sqrt(n.value)),
  };
}

Value _exactSqrt(ExactNumber n) {
  final numerator = _exactIntegerSqrt(n.value.numerator);
  final denominator = _exactIntegerSqrt(n.value.denominator);

  if (numerator != null && denominator != null) {
    return ExactNumber(Rational(numerator, denominator));
  } else {
    return ApproxNumber(math.sqrt(n.value.toDouble()));
  }
}

/// Returns the integer square root of [n] if [n] is a perfect square,
/// otherwise null.
BigInt? _exactIntegerSqrt(BigInt n) {
  final root = math.sqrt(n.toDouble());
  if (!root.isFinite) return null; // n is beyond the double range

  final candidate = BigInt.from(root.roundToDouble());
  return candidate * candidate == n ? candidate : null;
}

//arity == 1
Value _abs(List<Value> args, EvalContext context) {
  final first = _numberArg(args, 0);

  return switch (first) {
    ExactNumber n => n.value < Rational.zero ? negate(n) : n,
    ApproxNumber n => ApproxNumber(n.value.abs()),
  };
}

// ---------------------------------------------------------------------------
// Logarithms
// ---------------------------------------------------------------------------

Value _ln(List<Value> args, EvalContext context) {
  final first = _numberArg(args, 0);
  final bool outOfDomain = switch (first) {
    ExactNumber n => n.value <= Rational.zero,
    ApproxNumber n => n.value <= 0.0,
  };

  if (outOfDomain) {
    throw MathError('ln() cannot be calculated for x <= 0');
  }

  return switch (first) {
    ExactNumber n => ApproxNumber(math.log(n.value.toDouble())),
    ApproxNumber n => ApproxNumber(math.log(n.value)),
  };
}

/// `log(x)` = base 10, `log(x, b)` = base b.
Value _log(List<Value> args, EvalContext context) {
  final x = _numberArg(args, 0);
  final b = args.length > 1 ? _numberArg(args, 1) : ApproxNumber(10);

  final bool outOfDomain = switch (x) {
    ExactNumber n => n.value <= Rational.zero,
    ApproxNumber n => n.value <= 0.0,
  };
  final bool invalidBase = switch (b) {
    ExactNumber n => n.value <= Rational.zero || n.value == Rational.one,
    ApproxNumber n => n.value <= 0.0 || n.value == 1,
  };

  if (outOfDomain) {
    throw MathError('log() cannot be calculated for x <= 0');
  } else if (invalidBase) {
    throw MathError('log() basis has to be larger than 0 and not equal to 1');
  }

  return switch ((x, b)) {
    (NumberValue val, NumberValue bas) => ApproxNumber(
      math.log(val.toDouble()) / math.log(bas.toDouble()),
    ),
  };
}

// ---------------------------------------------------------------------------
// Trigonometry
// ---------------------------------------------------------------------------

Value _sin(List<Value> args, EvalContext context) => throw UnimplementedError();

Value _cos(List<Value> args, EvalContext context) => throw UnimplementedError();

Value _tan(List<Value> args, EvalContext context) => throw UnimplementedError();

// ---------------------------------------------------------------------------
// Stage 5 (bonus)
// ---------------------------------------------------------------------------

/// Largest r with r * r <= n, computed exactly (no double involved).
BigInt _integerSqrt(BigInt n) => throw UnimplementedError();
