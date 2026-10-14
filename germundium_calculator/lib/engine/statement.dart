// Statements: what one line of input can be, and what executing it gives.
//
//   "f(x) = x^2" --parseStatement()--> Statement --Evaluator.execute()--> Outcome
//
// These are plain data classes. There is nothing to implement here,
// but read them before you start (see the task file, task 4).

import 'ast.dart';
import 'environment.dart';
import 'value.dart';

// ---------------------------------------------------------------------------
// Statements (produced by the parser)
// ---------------------------------------------------------------------------

/// One complete line of input.
///
/// A statement is NOT an [Expr]: it can only stand at the top level of a
/// line. That is why `2 + (x = 3)` cannot even be represented as a tree.
sealed class Statement {
  const Statement();
}

/// `2 + 3`: compute a value.
final class ExpressionStatement extends Statement {
  const ExpressionStatement(this.expr);

  final Expr expr;

  @override
  String toString() => 'ExpressionStatement($expr)';
}

/// `x = 2 + 3`: compute a value and store it under [name].
final class Assignment extends Statement {
  const Assignment(this.name, this.expr, this.position);

  /// The name on the left side of `=`.
  final String name;

  /// The expression on the right side of `=`.
  final Expr expr;

  /// Where [name] starts in the input.
  final int position;

  @override
  String toString() => 'Assignment($name, $expr)';
}

/// `f(x, y) = x^2 + y`: store a function under [name].
final class FunctionDefinition extends Statement {
  const FunctionDefinition(this.name, this.params, this.body, this.position);

  /// The name of the function.
  final String name;

  /// The parameters, in order.
  ///
  /// They are [Variable] nodes, not plain strings, so that every parameter
  /// keeps its own position for error messages (`f(x, x) = 1`).
  final List<Variable> params;

  /// The right side of `=`. It is stored, not evaluated, when the function
  /// is defined.
  final Expr body;

  /// Where [name] starts in the input.
  final int position;

  @override
  String toString() =>
      'FunctionDefinition($name(${params.map((p) => p.name).join(', ')}), '
      '$body)';
}

// ---------------------------------------------------------------------------
// Outcomes (produced by the evaluator)
// ---------------------------------------------------------------------------

/// What executing one [Statement] produced.
///
/// Every outcome carries the environment AFTER the line. The environment
/// that was used to execute the line is never changed.
sealed class Outcome {
  const Outcome(this.environment);

  /// The environment after this line.
  final Environment environment;
}

/// The outcome of an [ExpressionStatement].
final class Computed extends Outcome {
  const Computed(this.value, super.environment);

  final Value value;

  @override
  String toString() => 'Computed($value)';
}

/// The outcome of an [Assignment].
final class Assigned extends Outcome {
  const Assigned(this.name, this.value, super.environment);

  /// The name that now holds [value].
  final String name;

  /// The value of the right side.
  final Value value;

  @override
  String toString() => 'Assigned($name = $value)';
}

/// The outcome of a [FunctionDefinition].
final class FunctionDefined extends Outcome {
  const FunctionDefined(this.name, super.environment);

  /// The name of the new function.
  final String name;

  @override
  String toString() => 'FunctionDefined($name)';
}
