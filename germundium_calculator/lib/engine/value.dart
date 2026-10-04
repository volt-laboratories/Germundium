// Value types of the engine (Phase 1, step 3).
// Skeleton only: signatures are fixed, every body is yours to write.

import 'package:rational/rational.dart';
import 'errors.dart';

sealed class Value {}

sealed class NumberValue extends Value {
  double toDouble();
  bool get isInteger;
  int? toIntOrNull();
}

final class ExactNumber extends NumberValue {
  final Rational value;

  ExactNumber(this.value);

  factory ExactNumber.fromInt(int n) => ExactNumber(Rational.fromInt(n));

  factory ExactNumber.parse(String source) =>
      ExactNumber(Rational.parse(source));

  @override
  bool operator ==(Object other) =>
      other is ExactNumber && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ExactNumber($value)';

  @override
  double toDouble() => value.toDouble();

  @override
  bool get isInteger => throw UnimplementedError();

  @override
  int? toIntOrNull() => throw UnimplementedError();
}

final class ApproxNumber extends NumberValue {
  final double value;

  ApproxNumber(this.value);

  @override
  bool operator ==(Object other) =>
      other is ApproxNumber && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ApproxNumber($value)';

  @override
  double toDouble() => value;

  @override
  bool get isInteger => throw UnimplementedError();

  @override
  int? toIntOrNull() => throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Operations
// ---------------------------------------------------------------------------

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

Value power(Value base, Value exponent) => throw UnimplementedError();

Value negate(Value a) => multiply(a, ExactNumber(Rational.fromInt(-1)));

Value factorial(Value a) => throw UnimplementedError();
