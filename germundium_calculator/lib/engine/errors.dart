/// Basisklasse aller Fehler, die die Engine wirft.
///
/// `sealed` heißt: Die UI kann per `switch` alle Fehlerarten vollständig
/// behandeln, und der Compiler meckert, wenn eine neue dazukommt.
sealed class CalcError implements Exception {
  const CalcError(this.message, [this.position]);

  /// Für den Nutzer lesbare Beschreibung (deutsch).
  final String message;

  /// Index im Eingabetext, an dem der Fehler auftrat (falls bekannt).
  /// Damit kann die UI später die Stelle markieren.
  final int? position;

  @override
  String toString() =>
      position == null ? message : '$message (Position $position)';
}

/// Eingabe ist formal falsch: unbekanntes Zeichen, Klammer fehlt, ...
final class SyntaxError extends CalcError {
  const SyntaxError(super.message, [super.position]);
}

/// Eingabe ist korrekt, aber nicht berechenbar: Division durch 0, ...
/// (wird ab Schritt 4 benutzt)
final class MathError extends CalcError {
  const MathError(super.message, [super.position]);
}
