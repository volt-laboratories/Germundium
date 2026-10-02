import 'package:germundium_calculator/engine/engine.dart'; // bzw. dein Import-Pfad aus dem Test

void main() {
  for (final eingabe in ['56+7']) {
    try {
      print('$eingabe  →  ${tokenize(eingabe)}');
    } on CalcError catch (e) {
      print('$eingabe  →  FEHLER: $e');
    }
  }
}
