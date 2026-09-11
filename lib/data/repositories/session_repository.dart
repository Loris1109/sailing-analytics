// lib/data/repositories/session_repository.dart
// This sits between your controllers and the database
// Controllers never touch AppDatabase directly

import 'package:drift/drift.dart' show Value;
import 'package:sailing_analytics/data/entities/session_with_boat.dart';
import 'package:sailing_analytics/data/services/session_stats.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../entities/gps_point.dart';
import '../entities/session.dart';

class SessionRepository {
  final AppDatabase _db;
  const SessionRepository(this._db);

  // ── Sessions ───────────────────────────────────────────────────

  Future<String> createSession({
    required String name,
    required String boatId,
  }) async {
    final id = const Uuid().v4();
    await _db.insertSession(
      SessionsCompanion.insert(
        id: id,
        name: name,
        // Spalte ist nullable (setNull beim Löschen des Boots), eine neue
        // Session hat aber immer eines — ohne aktives Boot kommt man gar
        // nicht bis hierher
        boatId: Value(boatId),
        startTime: DateTime.now(),
      ),
    );
    return id; // return ID so controller knows which session is active
  }

  // Stream — UI rebuilds automatically when sessions change
  Stream<List<SessionEntity>> watchSessions() {
    return _db.watchAllSessions().map(
      (rows) => rows.map(SessionEntity.fromDb).toList(),
    );
  }

  Future<void> completeSession(String id) async {
    // Alle Punkte holen
    final points = await getPointsForSession(id);

    // Ohne einen einzigen Punkt gibt es nichts zu speichern und kein
    // ehrliches Ende — so eine Session ist nur Rauschen in der Liste
    if (points.isEmpty) {
      await _db.deleteSession(id);
      return;
    }

    // Distanz, Spitzenspeed, Ø fahrend und Wenden in einem Durchlauf. Die
    // Punkte sind hier ohnehin schon geladen — die Kennzahlen kosten damit
    // weder zusätzliche I/O noch einen zweiten Durchlauf.
    final stats = computeSessionStats(
      points,
      tackAngleDeg: await _tackAngleFor(id),
    );

    // Ende ist der letzte Fix, nicht der Moment des Beendens. Nur so liefert
    // eine nachträgliche Reparatur dasselbe Ergebnis wie ein sauberer Stopp —
    // sonst stünde dort der Zeitpunkt des nächsten App-Starts.
    await _db.completeSession(id, points.last.timestamp, stats);
  }

  /// Wendewinkel des Boots, mit dem die Session gefahren wurde. Fällt auf
  /// den Standardwert zurück, wenn das Boot gelöscht wurde — boatId ist dann
  /// null, die Aufzeichnung bleibt trotzdem gültig.
  Future<double> _tackAngleFor(String sessionId) async {
    final boatId = (await _db.getSessionById(sessionId))?.boatId;
    if (boatId == null) return kDefaultTackAngle;
    return (await _db.getBoatById(boatId))?.tackAngle ?? kDefaultTackAngle;
  }

  /// Rechnet Sessions nach, deren Kennzahlen aus einer älteren Version des
  /// Algorithmus stammen — oder die noch gar keine haben.
  ///
  /// Läuft beim App-Start neben [recoverIncompleteSessions]. Ohne diesen Weg
  /// wäre jede Änderung an der Formel ein Datenverlust für alles bereits
  /// Aufgezeichnete: die Werte in der DB sind eingefroren und wissen nichts
  /// von einer neuen Berechnung.
  ///
  /// Bewusst gedeckelt: jede Session lädt ihre Punkte einzeln, bei vielen
  /// Altsessions soll der Start davon nicht hängen. Jede ist für sich
  /// konsistent geschrieben, der nächste Start macht mit dem Rest weiter.
  Future<int> recomputeOutdatedStats({int limit = 20}) async {
    final rows = await _db.getSessionsWithOutdatedStats();
    var done = 0;
    for (final row in rows.take(limit)) {
      final points = await getPointsForSession(row.id);
      if (points.isEmpty) continue;
      final boat = row.boatId != null
          ? await _db.getBoatById(row.boatId!)
          : null;
      await _db.updateSessionStats(
        row.id,
        computeSessionStats(
          points,
          tackAngleDeg: boat?.tackAngle ?? kDefaultTackAngle,
        ),
      );
      done++;
    }
    return done;
  }

  /// Beendet Sessions, die nie sauber abgeschlossen wurden — leerer Akku,
  /// Hitzeabschaltung, Absturz, aus dem App-Switcher gewischt.
  ///
  /// Darf nur laufen, wenn garantiert keine Aufnahme aktiv ist, sonst würde
  /// die laufende Session mitten im Betrieb beendet. Beim App-Start ist das
  /// per Definition der Fall.
  Future<int> recoverIncompleteSessions() async {
    final rows = await _db.getIncompleteSessions();
    for (final row in rows) {
      await completeSession(row.id);
    }
    return rows.length;
  }

  Future<void> deleteSession(String id) async {
    await _db.deleteSession(id);
  }

  Future<void> updateSessionName(String id, String name) =>
      _db.updateSessionName(id, name);

  Future<void> updateWindDirection(String id, double windDirection) =>
      _db.updateWindDirection(id, windDirection);

  Stream<List<SessionWithBoat>> watchSessionsWithBoat() {
    return _db.watchSessionsWithBoat();
  }

  // ── GPS Points ─────────────────────────────────────────────────

  Future<String> savePoint(GpsPointEntity point) async {
    await _db.insertGpsPoint(
      GpsPointsCompanion.insert(
        id: point.id,
        sessionId: point.sessionId,
        timestamp: point.timestamp,
        lat: point.lat,
        lon: point.lon,
        sog: point.sog,
        cog: point.cog,
        heel: point.heel,
        pitch: Value(point.pitch),
        magHeading: Value(point.magHeading),
        accuracy: point.accuracy,
      ),
    );
    return point.id; // ID zurückgeben, damit z.B. Range Measurements darauf verweisen können
  }

  Future<List<GpsPointEntity>> getPointsForSession(String sessionId) async {
    final rows = await _db.getPointsForSession(sessionId);
    return rows.map(GpsPointEntity.fromDb).toList();
  }
}
