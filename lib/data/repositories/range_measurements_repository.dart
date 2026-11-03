import 'dart:developer' as dev;
import 'package:drift/drift.dart';
import 'package:tacktics/data/database/app_database.dart';
import 'package:tacktics/data/entities/range_measurements.dart';

class RangeMeasurementRepository {
  final AppDatabase _db;

  RangeMeasurementRepository(this._db);

  // Batch speichern — beim Recording alle BLE-Pakete seit dem letzten
  // GPS-Fix in einer Transaktion, statt jedes Paket einzeln
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
