import 'package:germundium_calculator/engine/engine.dart';
import 'package:rational/rational.dart'; // bzw. dein Import-Pfad aus dem Test

//dart run lib/spielwiese.dart

void main() {
  final double x = 2.0;
  print('double tests: ${x == x.roundToDouble()}');
  for (final eingabe in ['pi', 'pi()', '2pi', 'sin', 'pi(2)']) {
    try {
      print('$eingabe  →  ${parse(eingabe)}');
    } on CalcError catch (e) {
      print('$eingabe  →  Error: $e');
    }
  }
}
