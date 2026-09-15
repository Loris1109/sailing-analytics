import 'package:tacktics/data/entities/boat.dart';
import 'package:tacktics/data/entities/session.dart';

class SessionWithBoat {
  final SessionEntity session;
  final BoatEntity? boat;

  const SessionWithBoat({required this.session, this.boat});
}
