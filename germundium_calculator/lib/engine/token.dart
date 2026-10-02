enum TokenType {
  number, // 3, 3.14, .5
  identifier, // x, sin, π, f, ans_1
  plus, // +
  minus, // - −
  star, // * × ·
  slash, // / ÷
  caret, // ^
  bang, // ! (Fakultät)
  lParen, // (
  rParen, // )
  comma, // ,  (Argumenttrenner, z.B. log(2, 8))
  equals, // =  (Definitionen, z.B. f(x) = x^2)
  eof, // Ende der Eingabe – erleichtert dem Parser das Leben
}

/// Ein Token ist das kleinste bedeutungstragende Stück der Eingabe.
final class Token {
  const Token(this.type, this.lexeme, this.position);

  final TokenType type;

  /// Der Originaltext. Zahlen bleiben bewusst ein String, damit später
  /// "0.1" exakt als 1/10 gelesen werden kann statt als ungenaues double.
  final String lexeme;

  /// Startindex im Eingabetext (für Fehlermeldungen).
  final int position;

  @override
  bool operator ==(Object other) =>
      other is Token &&
      other.type == type &&
      other.lexeme == lexeme &&
      other.position == position;

  @override
  int get hashCode => Object.hash(type, lexeme, position);

  @override
  String toString() => '${type.name}("$lexeme")@$position';
}
