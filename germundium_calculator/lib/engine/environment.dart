// The environment: every name the user has defined.
//
// Plain data. No math, and no registry: the environment does not know
// which names are built in. Checking that is the job of the evaluator
// (step 4 in the task file).
//
// An Environment is immutable. "Changing" it means creating a new one,
// the old one stays exactly as it was (see Konzept 1 in the task file).
//
// The public API (`Environment.empty`, `lookup`, `define`, `names`) is
// fixed by test/environment_test.dart. The bodies are yours to write.

import 'ast.dart';
import 'value.dart';

/// The name under which the result of the last line is stored.
const ansName = 'ans';

// ---------------------------------------------------------------------------
// Bindings
// ---------------------------------------------------------------------------

/// What a user-defined name stands for.
///
/// This mirrors the registry: a [VariableBinding] is the user's version of
/// a ConstantEntry, a [FunctionBinding] the user's version of a
/// FunctionEntry.
sealed class Binding {
  const Binding();
}

/// `x = 3`: the name stands for a value.
final class VariableBinding extends Binding {
  const VariableBinding(this.value);

  final Value value;

  @override
  String toString() => 'VariableBinding($value)';
}

/// `f(x) = x^2`: the name stands for a function.
final class FunctionBinding extends Binding {
  const FunctionBinding(this.params, this.body);

  /// The parameter names, in order.
  final List<String> params;

  /// The expression that computes the result. Positions inside it point
  /// into the line where the function was DEFINED, not where it is called
  /// (see Konzept 4 in the task file).
  final Expr body;

  // Variant B (task 29) adds a field here.

  @override
  String toString() => 'FunctionBinding((${params.join(', ')}) => $body)';
}

// ---------------------------------------------------------------------------
// Environment
// ---------------------------------------------------------------------------

/// All names the user has defined, each with its [Binding].
///
/// Immutable: [define] returns a new environment and leaves this one
/// unchanged.
final class Environment {
  // Private on purpose (task 8): nobody outside this file can hand in a
  // map and keep a reference to it.
  const Environment._(this._bindings);

  /// The environment before the user has defined anything.
  static const Environment empty = Environment._({});

  final Map<String, Binding> _bindings;

  /// The binding of [name], or `null` if the user has not defined it.
  Binding? lookup(String name) {
    // TODO (step 1)
    throw UnimplementedError();
  }

  /// A new environment in which [name] has [binding].
  ///
  /// If [name] already exists, its old binding is replaced, whatever kind
  /// it was: one name has one meaning. This environment is not changed.
  Environment define(String name, Binding binding) {
    // TODO (step 1)
    throw UnimplementedError();
  }

  /// Every defined name, each once, in the order of their first definition.
  Iterable<String> get names {
    // TODO (step 1)
    throw UnimplementedError();
  }

  @override
  String toString() => 'Environment(${_bindings.keys.join(', ')})';
}
