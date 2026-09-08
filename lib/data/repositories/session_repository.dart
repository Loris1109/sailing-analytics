// lib/data/repositories/session_repository.dart
// This sits between your controllers and the database
// Controllers never touch AppDatabase directly

import 'package:drift/drift.dart' show Value;
import 'package:latlong2/latlong.dart';
import 'package:sailing_analytics/data/entities/session_with_boat.dart';
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

    // Distanz berechnen
    const calc = Distance();
    double totalMeters = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalMeters += calc(
        LatLng(points[i].lat, points[i].lon),
        LatLng(points[i + 1].lat, points[i + 1].lon),
      );
    }

    // Ende ist der letzte Fix, nicht der Moment des Beendens. Nur so liefert
    // eine nachträgliche Reparatur dasselbe Ergebnis wie ein sauberer Stopp —
    // sonst stünde dort der Zeitpunkt des nächsten App-Starts.
    await _db.completeSession(id, points.last.timestamp, totalMeters);
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
