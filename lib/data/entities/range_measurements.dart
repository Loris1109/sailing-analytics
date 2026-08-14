import '../database/app_database.dart';

class RangeMeasurementEntity {
  final String id;
  final String sessionId;
  final String gpsPointId;
  final String peerId;
  final String tech; // 'ble' | 'uwb'
  final int? rssi;
  final int? distance;
  final int? quality;
  final DateTime timestamp;

  const RangeMeasurementEntity({
    required this.id,
    required this.sessionId,
    required this.gpsPointId,
    required this.peerId,
    required this.tech,
    this.rssi,
    this.distance,
    this.quality,
    required this.timestamp,
  });

  factory RangeMeasurementEntity.fromDb(RangeMeasurement row) =>
      RangeMeasurementEntity(
        id: row.id,
        sessionId: row.sessionId,
        gpsPointId: row.gpsPointId,
        peerId: row.peerId,
        tech: row.tech,
        rssi: row.rssi,
        distance: row.distance,
        quality: row.quality,
        timestamp: row.timestamp,
      );

  RangeMeasurementEntity copyWith({
    String? id,
    String? sessionId,
    String? gpsPointId,
    String? peerId,
    String? tech,
    int? rssi,
    int? distance,
    int? quality,
    DateTime? timestamp,
  }) => RangeMeasurementEntity(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    gpsPointId: gpsPointId ?? this.gpsPointId,
    peerId: peerId ?? this.peerId,
    tech: tech ?? this.tech,
    rssi: rssi ?? this.rssi,
    distance: distance ?? this.distance,
    quality: quality ?? this.quality,
    timestamp: timestamp ?? this.timestamp,
  );
}
