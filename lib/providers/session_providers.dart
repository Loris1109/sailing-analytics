import 'dart:math' as math;

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

/// Langsamster und schnellster Punkt einer Session, null wenn sie leer ist.
///
/// Abgeleitet statt im build gerechnet: dort liefen zwei O(n)-Durchläufe über
/// alle Punkte bei jedem Rebuild des HomeScreens — bei 4 Hz sind das nach
/// einer Stunde 14 400 Werte. Riverpod cacht das Ergebnis pro Session.
final sessionSpeedRangeProvider =
    FutureProvider.family<({double min, double max})?, String>((
      ref,
      sessionId,
    ) async {
      final points = await ref.watch(sessionPointsProvider(sessionId).future);
      if (points.isEmpty) return null;

      final speeds = points.map((p) => p.sog);
      return (min: speeds.reduce(math.min), max: speeds.reduce(math.max));
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
