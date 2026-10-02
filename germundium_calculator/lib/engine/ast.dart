/// Knoten des Syntaxbaums (AST = Abstract Syntax Tree).
///
/// Jeder Knoten merkt sich die Position im Eingabetext, damit spätere
/// Fehler (z.B. Division durch 0) die richtige Stelle markieren können.
sealed class Expr {
  const Expr(this.position);
  final int position;
}

/// Eine Zahl. Bleibt als String, die Umwandlung passiert erst im Evaluator.
final class NumberLiteral extends Expr {
  const NumberLiteral(this.lexeme, super.position);
  final String lexeme;

  @override
  String toString() => lexeme;
}

/// Ein Name: x, π, ans_3, ...
final class Variable extends Expr {
  const Variable(this.name, super.position);
  final String name;

  @override
  String toString() => name;
}

/// Unäres Minus: -x
final class Negate extends Expr {
  const Negate(this.operand, super.position);
  final Expr operand;

  @override
  String toString() => '(-$operand)';
}

/// Fakultät: x!
final class Factorial extends Expr {
  const Factorial(this.operand, super.position);
  final Expr operand;

  @override
  String toString() => '($operand!)';
}

enum BinaryOperator {
  add('+'),
  subtract('-'),
  multiply('*'),
  divide('/'),
  power('^');

  const BinaryOperator(this.symbol);
  final String symbol;
}

/// Zweistellige Operation: a + b, a ^ b, ...
/// Implizite Multiplikation (2x) wird ebenfalls zu multiply.
final class BinaryOp extends Expr {
  const BinaryOp(this.op, this.left, this.right, super.position);
  final BinaryOperator op;
  final Expr left;
  final Expr right;

  @override
  String toString() => '($left ${op.symbol} $right)';
}

/// Funktionsaufruf: sin(x), log(2, 8), rand()
final class Call extends Expr {
  const Call(this.name, this.args, super.position);
  final String name;
  final List<Expr> args;

  @override
  String toString() => '$name(${args.join(', ')})';
}
