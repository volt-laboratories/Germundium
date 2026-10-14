import 'package:germundium_calculator/engine/engine.dart';
import 'package:rational/rational.dart'; // bzw. dein Import-Pfad aus dem Test

//dart run lib/spielwiese.dart

void main() {
  final double x = 2.0;
  print('double tests: ${x == x.roundToDouble()}');
  for (final eingabe in [
    'cos(pi)',
    'sin(2pi)',
    'pi-pi',
    'foo',
    'log(4/2, 2)',
    '1/2',
  ]) {
    try {
      print('$eingabe  →  ${calculate(eingabe)}');
    } on CalcError catch (e) {
      print('$eingabe  →  Error: $e');
    }
  }
}

//Errors (potential)
//sin(pi), sin(2pi)
