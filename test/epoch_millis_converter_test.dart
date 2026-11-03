// test/epoch_millis_converter_test.dart
// Zeitstempel in Millisekunden: der Konverter selbst und Migration 10, die
// bestehende Sekundenwerte umrechnet. Die Migration läuft gegen eine echte
// SQLite-Datei — genau so, wie ein App-Update sie auf dem Handy vorfindet.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tacktics/data/database/app_database.dart';
import 'package:tacktics/data/database/epoch_millis_converter.dart';

void main() {
  const converter = EpochMillisConverter();

  test('Hin- und Rückweg erhält die Millisekunden', () {
    final t = DateTime(2026, 11, 3, 12, 0, 0, 123);
    final sql = converter.toSql(t);

    expect(sql, t.millisecondsSinceEpoch);
    expect(converter.fromSql(sql), t);
    expect(converter.fromSql(sql).millisecond, 123);
  });

  group('Migration 10', () {
    late Directory dir;
    late File file;

    // Eine Sekunde, wie Drift sie bis Schema 9 geschrieben hat
    final start = DateTime(2026, 9, 9, 12);
    final end = DateTime(2026, 9, 9, 13);
    int secs(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('tacktics_migration_');
      file = File('${dir.path}/db.sqlite');

      // Schema anlegen lassen — die Spalten sind in 9 und 10 identisch
      // INTEGER, nur die Einheit unterscheidet sich
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.customStatement(
        'INSERT INTO sessions (id, name, start_time, end_time) '
        "VALUES ('s1', 'Alt', ${secs(start)}, ${secs(end)}), "
        "('s2', 'Offen', ${secs(start)}, NULL)",
      );
      await db.customStatement(
        'INSERT INTO gps_points (id, session_id, timestamp, lat, lon, sog, cog, heel, accuracy) '
        "VALUES ('p1', 's1', ${secs(start)}, 53.3, 13.9, 4, 200, 0, 3)",
      );
      await db.customStatement(
        'INSERT INTO range_measurements (id, session_id, gps_point_id, peer_id, tech, rssi, timestamp) '
        "VALUES ('r1', 's1', 'p1', 'GER 7', 'ble', -60, ${secs(start)})",
      );
      await db.customStatement(
        'INSERT INTO session_clips (id, session_id, name, start_time, end_time) '
        "VALUES ('c1', 's1', 'Rennen 1', ${secs(start)}, ${secs(end)})",
      );
      // So, als käme die Datei aus der Vorversion
      await db.customStatement('PRAGMA user_version = 9');
      await db.close();
    });

    tearDown(() => dir.delete(recursive: true));

    Future<void> expectMigrated(AppDatabase db) async {
      final s1 = await db.getSessionById('s1');
      expect(s1!.startTime, start);
      expect(s1.endTime, end);

      final s2 = await db.getSessionById('s2');
      expect(s2!.startTime, start);
      expect(s2.endTime, isNull);

      final points = await db.getPointsForSession('s1');
      expect(points.single.timestamp, start);

      final ms = await db.getRangeMeasurementsForSession('s1');
      expect(ms.single.timestamp, start);

      final clip = await db.select(db.sessionClips).getSingle();
      expect(clip.startTime, start);
      expect(clip.endTime, end);
    }

    test('alte Sekundenwerte werden zu denselben Zeitpunkten', () async {
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await expectMigrated(db);
      await db.close();
    });

    test('ein zweiter Durchlauf rechnet nichts doppelt um', () async {
      var db = AppDatabase.forTesting(NativeDatabase(file));
      await expectMigrated(db);
      await db.customStatement('PRAGMA user_version = 9');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      await expectMigrated(db);
      await db.close();
    });

    test('neue Werte behalten nach der Migration ihre Millisekunden', () async {
      final db = AppDatabase.forTesting(NativeDatabase(file));
      final t = DateTime(2026, 11, 3, 12, 0, 0, 456);
      await db.insertGpsPoint(
        GpsPointsCompanion.insert(
          id: 'p2',
          sessionId: 's1',
          timestamp: t,
          lat: 53.3,
          lon: 13.9,
          sog: 4,
          cog: 200,
          heel: 0,
          accuracy: 3,
        ),
      );

      final points = await db.getPointsForSession('s1');
      expect(points.last.timestamp, t);
      expect(points.last.timestamp.millisecond, 456);
      await db.close();
    });
  });
}
