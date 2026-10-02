import 'package:germundium_calculator/engine/errors.dart';
import 'package:germundium_calculator/engine/token.dart';
import 'package:germundium_calculator/engine/tokenizer.dart';
import 'package:test/test.dart';

/// Hilfsfunktion: nur die Typen, ohne eof am Ende.
List<TokenType> types(String s) =>
    tokenize(s).map((t) => t.type).where((t) => t != TokenType.eof).toList();

/// Hilfsfunktion: nur die Lexeme, ohne eof am Ende.
List<String> lexemes(String s) => tokenize(
  s,
).where((t) => t.type != TokenType.eof).map((t) => t.lexeme).toList();

void main() {
  group('Grundlagen', () {
    test('leere Eingabe ergibt nur eof', () {
      expect(tokenize(''), [const Token(TokenType.eof, '', 0)]);
    });

    test('einfache Addition', () {
      expect(types('1 + 2'), [
        TokenType.number,
        TokenType.plus,
        TokenType.number,
      ]);
    });

    test('Leerzeichen sind egal', () {
      expect(types('1+2'), types('  1   +\t2 '));
    });

    test('Positionen stimmen', () {
      final tokens = tokenize('12 + x');
      expect(tokens.map((t) => t.position), [0, 3, 5, 6]);
    });
  });

  group('Zahlen', () {
    test('Ganzzahl, Dezimalzahl, führender Punkt', () {
      expect(lexemes('3 3.14 .5'), ['3', '3.14', '.5']);
    });

    test('führende Nullen bleiben im Lexem erhalten', () {
      expect(lexemes('007'), ['007']);
    });

    test('Punkt ohne folgende Ziffer ist ein Fehler', () {
      expect(() => tokenize('3.'), throwsA(isA<SyntaxError>()));
      expect(() => tokenize('.'), throwsA(isA<SyntaxError>()));
    });

    test('mehrere Dezimalpunkte sind ein Fehler', () {
      expect(
        () => tokenize('1.2.3'),
        throwsA(isA<SyntaxError>().having((e) => e.position, 'position', 3)),
      );
    });
  });

  group('Operatoren', () {
    test('ASCII-Operatoren', () {
      expect(types('+-*/^!(),='), [
        TokenType.plus,
        TokenType.minus,
        TokenType.star,
        TokenType.slash,
        TokenType.caret,
        TokenType.bang,
        TokenType.lParen,
        TokenType.rParen,
        TokenType.comma,
        TokenType.equals,
      ]);
    });

    test('Unicode-Varianten werden vereinheitlicht', () {
      expect(types('2×3÷4−1·5'), types('2*3/4-1*5'));
    });

    test('unbekanntes Zeichen', () {
      expect(
        () => tokenize('2 # 3'),
        throwsA(isA<SyntaxError>().having((e) => e.position, 'position', 2)),
      );
    });
  });

  group('Bezeichner', () {
    test('Funktionsaufruf', () {
      expect(types('sin(x)'), [
        TokenType.identifier,
        TokenType.lParen,
        TokenType.identifier,
        TokenType.rParen,
      ]);
    });

    test('griechische Buchstaben und Unterstriche', () {
      expect(lexemes('π θ x_1 ans2'), ['π', 'θ', 'x_1', 'ans2']);
    });

    test('2x wird zu Zahl + Bezeichner', () {
      expect(types('2x'), [TokenType.number, TokenType.identifier]);
    });

    test('Funktionsdefinition', () {
      expect(lexemes('f(x) = x^2'), ['f', '(', 'x', ')', '=', 'x', '^', '2']);
    });
  });
}
