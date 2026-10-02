import 'ast.dart';
import 'errors.dart';
import 'token.dart';
import 'tokenizer.dart';

/// Wandelt [source] in einen Syntaxbaum um.
/// Wirft [SyntaxError], wenn die Eingabe nicht der Grammatik entspricht.
Expr parse(String source) => _Parser(tokenize(source)).parseAll();

class _Parser {
  _Parser(this._tokens);

  final List<Token> _tokens;
  int _pos = 0;

  // ---------------------------------------------------------------------
  // Hilfsmethoden (fertig)
  // ---------------------------------------------------------------------

  /// Das Token, das gerade "dran" ist. Wird NICHT verbraucht.
  Token get _current => _tokens[_pos];

  /// Ist das aktuelle Token vom Typ [type]?
  bool _check(TokenType type) => _current.type == type;

  /// Verbraucht das aktuelle Token und gibt es zurück.
  /// Bleibt am eof stehen, läuft also nie über das Ende hinaus.
  Token _advance() {
    final token = _current;
    if (token.type != TokenType.eof) _pos++;
    return token;
  }

  /// Verbraucht ein Token vom Typ [type] oder wirft einen Fehler.
  /// Praktisch für Pflichtzeichen, z.B. die schließende Klammer.
  Token _expect(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw SyntaxError(message, _current.position);
  }

  // ---------------------------------------------------------------------
  // Einstieg (fertig)
  // ---------------------------------------------------------------------

  Expr parseAll() {
    final expr = _expression();
    if (!_check(TokenType.eof)) {
      throw SyntaxError('Unerwartetes "${_current.lexeme}"', _current.position);
    }
    return expr;
  }

  // ---------------------------------------------------------------------
  // Grammatik-Regeln (DEINE Aufgabe)
  //
  //   expr     := term (('+' | '-') term)*
  //   term     := unary (('*' | '/') unary | <implizit> unary)*
  //   unary    := '-' unary | power
  //   power    := postfix ('^' unary)?
  //   postfix  := primary '!'*
  //   primary  := NUMBER | IDENT | IDENT '(' args ')' | '(' expr ')'
  // ---------------------------------------------------------------------

  // Stufe 1
  Expr _expression() {
    return _term();
  }

  // Stufe 2 (in Stufe 1 einfach direkt _primary() zurückgeben)
  Expr _term() {
    return _primary();
  }

  // Stufe 3
  Expr _unary() {
    throw UnimplementedError('TODO: _unary');
  }

  // Stufe 3
  Expr _power() {
    throw UnimplementedError('TODO: _power');
  }

  // Stufe 4
  Expr _postfix() {
    throw UnimplementedError('TODO: _postfix');
  }

  // Stufe 1: nur Zahlen. Stufe 2: Klammern. Stufe 4: Variablen, Aufrufe.
  Expr _primary() {
    if (_check(TokenType.eof)) {
      throw SyntaxError('Incomplete Input', _current.position);
    } else if (_check(TokenType.number)) {
      final token = _advance();
      return NumberLiteral(token.lexeme, token.position);
    }

    throw SyntaxError('Unerwartetes "${_current.lexeme}"', _current.position);
  }
}
