import 'package:drift/drift.dart';

//RangeMeasurements table
// Beide Indizes bedienen die Cascades: ohne sie muss SQLite beim Löschen
// einer Session bzw. eines GPS-Punkts die ganze Tabelle scannen — bei
// Zehntausenden Zeilen wird das Löschen quadratisch.
@TableIndex(name: 'range_measurements_session', columns: {#sessionId})
@TableIndex(name: 'range_measurements_gps_point', columns: {#gpsPointId})
class RangeMeasurements extends Table {
  TextColumn get id => text()();

  // Cascade: eine gelöschte Session nimmt ihre Messungen mit. Ohne das
  // blieben Zehntausende Zeilen als Waisen liegen, die keine Abfrage je
  // wieder anfasst
  TextColumn get sessionId =>
      text().references(Sessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get gpsPointId =>
      text().references(GpsPoints, #id, onDelete: KeyAction.cascade)();
  TextColumn get peerId => text()();
  TextColumn get tech => text()(); // 'ble' | 'uwb' | später 'channel_sounding'

  IntColumn get rssi => integer().nullable()(); // nur bei BLE gefüllt
  IntColumn get distance =>
      integer().nullable()(); // nur bei UWB gefüllt (Zentimeter)
  IntColumn get quality => integer().nullable()(); // UWB-Qualitätsindikator
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

//Boats table
class Boats extends Table {
  TextColumn get id => text()();
  TextColumn get sailNumber => text()();
  TextColumn get name => text()();
  TextColumn get boatClass => text()();
  RealColumn get maxSpeed => real()();
  // Winkel ZWISCHEN den beiden Am-Wind-Kursen, Europe: 90°. Klassenabhängig,
  // wird beim Anlegen aus kBoatClasses vorbelegt und dann auf dem Boot
  // eingefroren — wie maxSpeed. Speist die Wendenerkennung, siehe
  // maneuverThresholdDeg in session_stats.dart.
  RealColumn get tackAngle =>
      real().named('tack_angle').withDefault(const Constant(90.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Sessions table
class Sessions extends Table {
  // Primary key
  TextColumn get id => text()();
  TextColumn get name => text()();
  // setNull statt cascade: ein gelöschtes Boot darf seine Sessions nicht
  // mitreißen — die Aufzeichnung bleibt wertvoll, nur die Bootsangaben
  // fehlen dann. Deshalb nullable
  TextColumn get boatId => text()
      .named('boat_id')
      .nullable()
      .references(Boats, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get startTime => dateTime().named('start_time')();
  DateTimeColumn get endTime => dateTime().named('end_time').nullable()();
  BoolColumn get isComplete =>
      boolean().named('is_complete').withDefault(const Constant(false))();
  BoolColumn get isSynced =>
      boolean().named('is_synced').withDefault(const Constant(false))();
  RealColumn get distance => real().named('distance').nullable()();
  // Where the wind came FROM, set by the user post-session via CompassPanel.
  // Nullable: "no wind entered" is a valid state, stats show "—" then.
  RealColumn get windDirection => real().named('wind_direction').nullable()();

  // ── Kennzahlen, einmal beim Beenden gerechnet ────────────────────
  // Eine beendete Session ist unveränderlich, also ist jede erneute
  // Berechnung verschwendet. completeSession lädt die Punkte für die
  // Distanz ohnehin — die übrigen Werte fallen im selben Durchlauf ab.
  // Nur so lassen sie sich auch in der Sessionliste zeigen, wo ein Laden
  // der Punkte pro Zeile nicht zu retten wäre.
  // Nullable: Sessions aus älteren Versionen haben sie noch nicht.
  RealColumn get peakSpeed => real().named('peak_speed').nullable()();
  RealColumn get avgMovingSpeed =>
      real().named('avg_moving_speed').nullable()();
  IntColumn get movingSeconds => integer().named('moving_seconds').nullable()();
  IntColumn get tacks => integer().nullable()();
  // Version des Algorithmus, mit dem die Werte oben entstanden sind.
  // 0 = noch nie gerechnet. Liegt sie unter sessionStatsVersion, rechnet
  // der Start die Session nach — sonst wäre jede Änderung an der Formel
  // ein Datenverlust für alles bereits Aufgezeichnete.
  IntColumn get statsVersion =>
      integer().named('stats_version').withDefault(const Constant(0))();

  // Tell drift which column is the primary key
  @override
  Set<Column> get primaryKey => {id};
}

// GPS points table — will have thousands of rows per session
//
// Der zusammengesetzte Index bedient WHERE session_id UND ORDER BY timestamp
// in einem: getPointsForSession musste ohne ihn die komplette Tabelle über
// alle Sessions scannen und danach sortieren. Bei 4 Hz sind das pro Stunde
// 14 400 Zeilen — nach 20 Trainings 280 000 gescannte für 14 400 gelieferte.
@TableIndex(name: 'gps_points_session_time', columns: {#sessionId, #timestamp})
class GpsPoints extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()
      .named('session_id')
      .references(Sessions, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get sog => real()();
  RealColumn get cog => real()();
  RealColumn get heel => real()();
  RealColumn get pitch => real().withDefault(const Constant(0.0))();
  RealColumn get magHeading =>
      real().named('mag_heading').withDefault(const Constant(0.0))();
  RealColumn get accuracy => real()();

  @override
  Set<Column> get primaryKey => {id};
}
