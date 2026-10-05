/// Base class of all errors thrown by the engine.
///
/// `sealed` means: the UI can handle every error kind exhaustively with a
/// `switch`, and the compiler complains when a new kind is added.
///
/// All errors are `Exception`s (not `Error`s): they are caused by user
/// input, get caught and displayed, and the app keeps running.
sealed class CalcError implements Exception {
  const CalcError(this.message, [this.position]);

  /// Human-readable description of the error.
  final String message;

  /// Index in the input text where the error occurred, or `null` if the
  /// location is unknown.
  ///
  /// The parser always knows the position. The value types never do;
  /// the evaluator adds it later. This lets the UI highlight the spot
  /// in the input.
  final int? position;

  @override
  String toString() =>
      position == null ? message : '$message (Position $position)';
}

/// The input is syntactically invalid and cannot be turned into an AST:
/// unknown character, missing parenthesis, operator without operand, ...
///
/// Thrown by the tokenizer and the parser.
final class SyntaxError extends CalcError {
  const SyntaxError(super.message, [super.position]);
}

/// The input is syntactically valid but has no valid result:
/// division by zero, factorial of a negative number, non-real result, ...
///
/// Thrown by the value types (from step 3 on) and later by the registry
/// and the evaluator.
final class MathError extends CalcError {
  const MathError(super.message, [super.position]);
}

final class EvaluationError extends CalcError {
  const EvaluationError(super.message, [super.position]);
}
