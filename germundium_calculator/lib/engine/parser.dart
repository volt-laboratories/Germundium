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

  //TODO:Fehlermeldungen überprüfen
  List<Expr> _arguments() {
    final startToken = _expect(TokenType.lParen, "Unreacheable: Expected '('");
    final items = <Expr>[];
    if (_current.type != TokenType.rParen) {
      // Sonderfall: leere Liste
      items.add(_expression()); // erstes Element

      while (_current.type == TokenType.comma) {
        // jedes weitere hat ein Komma davor
        _advance();
        items.add(_expression());
      }
    }
    _expect(
      TokenType.rParen,
      "Expected ')' to close '(' at position ${startToken.position}",
    );
    return items;
  }

  // ---------------------------------------------------------------------
  // Einstieg (fertig)
  // ---------------------------------------------------------------------

  Expr parseAll() {
    final expr = _expression();
    if (!_check(TokenType.eof)) {
      switch (_current.type) {
        case TokenType.rParen:
          throw SyntaxError("Unexpected ')'", _current.position);
        default:
          throw SyntaxError(
            "Unexpected '${_current.lexeme}'",
            _current.position,
          );
      }
    }

    return expr;
  }

  // ---------------------------------------------------------------------
  // Grammatik-Regeln (DEINE Aufgabe)
  //
  //   expr     := term (('+' | '-') term)*
  //   term     := unary (('*' | '/') unary | <implizit> unary)*
  //   unary    := ('-' | '+') unary | power
  //   power    := postfix ('^' unary)?
  //   postfix  := primary '!'*
  //   primary  := NUMBER | IDENT | IDENT '(' args ')' | '(' expr ')'
  // ---------------------------------------------------------------------

  // Stufe 1
  Expr _expression() {
    var left = _term();

    while (_check(TokenType.plus) || _check(TokenType.minus)) {
      final op = _advance();
      final right = _term();
      final operator = switch (op.type) {
        TokenType.plus => BinaryOperator.add,
        TokenType.minus => BinaryOperator.subtract,
        _ => throw StateError('Unreachable'),
      };

      left = BinaryOp(
        op: operator,
        left: left,
        right: right,
        position: op.position,
      );
    }

    return left;
  }

  // Stufe 2 (in Stufe 1 einfach direkt _primary() zurückgeben)
  Expr _term() {
    var left = _unary();

    while (_check(TokenType.star) || _check(TokenType.slash)) {
      final op = _advance();
      final right = _unary();
      final operator = switch (op.type) {
        TokenType.star => BinaryOperator.multiply,
        TokenType.slash => BinaryOperator.divide,
        _ => throw StateError('Unreachable _term()'),
      };

      left = BinaryOp(
        op: operator,
        left: left,
        right: right,
        position: op.position,
      );
    }

    return left;
  }

  // Stufe 3
  Expr _unary() {
    if (_current.type == TokenType.plus) {
      _advance();

      return _unary();
    } else if (_current.type == TokenType.minus) {
      final token = _advance();

      return Negate(operand: _unary(), position: token.position);
    } else {
      return _power();
    }
  }

  // Stufe 3
  Expr _power() {
    final left = _postfix(); // 1. immer zuerst: linke Seite lesen

    if (_current.type == TokenType.caret) {
      final op = _advance(); // 2. nur wenn ^ folgt
      final right = _unary();
      return BinaryOp(
        // 3a. direkt zurückgeben
        op: BinaryOperator.power,
        left: left,
        right: right,
        position: op.position,
      );
    }

    return left; // 3b. kein ^ → linke Seite allein
  }

  // Stufe 4
  Expr _postfix() {
    var left = _primary();

    while (_current.type == TokenType.bang) {
      final token = _advance();
      left = Factorial(operand: left, position: token.position);
    }

    return left;
  }

  // Stufe 1: nur Zahlen. Stufe 2: Klammern. Stufe 4: Variablen, Aufrufe.
  Expr _primary() {
    if (_check(TokenType.eof)) {
      //TODO: testen ob das überhaupt nötig ist, oder ob _parseAll das schon abfängt
      throw SyntaxError('Incomplete Input', _current.position);
    } else if (_check(TokenType.number)) {
      final token = _advance();
      return NumberLiteral(lexeme: token.lexeme, position: token.position);
    } else if (_check(TokenType.identifier)) {
      final token = _advance();
      if (_check(TokenType.lParen)) {
        return Call(
          name: token.lexeme,
          args: _arguments(),
          position: token.position,
        );
      }
      return Variable(name: token.lexeme, position: token.position);
    } else if (_check(TokenType.lParen)) {
      final token = _advance();

      if (_current.type == TokenType.rParen) {
        throw SyntaxError("Empty Brackets ()", _current.position);
      }

      final expression = _expression();

      _expect(
        TokenType.rParen,
        "Expected ')' to close '(' at position ${token.position}",
      );

      return expression;
    }

    throw SyntaxError("Unexpected '${_current.lexeme}'", _current.position);
  }
}
