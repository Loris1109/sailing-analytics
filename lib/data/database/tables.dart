import 'package:drift/drift.dart';

//RangeMeasurements table
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

  // Tell drift which column is the primary key
  @override
  Set<Column> get primaryKey => {id};
}

// GPS points table — will have thousands of rows per session
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
