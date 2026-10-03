/// Recursive-descent parser for calculator expressions.
///
/// Grammar, from lowest to highest precedence:
///
/// ```text
/// expr    := term (('+' | '-') term)*
/// term    := unary (('*' | '/') unary | <implicit> unary)*
/// unary   := ('-' | '+') unary | power
/// power   := postfix ('^' unary)?
/// postfix := primary '!'*
/// primary := NUMBER | IDENT | IDENT '(' args ')' | '(' expr ')'
/// args    := (expr (',' expr)*)?
/// ```
///
/// Each rule is implemented by one method of the parser.
library;

import 'ast.dart';
import 'errors.dart';
import 'token.dart';
import 'tokenizer.dart';

/// Parses [source] into an abstract syntax tree.
///
/// Throws a [SyntaxError] if [source] does not match the grammar.
/// The error's position points to the offending token.
Expr parse(String source) => _Parser(tokenize(source)).parseAll();

/// Turns a list of tokens into an [Expr] tree.
///
/// Expects the token list to end with an `eof` token, as produced
/// by [tokenize]. Each instance parses exactly one input.
class _Parser {
  _Parser(this._tokens);

  final List<Token> _tokens;
  int _pos = 0;

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  /// The token currently being looked at. Does not consume it.
  Token get _current => _tokens[_pos];

  /// Whether the current token is of the given [type].
  bool _check(TokenType type) => _current.type == type;

  /// Consumes the current token and returns it.
  ///
  /// Stays on `eof`, so it never runs past the end of the token list.
  Token _advance() {
    final token = _current;
    if (token.type != TokenType.eof) _pos++;
    return token;
  }

  /// Consumes a token of the given [type], or throws a [SyntaxError]
  /// with [message]. Used for mandatory tokens such as `)`.
  Token _expect(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw SyntaxError(message, _current.position);
  }

  /// Parses a parenthesized, comma-separated argument list `(a, b, ...)`.
  ///
  /// The caller must have checked that the current token is `(`.
  /// Returns an empty list for `()`.
  List<Expr> _arguments() {
    assert(_check(TokenType.lParen), "_arguments() must start at '('");
    final startToken = _advance();
    final items = <Expr>[];
    if (_current.type != TokenType.rParen) {
      // Sonderfall: leere Liste
      items.add(_expression()); // erstes Element

      while (_check(TokenType.comma)) {
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
  // Entry point
  // ---------------------------------------------------------------------

  /// Parses a complete expression and ensures that no tokens are left
  /// over, so inputs like `2 3` or `(1))` are rejected.
  Expr parseAll() {
    final expr = _expression();
    if (!_check(TokenType.eof)) {
      // TODO(before MVP): unify error messages, add "Unmatched ')'" here.
      throw SyntaxError("Unexpected '${_current.lexeme}'", _current.position);
    }

    return expr;
  }

  // ---------------------------------------------------------------------
  // Grammar rules
  //
  //   expr     := term (('+' | '-') term)*
  //   term     := unary (('*' | '/') unary | <implizit> unary)*
  //   unary    := ('-' | '+') unary | power
  //   power    := postfix ('^' unary)?
  //   postfix  := primary '!'*
  //   primary  := NUMBER | IDENT | IDENT '(' args ')' | '(' expr ')'
  // ---------------------------------------------------------------------

  /// `expr := term (('+' | '-') term)*`
  ///
  /// Addition and subtraction, left-associative: `1-2-3` is `(1-2)-3`.
  Expr _expression() {
    var left = _term();

    while (_check(TokenType.plus) || _check(TokenType.minus)) {
      final op = _advance();
      final right = _term();
      final operator = op.type == TokenType.plus
          ? BinaryOperator.add
          : BinaryOperator.subtract;

      left = BinaryOp(
        op: operator,
        left: left,
        right: right,
        position: op.position,
      );
    }

    return left;
  }

  /// `term := unary (('*' | '/') unary | <implicit> unary)*`
  ///
  /// Multiplication and division, left-associative.
  ///
  /// Also handles implicit multiplication when an identifier or `(`
  /// directly follows a factor: `2x`, `2(3+1)`, `2sin(x)`.
  /// Numbers never start an implicit factor, so `2 3` stays an error.
  /// Note that `1/2x` is parsed as `(1/2)*x`, not `1/(2x)`.
  Expr _term() {
    var left = _unary();

    while (true) {
      if (_check(TokenType.star) || _check(TokenType.slash)) {
        final op = _advance();
        final right = _unary();
        left = BinaryOp(
          op: op.type == TokenType.star
              ? BinaryOperator.multiply
              : BinaryOperator.divide,
          left: left,
          right: right,
          position: op.position,
        );
      } else if (_check(TokenType.identifier) || _check(TokenType.lParen)) {
        final position = _current.position;
        final right = _unary();
        left = BinaryOp(
          op: BinaryOperator.multiply,
          left: left,
          right: right,
          position: position,
        );
      } else {
        break;
      }
    }

    return left;
  }

  /// `unary := ('-' | '+') unary | power`
  ///
  /// Prefix signs. They bind weaker than `^`, so `-2^2` is `-(2^2)`.
  /// A unary plus creates no node: `+5` is parsed as `5`.
  Expr _unary() {
    if (_check(TokenType.plus)) {
      _advance();

      return _unary();
    } else if (_check(TokenType.minus)) {
      final token = _advance();

      return Negate(operand: _unary(), position: token.position);
    } else {
      return _power();
    }
  }

  /// `power := postfix ('^' unary)?`
  ///
  /// Exponentiation, right-associative: `2^3^2` is `2^(3^2)`.
  /// The exponent is parsed with [_unary], which allows `2^-3`.
  Expr _power() {
    final left = _postfix(); // 1. immer zuerst: linke Seite lesen

    if (_check(TokenType.caret)) {
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

  /// `postfix := primary '!'*`
  ///
  /// Factorial. Repeated factorials nest: `3!!` is `(3!)!`.
  Expr _postfix() {
    var left = _primary();

    while (_check(TokenType.bang)) {
      final token = _advance();
      left = Factorial(operand: left, position: token.position);
    }

    return left;
  }

  /// `primary := NUMBER | IDENT | IDENT '(' args ')' | '(' expr ')'`
  ///
  /// Numbers, variables, function calls and parenthesized expressions.
  /// An identifier directly followed by `(` is always a call, so `x(2)`
  /// calls `x` instead of multiplying.
  Expr _primary() {
    if (_check(TokenType.eof)) {
      // Without this branch, the final throw would report "Unexpected ''",
      // because the eof token has an empty lexeme.
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

      if (_check(TokenType.rParen)) {
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
