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
  double toDouble() => throw UnimplementedError();

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
  double toDouble() => throw UnimplementedError();

  @override
  bool get isInteger => throw UnimplementedError();

  @override
  int? toIntOrNull() => throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Operations
// ---------------------------------------------------------------------------

Value add(Value a, Value b) => throw UnimplementedError();

Value subtract(Value a, Value b) => throw UnimplementedError();

Value multiply(Value a, Value b) => throw UnimplementedError();

Value divide(Value a, Value b) => throw UnimplementedError();

Value power(Value base, Value exponent) => throw UnimplementedError();

Value negate(Value a) => throw UnimplementedError();

Value factorial(Value a) => throw UnimplementedError();
