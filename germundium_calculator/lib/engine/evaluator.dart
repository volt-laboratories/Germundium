// Skeleton for stage 5: the evaluator.
//
// The public API (`calculate`, `Evaluator`, `Evaluator.evaluate`) is fixed
// by test/evaluator_test.dart. The private helpers are a suggestion:
// rename, merge or delete them as you like. Every body is yours to write.

import 'ast.dart';
import 'builtins.dart';
import 'errors.dart';
import 'parser.dart';
import 'registry.dart';
import 'value.dart';
import 'environment.dart';
import 'statement.dart';

// ---------------------------------------------------------------------------
// Entry point for the app
// ---------------------------------------------------------------------------

/// Parses and executes one line of input in one step.
///
/// This is what the app will call when the user presses `=` (phase 3).
/// [environment] holds everything the user defined so far. The returned
/// [Outcome] carries the new one; [environment] itself never changes.
///
/// Uses the built-in registry from [standardRegistry] unless [registry]
/// is given.
Outcome run(
  String input, {
  Environment environment = Environment.empty,
  EvalContext context = const EvalContext(),
  FunctionRegistry? registry,
}) {
  // TODO (step 7)
  throw UnimplementedError();
}

/// Parses and evaluates [input] in one step.
///
/// This is what the app will call when the user presses `=` (phase 3).
/// Uses the built-in registry from [standardRegistry] unless [registry]
/// is given.
///
/// Throws a [SyntaxError] if [input] cannot be parsed (see [parse]), and
/// another [CalcError] if it cannot be evaluated. Either way,
/// [CalcError.position] points into [input].
Value calculate(
  String input, {
  EvalContext context = const EvalContext(),
  FunctionRegistry? registry,
}) {
  final p = parse(input);
  final e = Evaluator(
    registry: registry ?? standardRegistry(),
    context: context,
  );

  return e.evaluate(p);
}

// ---------------------------------------------------------------------------
// Evaluator
// ---------------------------------------------------------------------------

/// Computes the [Value] of an [Expr] tree.
///
/// The evaluator does almost no math itself: operators are delegated to
/// the functions in value.dart, names to the [registry]. Its own jobs are
/// walking the tree, resolving names, and attaching positions to errors.
///
/// It keeps no state between two calls of [evaluate]: the same tree gives
/// the same result for the same registry and context.
final class Evaluator {
  Evaluator({
    required this.registry,
    this.context = const EvalContext(),
    this.environment = Environment.empty,
  });

  /// Everything the user defined: variables, functions and `ans`.
  ///
  /// The evaluator never changes it. [execute] returns a new one instead.
  final Environment environment;

  /// Which constants and functions exist.
  final FunctionRegistry registry;

  /// Settings such as DEG / RAD, passed on to every function call.
  final EvalContext context;

  /// Executes one line of input and returns what happened, together
  /// with the new environment.
  ///
  /// Throws a [CalcError] with a position if the line cannot be executed.
  /// Nothing is stored in that case.
  Outcome execute(Statement statement) {
    // TODO (step 4): one exhaustive switch over the statement type,
    // each case delegates to one of the helpers. No `default`.
    throw UnimplementedError();
  }

  // Stage 6 will add a third field here: the environment with user
  // variables, history references and user-defined functions.

  /// Computes the value of [expr].
  ///
  /// Throws a [CalcError] whose [CalcError.position] points at the
  /// innermost node where the problem occurred.
  Value evaluate(Expr expr) {
    return _at(
      expr.position,
      () => switch (expr) {
        (NumberLiteral number) => _number(number),
        (Negate negate) => _negate(negate),
        (Factorial factorial) => _factorial(factorial),
        (BinaryOp binaryOp) => _binary(binaryOp),
        (Variable variable) => _variable(variable),
        (Call call) => _call(call),
      },
    );
  }

  // -------------------------------------------------------------------------
  // Stage 1: numbers and operators
  // -------------------------------------------------------------------------

  /// `42`, `0.1`: the lexeme becomes an exact number.
  Value _number(NumberLiteral node) => ExactNumber.parse(node.lexeme);

  /// `-x`
  Value _negate(Negate node) => negate(evaluate(node.operand));

  /// `x!`
  Value _factorial(Factorial node) => factorial(evaluate(node.operand));

  /// `a + b`, `a - b`, `a * b`, `a / b`, `a ^ b`, and implicit `2x`.
  Value _binary(BinaryOp node) {
    return switch (node.op) {
      BinaryOperator.add => add(evaluate(node.left), evaluate(node.right)),
      BinaryOperator.subtract => subtract(
        evaluate(node.left),
        evaluate(node.right),
      ),
      BinaryOperator.multiply => multiply(
        evaluate(node.left),
        evaluate(node.right),
      ),
      BinaryOperator.divide => divide(
        evaluate(node.left),
        evaluate(node.right),
      ),
      BinaryOperator.power => power(evaluate(node.left), evaluate(node.right)),
    };
  }

  // -------------------------------------------------------------------------
  // Stage 2: error positions
  // -------------------------------------------------------------------------

  /// Runs [compute] and returns its result.
  ///
  /// If [compute] throws a [CalcError] that has no position yet, throws
  /// the same kind of error again, with [position] filled in. A
  /// [CalcError] that already has a position, and anything that is not a
  /// [CalcError], passes through unchanged.
  Value _at(int position, Value Function() compute) {
    try {
      return compute();
    } on CalcError catch (e) {
      if (e.position == null) {
        throw _withPosition(e, position);
      } else {
        rethrow;
      }
    }
  }

  /// A copy of [error] with [position], same type and same message.
  ///
  /// (Alternative: a method `withPosition` on [CalcError] itself.
  /// Your decision, see the task file.)
  CalcError _withPosition(CalcError error, int position) => switch (error) {
    SyntaxError e => SyntaxError(e.message, position),
    MathError e => MathError(e.message, position),
    EvaluationError e => EvaluationError(e.message, position),
  };

  // -------------------------------------------------------------------------
  // Stage 3: names
  // -------------------------------------------------------------------------

  /// `pi`, `foo`, or `sin` without parentheses.
  Value _variable(Variable node) => switch (registry.lookup(node.name)) {
    null => throw EvaluationError("Unknown name '${node.name}'"),
    ConstantEntry c => c.value,
    FunctionEntry _ => throw EvaluationError(
      "'${node.name}' is a function, write ${node.name}(...)",
    ),
  };

  // -------------------------------------------------------------------------
  // Stage 4 and 5: calls
  // -------------------------------------------------------------------------

  /// `sin(x)`, `log(x, b)`, `rand()`, and (stage 5) `pi(2)`.
  Value _call(Call node) => switch (registry.lookup(node.name)) {
    null => throw EvaluationError("Unknown function '${node.name}(...)'"),
    ConstantEntry c => _constantTimes(c, node),
    FunctionEntry f => registry.invoke(
      f.name, //Check node.name or f.name what is better (should be the same)
      node.args.map((ex) => evaluate(ex)).toList(),
      context,
    ),
  };

  /// Stage 5: a constant used with parentheses, `pi(2)` means `pi * 2`.
  Value _constantTimes(ConstantEntry entry, Call node) => node.args.length == 1
      ? multiply(entry.value, evaluate(node.args.first))
      : throw EvaluationError(
          "'${entry.name}' is a constant: ${entry.name}(x) means ${entry.name} * x and needs exactly one value",
        );
}
