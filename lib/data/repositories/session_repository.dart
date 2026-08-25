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
        boatId: boatId,
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

    // Distanz berechnen
    const calc = Distance();
    double totalMeters = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalMeters += calc(
        LatLng(points[i].lat, points[i].lon),
        LatLng(points[i + 1].lat, points[i + 1].lon),
      );
    }
    await _db.completeSession(id, DateTime.now(), totalMeters);
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
    final id = const Uuid().v4();
    await _db.insertGpsPoint(
      GpsPointsCompanion.insert(
        id: id,
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
    return id; // ID zurückgeben, damit z.B. Range Measurements darauf verweisen können
  }

  Future<List<GpsPointEntity>> getPointsForSession(String sessionId) async {
    final rows = await _db.getPointsForSession(sessionId);
    return rows.map(GpsPointEntity.fromDb).toList();
  }
}
