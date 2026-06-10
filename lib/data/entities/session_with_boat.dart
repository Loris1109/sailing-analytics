import 'package:sailing_analytics/data/entities/boat.dart';
import 'package:sailing_analytics/data/entities/session.dart';

class SessionWithBoat {
  final SessionEntity session;
  final BoatEntity? boat;

  const SessionWithBoat({required this.session, this.boat});
}
