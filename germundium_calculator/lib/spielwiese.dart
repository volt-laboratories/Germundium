import 'package:germundium_calculator/engine/engine.dart'; // bzw. dein Import-Pfad aus dem Test

//dart run lib/spielwiese.dart

void main() {
  for (final eingabe in ['()', ')', '1 +', '((1)', '(1))', '2 3']) {
    try {
      print('$eingabe  →  ${parse(eingabe)}');
    } on CalcError catch (e) {
      print('$eingabe  →  Error: $e');
    }
  }
}
