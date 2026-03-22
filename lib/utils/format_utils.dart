// lib/utils/format_utils.dart
//
// Gemeinsame Hilfsfunktionen für Formatierung.

/// Formatiert einen Meterwert ohne überflüssige Dezimalstelle.
/// Beispiele: 9.0 → '9 m', 10.5 → '10.5 m'
/// Ersetzt die identischen _fmtSpeed()-Definitionen in
/// overview_tab und basic_info_step.
String fmtSpeed(double meters) {
  if (meters == meters.roundToDouble()) return '${meters.toInt()} m';
  return '${meters.toStringAsFixed(1)} m';
}

/// Formatiert eine ganze Zahl mit explizitem Vorzeichen.
/// Positive Zahlen erhalten ein '+', negative ihr '-', 0 wird '+0'.
/// Beispiele: 3 → '+3', -1 → '-1', 0 → '+0'
///
/// Ersetzt die identischen Inline-Ausdrücke
///   `bonus >= 0 ? '+$bonus' : '$bonus'`
/// in skills_tab, overview_tab, attributes_step und spell_tab.
String signedInt(int value) => value >= 0 ? '+$value' : '$value';