// Skeleton only: types and signatures are fixed, every body marked with
// UnimplementedError or TODO is yours to write.

import 'errors.dart';
import 'value.dart';

// ---------------------------------------------------------------------------
// Settings passed into every function call
// ---------------------------------------------------------------------------

/// Unit used to interpret angles in trigonometric functions.
enum AngleMode { radians, degrees }

/// Settings that influence how a function is evaluated.
///
/// Passed explicitly into every call, never stored globally. This way a test
/// can evaluate the same expression in DEG and RAD side by side, and the UI
/// (phase 4) only has to build a new context when the user changes a setting.
final class EvalContext {
  final AngleMode angleMode;

  const EvalContext({this.angleMode = AngleMode.radians});
}

// ---------------------------------------------------------------------------
// Entry metadata
// ---------------------------------------------------------------------------

/// Topic a registry entry belongs to. Used later by the overlay menu
/// (phase 4) to group buttons.
enum FunctionCategory { constant, basic, trigonometry, logarithm }

/// How many arguments a function accepts: from [min] to [max] (inclusive).
///
/// A `null` [max] means "no upper limit" (e.g. a future `max(a, b, ...)`).
final class Arity {
  final int min;
  final int? max;

  // TODO (stage 1, task 7): add asserts to the initializer lists
  // (min must not be negative, max must not be smaller than min).
  const Arity.exactly(int n)
      : min = n,
        max = n;

  const Arity.range(this.min, int this.max);

  const Arity.atLeast(this.min) : max = null;

  /// Whether a call with [count] arguments is allowed.
  bool accepts(int count) => throw UnimplementedError();

  /// Human-readable form for error messages:
  /// `'1'`, `'1 to 2'`, `'at least 1'`.
  @override
  String toString() => throw UnimplementedError();
}

/// Signature every built-in function implements.
///
/// The arguments are already evaluated values. The argument count has
/// already been checked by [FunctionRegistry.invoke] before this is called.
typedef FunctionImpl = Value Function(List<Value> args, EvalContext context);

// ---------------------------------------------------------------------------
// Entries
// ---------------------------------------------------------------------------

/// One thing the user can type by name: a constant or a function.
sealed class RegistryEntry {
  /// Identifier as it appears in an expression, e.g. `'sqrt'`, `'pi'`.
  final String name;

  /// Label shown on buttons, e.g. `'√'`, `'π'`.
  final String symbol;

  final FunctionCategory category;

  const RegistryEntry({
    required this.name,
    required this.symbol,
    required this.category,
  });
}

/// A named value such as π. Used without parentheses: `2pi`, not `pi()`.
final class ConstantEntry extends RegistryEntry {
  final Value value;

  ConstantEntry({
    required super.name,
    required super.symbol,
    required this.value,
  }) : super(category: FunctionCategory.constant);
}

/// A named function such as `sin`. Used with parentheses: `sin(x)`.
final class FunctionEntry extends RegistryEntry {
  final Arity arity;
  final FunctionImpl evaluate;

  FunctionEntry({
    required super.name,
    required super.symbol,
    required super.category,
    required this.arity,
    required this.evaluate,
  });
}

// ---------------------------------------------------------------------------
// Registry
// ---------------------------------------------------------------------------

/// Lookup table for all built-in constants and functions.
///
/// Immutable after construction. User-defined functions (`f(x) = x²`)
/// do NOT go here; they belong to the environment (stage 6).
final class FunctionRegistry {
  final Map<String, RegistryEntry> _entries = {};

  /// Builds the registry from [entries].
  ///
  /// Throws an [ArgumentError] if two entries share a name.
  FunctionRegistry(Iterable<RegistryEntry> entries) {
    // TODO (stage 2, task 10)
    throw UnimplementedError();
  }

  /// The entry called [name], or `null` if there is none.
  /// Names are case-sensitive.
  RegistryEntry? lookup(String name) => throw UnimplementedError();

  /// All entries, in registration order.
  Iterable<RegistryEntry> get entries => throw UnimplementedError();

  /// All entries of [category], in registration order.
  Iterable<RegistryEntry> inCategory(FunctionCategory category) =>
      throw UnimplementedError();

  /// Calls the function [name] with [args].
  ///
  /// This is the ONE place where the argument count is checked.
  /// Throws a [CalcError] if [name] is unknown, is a constant, or
  /// [args] has the wrong length.
  Value invoke(String name, List<Value> args, EvalContext context) =>
      throw UnimplementedError();
}
