// lib/data/database/app_database.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sailing_analytics/data/entities/boat.dart';
import 'package:sailing_analytics/data/entities/session.dart';
import 'package:sailing_analytics/data/entities/session_with_boat.dart';
import 'tables.dart';

// This tells drift which tables exist and what version the schema is
// The part() line imports the generated code — doesn't exist yet, that's fine
part 'app_database.g.dart';

@DriftDatabase(tables: [Sessions, GpsPoints, Boats])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      await customStatement('DROP TABLE IF EXISTS gps_points');
      await customStatement('DROP TABLE IF EXISTS sessions');
      await customStatement('DROP TABLE IF EXISTS boats');
      await m.createAll();
    },
  );

  // ── Session queries ────────────────────────────────────────────

  // Insert a new session — returns nothing, just saves
  Future<void> insertSession(SessionsCompanion session) =>
      into(sessions).insert(session);

  // Get all sessions, newest first
  Future<List<Session>> getAllSessions() => (select(
    sessions,
  )..orderBy([(s) => OrderingTerm.desc(s.startTime)])).get();

  // Watch sessions — Stream that updates UI automatically when DB changes
  // This is the killer feature of drift — reactive queries
  Stream<List<Session>> watchAllSessions() => (select(
    sessions,
  )..orderBy([(s) => OrderingTerm.desc(s.startTime)])).watch();

  // Mark session as finished
  Future<void> completeSession(String id, DateTime endTime, double distance) =>
      (update(sessions)..where((s) => s.id.equals(id))).write(
        SessionsCompanion(
          endTime: Value(endTime),
          isComplete: const Value(true),
          distance: Value(distance),
        ),
      );

  // Mark as synced to Supabase
  Future<void> markSynced(String id) =>
      (update(sessions)..where((s) => s.id.equals(id))).write(
        const SessionsCompanion(isSynced: Value(true)),
      );

  Future<void> deleteSession(String id) =>
      (delete(sessions)..where((s) => s.id.equals(id))).go();

  Future<void> updateSessionName(String id, String name) => (update(
    sessions,
  )..where((s) => s.id.equals(id))).write(SessionsCompanion(name: Value(name)));

  Future<void> updateWindDirection(String id, double windDirection) =>
      (update(sessions)..where((s) => s.id.equals(id))).write(
        SessionsCompanion(windDirection: Value(windDirection)),
      );

  // ── GPS point queries ──────────────────────────────────────────

  // Insert one point — called every GPS fix during recording
  Future<void> insertGpsPoint(GpsPointsCompanion point) =>
      into(gpsPoints).insert(point);

  // Batch insert — more efficient if you buffer points
  Future<void> insertGpsPoints(List<GpsPointsCompanion> points) =>
      batch((b) => b.insertAll(gpsPoints, points));

  // Get all points for a session — for map display after recording
  Future<List<GpsPoint>> getPointsForSession(String sessionId) =>
      (select(gpsPoints)
            ..where((p) => p.sessionId.equals(sessionId))
            ..orderBy([(p) => OrderingTerm.asc(p.timestamp)]))
          .get();

  // Get unsynced sessions — for the Supabase sync queue
  Future<List<Session>> getUnsyncedSessions() =>
      (select(sessions)
            ..where((s) => s.isSynced.equals(false))
            ..where((s) => s.isComplete.equals(true)))
          .get();

  // ── Boat queries ───────────────────────────────────────────────

  Future<void> insertBoat(BoatsCompanion boat) => into(boats).insert(boat);

  Future<List<Boat>> getAllBoats() => select(boats).get();
  Future<void> deleteBoat(String id) =>
      (delete(boats)..where((b) => b.id.equals(id))).go();

  Stream<List<Boat>> watchAllBoats() => select(boats).watch();

  Stream<Boat?> watchActiveBoat() => (select(
    boats,
  )..where((b) => b.isActive.equals(true))).watchSingleOrNull();

  Future<Boat?> getActiveBoat() =>
      (select(boats)..where((b) => b.isActive.equals(true))).getSingleOrNull();

  // Nullable on purpose — the boat may have been deleted since the session
  Future<Boat?> getBoatById(String id) =>
      (select(boats)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<void> setActiveBoat(String id) async {
    await (update(boats)).write(const BoatsCompanion(isActive: Value(false)));
    await (update(boats)..where((b) => b.id.equals(id))).write(
      const BoatsCompanion(isActive: Value(true)),
    );
  }

  Stream<List<SessionWithBoat>> watchSessionsWithBoat() {
    final query = select(sessions).join([
      leftOuterJoin(boats, boats.id.equalsExp(sessions.boatId)),
    ])..orderBy([OrderingTerm.desc(sessions.startTime)]);

    return query.watch().map(
      (rows) => rows.map((row) {
        final session = SessionEntity.fromDb(row.readTable(sessions));
        final boatRow = row.readTableOrNull(boats);
        final boat = boatRow != null ? BoatEntity.fromDb(boatRow) : null;
        return SessionWithBoat(session: session, boat: boat);
      }).toList(),
    );
  }
}

// How drift opens the SQLite file
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // getApplicationDocumentsDirectory = app's private folder
    // Only your app can access this — safe for user data
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'sailtrack.db'));
    return NativeDatabase.createInBackground(file);
  });
}
