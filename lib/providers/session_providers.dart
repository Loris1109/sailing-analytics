import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sailing_analytics/data/entities/boat.dart';
import 'package:sailing_analytics/data/entities/gps_point.dart';
import 'package:sailing_analytics/data/entities/session.dart';
import 'package:sailing_analytics/data/entities/session_with_boat.dart';
import 'package:sailing_analytics/data/services/gps_service.dart';
import 'package:sailing_analytics/providers/repository_providers.dart';

// ─── lib/providers/session_providers.dart ───
// StreamProviders for what the screen displays

final latestSessionProvider = StreamProvider<SessionEntity?>((ref) {
  return ref
      .watch(sessionRepositoryProvider)
      .watchSessions()
      .map((list) => list.isEmpty ? null : list.first);
});

final sessionsStreamProvider = StreamProvider<List<SessionEntity>>((ref) {
  return ref.watch(sessionRepositoryProvider).watchSessions();
});

final sessionPointsProvider =
    FutureProvider.family<List<GpsPointEntity>, String>((ref, sessionId) {
      return ref.read(sessionRepositoryProvider).getPointsForSession(sessionId);
    });

final currentPositionProvider = FutureProvider<Position?>((ref) async {
  final pos = await GpsService.getLastKnownPosition();
  return pos;
});

final sessionsWithBoatProvider = StreamProvider<List<SessionWithBoat>>((ref) {
  return ref.watch(sessionRepositoryProvider).watchSessionsWithBoat();
});

final boatByIdProvider = FutureProvider.family<BoatEntity?, String>((
  ref,
  boatId,
) {
  return ref.watch(boatRepositoryProvider).getBoatById(boatId);
});
