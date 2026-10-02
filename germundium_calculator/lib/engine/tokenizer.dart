import 'errors.dart';
import 'token.dart';

/// Zerlegt [source] in Tokens. Die Liste endet immer mit [TokenType.eof].
///
/// Wirft [SyntaxError] bei unbekannten Zeichen oder kaputten Zahlen.
List<Token> tokenize(String source) => _Tokenizer(source).run();

class _Tokenizer {
  _Tokenizer(this.source);

  final String source;
  final List<Token> _tokens = [];
  int _pos = 0;

  // Einzelzeichen-Operatoren. Die Unicode-Varianten (×, ÷, ·, −) werden
  // gleich hier vereinheitlicht, damit der Parser sie nie sehen muss.
  static const Map<String, TokenType> _single = {
    '+': TokenType.plus,
    '-': TokenType.minus,
    '−': TokenType.minus,
    '*': TokenType.star,
    '×': TokenType.star,
    '·': TokenType.star,
    '/': TokenType.slash,
    '÷': TokenType.slash,
    '^': TokenType.caret,
    '!': TokenType.bang,
    '(': TokenType.lParen,
    ')': TokenType.rParen,
    ',': TokenType.comma,
    '=': TokenType.equals,
  };

  // \p{L} = jeder Unicode-Buchstabe, also auch π, θ, ä.
  static final RegExp _identStart = RegExp(r'\p{L}', unicode: true);
  static final RegExp _identPart = RegExp(r'[\p{L}0-9_]', unicode: true);

  bool get _atEnd => _pos >= source.length;
  String get _peek => source[_pos];

  static bool _isDigit(String c) {
    final u = c.codeUnitAt(0);
    return u >= 0x30 && u <= 0x39; // '0'..'9'
  }

  List<Token> run() {
    while (!_atEnd) {
      final c = _peek;

      if (c.trim().isEmpty) {
        _pos++; // Leerzeichen, Tabs etc. ignorieren
      } else if (_isDigit(c) || c == '.') {
        _number();
      } else if (_identStart.hasMatch(c)) {
        _identifier();
      } else {
        final type = _single[c];
        if (type == null) {
          throw SyntaxError('Unbekanntes Zeichen "$c"', _pos);
        }
        _tokens.add(Token(type, c, _pos));
        _pos++;
      }
    }
    _tokens.add(Token(TokenType.eof, '', _pos));
    return _tokens;
  }

  /// Zahl: Ziffern, optional '.' gefolgt von mindestens einer Ziffer.
  /// Erlaubt: 3   3.14   .5      Nicht erlaubt: 3.   1.2.3   .
  void _number() {
    final start = _pos;
    _skipDigits();

    if (!_atEnd && _peek == '.') {
      _pos++;
      if (_atEnd || !_isDigit(_peek)) {
        throw SyntaxError('Ziffer nach Dezimalpunkt erwartet', _pos);
      }
      _skipDigits();
    }

    if (!_atEnd && _peek == '.') {
      throw SyntaxError('Zahl mit mehreren Dezimalpunkten', _pos);
    }

    _tokens.add(Token(TokenType.number, source.substring(start, _pos), start));
  }

  /// Bezeichner: Buchstabe, danach Buchstaben, Ziffern oder '_'.
  /// Achtung: "sin2" ist EIN Bezeichner, "2x" dagegen Zahl + Bezeichner
  /// (das wird im Parser zu impliziter Multiplikation).
  void _identifier() {
    final start = _pos;
    _pos++;
    while (!_atEnd && _identPart.hasMatch(_peek)) {
      _pos++;
    }
    _tokens.add(
      Token(TokenType.identifier, source.substring(start, _pos), start),
    );
  }

  void _skipDigits() {
    while (!_atEnd && _isDigit(_peek)) {
      _pos++;
    }
  }
}
