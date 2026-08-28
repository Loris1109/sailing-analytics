import 'dart:developer' as dev;
import 'package:drift/drift.dart';
import 'package:sailing_analytics/data/database/app_database.dart';
import 'package:sailing_analytics/data/entities/range_measurements.dart';

class RangeMeasurementRepository {
  final AppDatabase _db;

  RangeMeasurementRepository(this._db);

  // Einzeln speichern (beim Recording, per BLE-Advertisement)
  Future<void> insertRangeMeasurement(RangeMeasurementEntity m) async {
    try {
      await _db.insertRangeMeasurement(
        RangeMeasurementsCompanion(
          id: Value(m.id),
          sessionId: Value(m.sessionId),
          gpsPointId: Value(m.gpsPointId),
          peerId: Value(m.peerId),
          tech: Value(m.tech),
          rssi: Value(m.rssi),
          distance: Value(m.distance),
          quality: Value(m.quality),
          timestamp: Value(m.timestamp),
        ),
      );
      dev.log('✅ RangeMeasurement saved: ${m.peerId}/${m.tech} for GPS ${m.gpsPointId.substring(0, 8)}...');
    } catch (e) {
      dev.log('❌ Failed to insert RangeMeasurement: $e', error: e);
      rethrow;
    }
  }

  // Batch speichern (beim Upload)
  Future<void> insertRangeMeasurements(List<RangeMeasurementEntity> ms) async {
    await _db.insertRangeMeasurements(
      ms
          .map(
            (m) => RangeMeasurementsCompanion(
              id: Value(m.id),
              sessionId: Value(m.sessionId),
              gpsPointId: Value(m.gpsPointId),
              peerId: Value(m.peerId),
              tech: Value(m.tech),
              rssi: Value(m.rssi),
              distance: Value(m.distance),
              quality: Value(m.quality),
              timestamp: Value(m.timestamp),
            ),
          )
          .toList(),
    );
  }

  // Alle Messungen einer Session holen
  Future<List<RangeMeasurementEntity>> getRangeMeasurementsForSession(
    String sessionId,
  ) async {
    dev.log('📊 Fetching RangeMeasurements for session $sessionId...');
    final rows = await _db.getRangeMeasurementsForSession(sessionId);
    dev.log('✅ Found ${rows.length} RangeMeasurements');
    return rows.map((r) => RangeMeasurementEntity.fromDb(r)).toList();
  }
}
