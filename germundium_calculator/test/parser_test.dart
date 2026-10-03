// Import-Pfad genauso wie in deinem tokenizer_test.dart:
import 'package:germundium_calculator/engine/engine.dart';
import 'package:test/test.dart';

//dart test test/parser_test.dart

/// Parst und gibt den Baum vollständig geklammert zurück.
/// So sieht man sofort, wie der Parser gruppiert hat.
String p(String s) => parse(s).toString();

Matcher get syntaxError => throwsA(isA<SyntaxError>());

void expectSyntaxError(String input, int position) {
  expect(
    () => p(input),
    throwsA(isA<SyntaxError>().having((e) => e.position, 'position', position)),
  );
}

void main() {
  group('Stufe 1: Zahlen, + und -', () {
    test('einzelne Zahl', () => expect(p('42'), '42'));
    test('Addition', () => expect(p('1 + 2'), '(1 + 2)'));
    test('linksassoziativ', () => expect(p('1 - 2 + 3'), '((1 - 2) + 3)'));
    test('leere Eingabe', () => expect(() => parse(''), syntaxError));
    test(
      'Operator ohne rechte Seite',
      () => expect(() => parse('1 +'), syntaxError),
    );
    test(
      'zwei Zahlen ohne Operator',
      () => expect(() => parse('1 2'), syntaxError),
    );
  });

  group('Stufe 2: * und /, Klammern', () {
    test('Punkt vor Strich', () => expect(p('1 + 2 * 3'), '(1 + (2 * 3))'));
    test(
      'Division linksassoziativ',
      () => expect(p('8 / 4 / 2'), '((8 / 4) / 2)'),
    );
    test('Klammern', () => expect(p('(1 + 2) * 3'), '((1 + 2) * 3)'));
    test('verschachtelte Klammern', () => expect(p('((5))'), '5'));
    test('Klammer nicht geschlossen', () {
      expect(
        () => parse('(1 + 2'),
        throwsA(isA<SyntaxError>().having((e) => e.position, 'position', 6)),
      );
    });
    test('Klammer zu ohne auf', () => expect(() => parse(')'), syntaxError));
  });

  group('Stufe 3: Vorzeichen und Potenzen', () {
    test('Vorzeichen', () => expect(p('-3'), '(-3)'));
    test('doppeltes Vorzeichen', () => expect(p('--3'), '(-(-3))'));
    test('Minus nach Operator', () => expect(p('1 - -2'), '(1 - (-2))'));
    test('-2^2 ist -(2^2)', () => expect(p('-2^2'), '(-(2 ^ 2))'));
    test('Potenz rechtsassoziativ', () => expect(p('2^3^2'), '(2 ^ (3 ^ 2))'));
    test('negativer Exponent', () => expect(p('2^-1'), '(2 ^ (-1))'));
    test('positives Vorzeichen', () => expect(p('+5'), '5'));
    test('positives Vorzeichen + Summe', () => expect(p('2++5'), '(2 + 5)'));
  });

  group('Stufe 3: Syntaxfehler', () {
    // _primary sieht eof
    test('Potenz ohne Exponent', () => expectSyntaxError('2^', 2));
    test('Vorzeichen ohne Operand', () => expectSyntaxError('-', 1));
    test('Operator am Ende', () => expectSyntaxError('2*', 2));

    // _primary sieht unerwartetes Token
    test('Potenz ohne Basis', () => expectSyntaxError('^2', 0));
    test('Operator am Anfang', () => expectSyntaxError('*5', 0));
    test('zwei Operatoren', () => expectSyntaxError('2^*3', 2));
    test(
      'zwei Operatoren mit Leerzeichen',
      () => expectSyntaxError('2 * * 3', 4),
    );
    test('leere Klammer', () => expectSyntaxError('()', 1));

    // eof-Check in parseAll: Ausdruck fertig, aber Tokens übrig
    test('überzählige schließende Klammer', () => expectSyntaxError('2+3)', 3));
    test('zwei Zahlen ohne Operator', () => expectSyntaxError('2 3', 2));
  });

  group('Stufe 4: Variablen, Fakultät, Funktionsaufrufe', () {
    test('Variable', () => expect(p('x'), 'x'));
    test('Konstante', () => expect(p('2 * π'), '(2 * π)'));
    test('Fakultät', () => expect(p('3!'), '(3!)'));
    test('doppelte Fakultät', () => expect(p('3!!'), '((3!)!)'));
    test(
      'Fakultät bindet stärker als Potenz',
      () => expect(p('2^3!'), '(2 ^ (3!))'),
    );
    test(
      'Fakultät bindet stärker als Minus',
      () => expect(p('-3!'), '(-(3!))'),
    );
    test('Aufruf', () => expect(p('sin(x)'), 'sin(x)'));
    test('mehrere Argumente', () => expect(p('log(2, 8)'), 'log(2, 8)'));
    test('keine Argumente', () => expect(p('rand()'), 'rand()'));
    test(
      'Aufruf in Ausdruck',
      () => expect(p('sin(1 + 2) * 3'), '(sin((1 + 2)) * 3)'),
    );
    test(
      'Argumentliste nicht beendet',
      () => expect(() => parse('log(2,'), syntaxError),
    );
  }, skip: 'Stufe 4');

  group('Stufe 5: implizite Multiplikation', () {
    test('Zahl und Variable', () => expect(p('2x'), '(2 * x)'));
    test('Zahl und Konstante', () => expect(p('2π'), '(2 * π)'));
    test('Zahl und Funktion', () => expect(p('3sin(x)'), '(3 * sin(x))'));
    test('Zahl und Klammer', () => expect(p('2(1 + 3)'), '(2 * (1 + 3))'));
    test('Klammer und Klammer', () => expect(p('(1)(2)'), '(1 * 2)'));
    test('zwei Variablen', () => expect(p('x y'), '(x * y)'));
    test('Potenz bindet stärker', () => expect(p('2x^2'), '(2 * (x ^ 2))'));
    test('1/2x ist (1/2)*x', () => expect(p('1/2x'), '((1 / 2) * x)'));
    test('Vorzeichen', () => expect(p('-2x'), '((-2) * x)'));
    test(
      'Zahl nach Zahl bleibt ein Fehler',
      () => expect(() => parse('2 3'), syntaxError),
    );
  }, skip: 'Stufe 5');
}
