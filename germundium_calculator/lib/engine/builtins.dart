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
      // TODO (stage 3): e

      // --- Basic -------------------------------------------------------------
      FunctionEntry(
        name: 'sqrt',
        symbol: '√',
        category: FunctionCategory.basic,
        arity: const Arity.exactly(1),
        evaluate: _sqrt,
      ),
      // TODO (stage 3): abs

      // --- Logarithms --------------------------------------------------------
      // TODO (stage 3): ln, log (log accepts 1 or 2 arguments)

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
NumberValue _numberArg(List<Value> args, int index) =>
    throw UnimplementedError();

/// Converts [angle] to radians according to [mode].
double _toRadians(double angle, AngleMode mode) => throw UnimplementedError();

// ---------------------------------------------------------------------------
// Basic
// ---------------------------------------------------------------------------

Value _sqrt(List<Value> args, EvalContext context) =>
    throw UnimplementedError();

Value _abs(List<Value> args, EvalContext context) =>
    throw UnimplementedError();

// ---------------------------------------------------------------------------
// Logarithms
// ---------------------------------------------------------------------------

Value _ln(List<Value> args, EvalContext context) => throw UnimplementedError();

/// `log(x)` = base 10, `log(x, b)` = base b.
Value _log(List<Value> args, EvalContext context) =>
    throw UnimplementedError();

// ---------------------------------------------------------------------------
// Trigonometry
// ---------------------------------------------------------------------------

Value _sin(List<Value> args, EvalContext context) =>
    throw UnimplementedError();

Value _cos(List<Value> args, EvalContext context) =>
    throw UnimplementedError();

Value _tan(List<Value> args, EvalContext context) =>
    throw UnimplementedError();

// ---------------------------------------------------------------------------
// Stage 5 (bonus)
// ---------------------------------------------------------------------------

/// Largest r with r * r <= n, computed exactly (no double involved).
BigInt _integerSqrt(BigInt n) => throw UnimplementedError();
