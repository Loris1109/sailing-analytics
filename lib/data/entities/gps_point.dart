import '../database/app_database.dart';

class GpsPointEntity {
  final String id;
  final String sessionId;
  final DateTime timestamp;
  final double lat;
  final double lon;
  final double sog;
  final double cog;
  final double heel;
  final double pitch;
  final double magHeading;
  final double accuracy;

  const GpsPointEntity({
    required this.id,
    required this.sessionId,
    required this.timestamp,
    required this.lat,
    required this.lon,
    required this.sog,
    required this.cog,
    required this.heel,
    required this.pitch,
    required this.magHeading,
    required this.accuracy,
  });

  factory GpsPointEntity.fromDb(GpsPoint row) => GpsPointEntity(
    id: row.id,
    sessionId: row.sessionId,
    timestamp: row.timestamp,
    lat: row.lat,
    lon: row.lon,
    sog: row.sog,
    cog: row.cog,
    heel: row.heel,
    pitch: row.pitch,
    magHeading: row.magHeading,
    accuracy: row.accuracy,
  );
}
