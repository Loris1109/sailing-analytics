// lib/data/database/epoch_millis_converter.dart

import 'package:drift/drift.dart';

/// Speichert DateTime als Unix-MILLISEKUNDEN.
///
/// Drift legt eine `dateTime()`-Spalte standardmäßig als Unix-SEKUNDEN ab
/// und schneidet beim Schreiben alles darunter weg. Für eine Spur und für
/// BLE-Pakete, die mehrmals pro Sekunde ankommen, ist das zu grob: alle
/// Pakete einer Sekunde bekämen denselben Zeitstempel, und ein GPS-Punkt
/// läge bis zu 999 ms daneben — auf dem Wasser schnell mehrere Meter.
///
/// Die Spalte bleibt INTEGER und sortiert weiter numerisch; Indizes und
/// Vergleiche funktionieren unverändert. Für die Umstellung bestehender
/// Daten siehe Migration 10 in app_database.dart.
class EpochMillisConverter extends TypeConverter<DateTime, int> {
  const EpochMillisConverter();

  // Lokalzeit, wie Drift sie auch vorher geliefert hat
  @override
  DateTime fromSql(int fromDb) => DateTime.fromMillisecondsSinceEpoch(fromDb);

  @override
  int toSql(DateTime value) => value.millisecondsSinceEpoch;
}
