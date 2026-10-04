import 'package:germundium_calculator/engine/engine.dart';
import 'package:rational/rational.dart'; // bzw. dein Import-Pfad aus dem Test

//dart run lib/spielwiese.dart

void main() {
  print('rational 0.5 == 0.50: ${Rational.parse('0.0') == Rational.zero}');
  for (final eingabe in [
    'x',
    'sin(x)',
    'log(2, 8)',
    'max(1, 2+3)',
    'rand()',
    'sin(',
  ]) {
    try {
      print('$eingabe  →  ${parse(eingabe)}');
    } on CalcError catch (e) {
      print('$eingabe  →  Error: $e');
    }
  }
}
