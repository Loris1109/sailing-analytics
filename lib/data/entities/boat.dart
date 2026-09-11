import 'package:sailing_analytics/data/database/app_database.dart';

class BoatEntity {
  final String id;
  final String sailNumber;
  final String name;
  final String boatClass;
  final double maxSpeed;

  /// Winkel zwischen den beiden Am-Wind-Kursen in Grad, Europe: 90°.
  /// Klassenabhängig, aus kBoatClasses vorbelegt. Speist die
  /// Wendenerkennung — nicht direkt als Schwelle, siehe
  /// `maneuverThresholdDeg` in session_stats.dart.
  final double tackAngle;

  final bool isActive;

  const BoatEntity({
    required this.id,
    required this.sailNumber,
    required this.name,
    required this.boatClass,
    required this.maxSpeed,
    required this.tackAngle,
    required this.isActive,
  });

  factory BoatEntity.fromDb(Boat row) => BoatEntity(
    id: row.id,
    name: row.name,
    sailNumber: row.sailNumber,
    boatClass: row.boatClass,
    maxSpeed: row.maxSpeed,
    tackAngle: row.tackAngle,
    isActive: row.isActive,
  );

  BoatEntity copyWith({
    String? name,
    String? sailNumber,
    String? boatClass,
    double? maxSpeed,
    double? tackAngle,
    bool? isActive,
  }) {
    return BoatEntity(
      id: id,
      name: name ?? this.name,
      sailNumber: sailNumber ?? this.sailNumber,
      boatClass: boatClass ?? this.boatClass,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      tackAngle: tackAngle ?? this.tackAngle,
      isActive: isActive ?? this.isActive,
    );
  }
}
