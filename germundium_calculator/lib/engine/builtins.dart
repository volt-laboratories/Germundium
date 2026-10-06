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
  FunctionEntry(
    name: 'sin',
    symbol: 'sin( )',
    category: FunctionCategory.trigonometry,
    arity: Arity.exactly(1),
    evaluate: _sin,
  ),
  FunctionEntry(
    name: 'cos',
    symbol: 'cos( )',
    category: FunctionCategory.trigonometry,
    arity: Arity.exactly(1),
    evaluate: _cos,
  ),
  FunctionEntry(
    name: 'tan',
    symbol: 'tan( )',
    category: FunctionCategory.trigonometry,
    arity: Arity.exactly(1),
    evaluate: _tan,
  ),
]);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
/// 90 and 180 as exact rationals, used for the pole check in [_tan].
final _r90 = Rational.fromInt(90);
final _r180 = Rational.fromInt(180);
final _r270 = Rational.fromInt(270);

/// Returns argument [index] as a number.
///
/// Today every Value is a NumberValue. Once MatrixValue exists, this is
/// where "sin of a matrix" gets rejected.
NumberValue _numberArg(List<Value> args, int index) => switch (args[index]) {
  NumberValue n => n,
};

/// Converts [angle] to radians according to [mode].
double _toRadians(double angle, AngleMode mode) => switch (mode) {
  AngleMode.degrees => angle / 180 * math.pi,
  AngleMode.radians => angle,
};

/// Converts [angle] from radians to the unit of [mode].
/// Counterpart of [_toRadians], used for results of asin, acos, atan.
double _fromRadians(double angle, AngleMode mode) => switch (mode) {
  AngleMode.degrees => angle / math.pi * 180,
  AngleMode.radians => angle,
};

// ---------------------------------------------------------------------------
// Basic
// ---------------------------------------------------------------------------

Value _sqrt(List<Value> args, EvalContext context) {
  final x = _numberArg(args, 0);

  final isNegative = switch (x) {
    ExactNumber n => n.value < Rational.zero,
    ApproxNumber n => n.value < 0.0,
  };
  if (isNegative) {
    throw MathError('sqrt is undefined for negative numbers');
  }

  if (x is ExactNumber) {
    final exact = _exactSqrt(x.value);
    if (exact != null) {
      return ExactNumber(exact);
    }
  }

  return ApproxNumber(math.sqrt(x.toDouble()));
}

//My old Versions
// Value _sqrt(List<Value> args, EvalContext context) {
//   final first = _numberArg(args, 0);
//   final bool neg = switch (first) {
//     ExactNumber n => n.value < Rational.zero,
//     ApproxNumber n => n.value < 0.0,
//   };

//   if (neg) {
//     throw MathError('the result is not real (sqirt) number');
//   }

//   return switch (first) {
//     ExactNumber n => _exactSqrt(n),
//     ApproxNumber n => ApproxNumber(math.sqrt(n.value)),
//   };
// }

// Value _exactSqrt(ExactNumber n) {
//   final numerator = _exactIntegerSqrt(n.value.numerator);
//   final denominator = _exactIntegerSqrt(n.value.denominator);

//   if (numerator != null && denominator != null) {
//     return ExactNumber(Rational(numerator, denominator));
//   } else {
//     return ApproxNumber(math.sqrt(n.value.toDouble()));
//   }
// }

// /// Returns the integer square root of [n] if [n] is a perfect square,
// /// otherwise null.
// BigInt? _exactIntegerSqrt(BigInt n) {
//   final root = math.sqrt(n.toDouble());
//   if (!root.isFinite) return null; // n is beyond the double range

//   final candidate = BigInt.from(root.roundToDouble());
//   return candidate * candidate == n ? candidate : null;
// }

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
    ExactNumber n =>
      n.value == Rational.one
          ? ExactNumber.fromInt(0)
          : ApproxNumber(math.log(n.value.toDouble())),
    ApproxNumber n => ApproxNumber(math.log(n.value)),
  };
}

/// `log(x)` = base 10, `log(x, b)` = base b.
Value _log(List<Value> args, EvalContext context) {
  final x = _numberArg(args, 0);
  final b = args.length > 1 ? _numberArg(args, 1) : ExactNumber.fromInt(10);

  final bool outOfDomain = switch (x) {
    ExactNumber n => n.value <= Rational.zero,
    ApproxNumber n => n.value <= 0.0,
  };

  if (x.toDouble() == 1.0) {
    return ExactNumber.fromInt(0);
  }

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
    (ExactNumber val, NumberValue _) when val.value == Rational.one =>
      ExactNumber.fromInt(0),
    (ExactNumber val, ExactNumber bas)
        when _exactIntegerLog(val.value, bas.value.toBigInt()) != null &&
            bas.isInteger =>
      ExactNumber.fromInt(_exactIntegerLog(val.value, bas.value.toBigInt())!),
    (NumberValue val, NumberValue bas) => ApproxNumber(
      math.log(val.toDouble()) / math.log(bas.toDouble()),
    ),
  };
}

/// Returns k if n == base^k for some k >= 0, otherwise null.
/// Requires n > 0 and base >= 2.
int? _exactPowerExponent(BigInt n, BigInt base) {
  assert(n > BigInt.zero && base >= BigInt.two);

  var rest = n;
  var exponent = 0;
  while (rest % base == BigInt.zero) {
    rest = rest ~/ base;
    exponent++;
  }
  return rest == BigInt.one ? exponent : null;
}

/// Returns k if x == base^k for some integer k (also negative),
/// otherwise null. Requires x > 0 and base >= 2.
int? _exactIntegerLog(Rational x, BigInt base) {
  assert(x > Rational.zero);

  if (x.denominator == BigInt.one) {
    return _exactPowerExponent(x.numerator, base);
  }
  if (x.numerator == BigInt.one) {
    final k = _exactPowerExponent(x.denominator, base);
    return k == null ? null : -k;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Trigonometry
// ---------------------------------------------------------------------------

//CHECK: ignore exact values for double?
//CHECK: Why only in degree Mode and not to for 2*Pi format
Value _sin(List<Value> args, EvalContext context) {
  final arg = _numberArg(args, 0);
  final exact = switch (arg) {
    ExactNumber n
        when context.angleMode == AngleMode.degrees ||
            n.value == Rational.zero =>
      _exactSinDegrees(n.value),
    _ => null,
  };

  return exact != null
      ? ExactNumber(exact)
      : ApproxNumber(math.sin(_toRadians(arg.toDouble(), context.angleMode)));
}

Value _cos(List<Value> args, EvalContext context) {
  final arg = _numberArg(args, 0);
  final exact = switch (arg) {
    ExactNumber n
        when context.angleMode == AngleMode.degrees ||
            n.value == Rational.zero =>
      _exactCosDegrees(n.value),
    _ => null,
  };

  return exact != null
      ? ExactNumber(exact)
      : ApproxNumber(math.cos(_toRadians(arg.toDouble(), context.angleMode)));
}

Value _tan(List<Value> args, EvalContext context) {
  final arg = _numberArg(args, 0);
  final isDegrees = context.angleMode == AngleMode.degrees;

  final isPole =
      isDegrees &&
      switch (arg) {
        ExactNumber n => _isTanPoleDegrees(n.value),
        ApproxNumber n => n.value % 180 == 90,
      };

  if (isPole) {
    throw MathError('tan is undefined at odd multiples of 90°');
  }

  final exact = switch (arg) {
    ExactNumber n when isDegrees || n.value == Rational.zero =>
      _exactTanDegrees(n.value),
    _ => null,
  };

  return exact != null
      ? ExactNumber(exact)
      : ApproxNumber(math.tan(_toRadians(arg.toDouble(), context.angleMode)));
}

/// Whether tan has a pole at the given angle in degrees (90° + k·180°).
bool _isTanPoleDegrees(Rational degrees) {
  final reduced = _reduceDegrees(degrees);
  return reduced == _r90 || reduced == _r270;
}

/// Exact tangent for an angle in degrees, or null if the result
/// is not rational. Poles (90°, 270°) also return null; they must be
/// rejected by the caller before this is used.
Rational? _exactTanDegrees(Rational degrees) {
  final reduced = _reduceDegrees(degrees);

  if (!reduced.isInteger) {
    return null;
  }

  return switch (reduced.toBigInt().toInt()) {
    0 || 180 => Rational.zero,
    45 || 225 => Rational.one,
    135 || 315 => Rational.fromInt(-1),
    _ => null,
  };
}

/// Exact cosine for an angle in degrees, or null if the result
/// is not rational. Uses cos(x) = sin(x + 90°).
Rational? _exactCosDegrees(Rational degrees) {
  return _exactSinDegrees(degrees + Rational.fromInt(90));
}

Rational? _exactSinDegrees(Rational degrees) {
  final redDegree = _reduceDegrees(degrees);

  if (!redDegree.isInteger) {
    return null;
  }

  return switch (redDegree.toBigInt().toInt()) {
    0 || 180 => Rational.zero,
    30 || 150 => Rational(BigInt.one, BigInt.two),
    90 => Rational.one,
    210 || 330 => Rational(BigInt.from(-1), BigInt.two),
    270 => Rational.fromInt(-1),
    _ => null,
  };
}

/// Reduces an angle in degrees to the interval [0, 360).
Rational _reduceDegrees(Rational degrees) {
  final fullTurn = Rational.fromInt(360);
  return degrees - Rational((degrees / fullTurn).floor()) * fullTurn;
}

// ---------------------------------------------------------------------------
// Stage 5 (bonus)
// ---------------------------------------------------------------------------

/// Largest r with r * r <= n, computed exactly (no double involved).
BigInt _integerSqrt(BigInt n) {
  assert(!n.isNegative);
  if (n < BigInt.two) {
    return n; // sqrt(0) = 0, sqrt(1) = 1
  }

  // Start value >= sqrt(n): if n has L bits, then n < 2^L,
  // so sqrt(n) < 2^(L/2) <= 2^ceil(L/2).
  var x = BigInt.one << ((n.bitLength + 1) ~/ 2);

  while (true) {
    final y = (x + n ~/ x) >> 1;
    if (y >= x) {
      return x;
    }
    x = y;
  }
}

/// Exact square root of a non-negative rational, or null if it is
/// irrational. Uses sqrt(p/q) = sqrt(p) / sqrt(q).
Rational? _exactSqrt(Rational x) {
  assert(x >= Rational.zero);

  final p = _integerSqrt(x.numerator);
  if (p * p != x.numerator) {
    return null;
  }

  final q = _integerSqrt(x.denominator);
  if (q * q != x.denominator) {
    return null;
  }

  return Rational(p, q);
}
