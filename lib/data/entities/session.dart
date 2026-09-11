import '../database/app_database.dart';

class SessionEntity {
  final String id;
  final String name;
  final String? boatId;
  final DateTime startTime;
  final DateTime? endTime;
  final double? distance;
  final double? windDirection;
  final bool isComplete;

  // ── Kennzahlen, beim Beenden einmal gerechnet ────────────────────
  // Siehe session_stats.dart. Null bei Sessions, die noch nie durch die
  // Berechnung gelaufen sind — die UI zeigt dann "—".
  final double? peakSpeed; // kn, über 2 s gemittelt
  final double? avgMovingSpeed; // kn, zeitgewichtet, ohne Stillstand
  final Duration? movingTime;
  final int? tacks;

  const SessionEntity({
    required this.id,
    required this.name,
    this.boatId,
    required this.startTime,
    this.endTime,
    this.distance,
    this.windDirection,
    this.isComplete = false,
    this.peakSpeed,
    this.avgMovingSpeed,
    this.movingTime,
    this.tacks,
  });

  factory SessionEntity.fromDb(Session row) => SessionEntity(
    id: row.id,
    name: row.name,
    boatId: row.boatId,
    startTime: row.startTime,
    endTime: row.endTime,
    distance: row.distance,
    windDirection: row.windDirection,
    isComplete: row.isComplete,
    peakSpeed: row.peakSpeed,
    avgMovingSpeed: row.avgMovingSpeed,
    movingTime: row.movingSeconds != null
        ? Duration(seconds: row.movingSeconds!)
        : null,
    tacks: row.tacks,
  );

  SessionEntity copyWith({
    String? name,
    String? boatId,
    DateTime? startTime,
    DateTime? endTime,
    double? distance,
    double? windDirection,
    bool? isComplete,
    double? peakSpeed,
    double? avgMovingSpeed,
    Duration? movingTime,
    int? tacks,
  }) {
    return SessionEntity(
      id: id,
      name: name ?? this.name,
      boatId: boatId ?? this.boatId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distance: distance ?? this.distance,
      windDirection: windDirection ?? this.windDirection,
      isComplete: isComplete ?? this.isComplete,
      peakSpeed: peakSpeed ?? this.peakSpeed,
      avgMovingSpeed: avgMovingSpeed ?? this.avgMovingSpeed,
      movingTime: movingTime ?? this.movingTime,
      tacks: tacks ?? this.tacks,
    );
  }
}
