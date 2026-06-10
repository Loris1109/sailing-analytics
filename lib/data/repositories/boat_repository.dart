import 'package:drift/drift.dart';
import 'package:sailing_analytics/data/database/app_database.dart';
import 'package:sailing_analytics/data/entities/boat.dart';
import 'package:uuid/uuid.dart';

class BoatRepository {
  final AppDatabase _db;
  const BoatRepository(this._db);

  Future<List<BoatEntity>> getBoats() =>
      _db.getAllBoats().then((boats) => boats.map(BoatEntity.fromDb).toList());

  Stream<List<BoatEntity>> watchBoats() =>
      _db.watchAllBoats().map((boats) => boats.map(BoatEntity.fromDb).toList());

  Stream<BoatEntity?> watchActiveBoat() => _db.watchActiveBoat().map(
    (boat) => boat != null ? BoatEntity.fromDb(boat) : null,
  );

  Future<BoatEntity?> getActiveBoat() => _db.getActiveBoat().then(
    (boat) => boat != null ? BoatEntity.fromDb(boat) : null,
  );

  Future<void> addBoat(BoatEntity boat) => _db.insertBoat(
    BoatsCompanion.insert(
      id: const Uuid().v4(),
      name: boat.name,
      sailNumber: boat.sailNumber,
      boatClass: boat.boatClass,
      maxSpeed: boat.maxSpeed,
      isActive: Value(boat.isActive),
    ),
  );

  Future<void> setActiveBoat(String id) => _db.setActiveBoat(id);

  Future<void> deleteBoat(String id) => _db.deleteBoat(id);
}
