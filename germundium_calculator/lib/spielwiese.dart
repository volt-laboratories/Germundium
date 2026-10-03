import 'package:germundium_calculator/engine/engine.dart'; // bzw. dein Import-Pfad aus dem Test

//dart run lib/spielwiese.dart

void main() {
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
