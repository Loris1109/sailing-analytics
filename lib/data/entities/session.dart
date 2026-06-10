import '../database/app_database.dart';

class SessionEntity {
  final String id;
  final String name;
  final String boatId;
  final DateTime startTime;
  final DateTime? endTime;
  final double? distance;
  final double? windDirection;
  final bool isComplete;

  const SessionEntity({
    required this.id,
    required this.name,
    required this.boatId,
    required this.startTime,
    this.endTime,
    this.distance,
    this.windDirection,
    this.isComplete = false,
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
  );

  SessionEntity copyWith({
    String? name,
    String? boatId,
    DateTime? startTime,
    DateTime? endTime,
    double? distance,
    double? windDirection,
    bool? isComplete,
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
    );
  }
}
