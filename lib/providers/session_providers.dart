import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tacktics/data/entities/boat.dart';
import 'package:tacktics/data/entities/gps_point.dart';
import 'package:tacktics/data/entities/session.dart';
import 'package:tacktics/data/entities/session_with_boat.dart';
import 'package:tacktics/data/services/gps_service.dart';
import 'package:tacktics/data/services/session_stats.dart';
import 'package:tacktics/data/services/speed_profile.dart';
import 'package:tacktics/providers/ui_providers.dart';
import 'package:tacktics/providers/repository_providers.dart';

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

/// Die Punkte, die tatsächlich gezeigt werden: die Session, beschnitten auf
/// den aufgezogenen Ausschnitt.
///
/// Als abgeleiteter Provider und nicht im build der Karte gefiltert — dort
/// liefe der Durchlauf bei jedem Rebuild erneut, und beim Ziehen am Griff
/// heißt das: je Frame. Riverpod rechnet nur nach, wenn sich Punkte oder
/// Ausschnitt wirklich geändert haben.
final visiblePointsProvider =
    FutureProvider.family<List<GpsPointEntity>, String>((ref, sessionId) async {
      final points = await ref.watch(sessionPointsProvider(sessionId).future);
      final range = ref.watch(trimRangeProvider);
      return range?.apply(points) ?? points;
    });

/// Das Speed-Profil der Session für die Trim-Leiste, null wenn sich keine
/// Zeitachse aufspannen lässt (siehe buildSpeedProfile).
///
/// Gekeyt allein auf die Session, nicht auf die Breite der Leiste: Riverpod
/// cacht das Ergebnis dann über Drehungen und das Auf- und Zuziehen des
/// Panels hinweg. Der Durchlauf über die Punkte passiert einmal je Session.
final speedProfileProvider = FutureProvider.family<SpeedProfile?, String>((
  ref,
  sessionId,
) async {
  final points = await ref.watch(sessionPointsProvider(sessionId).future);
  return buildSpeedProfile(points);
});

/// Die drei Zahlen der Statistikleiste. Alle nullable: eine Session aus einer
/// älteren Version hat sie noch nicht, und die Leiste zeigt dann "—".
typedef DisplayStats = ({
  double? peakSpeed,
  double? avgMovingSpeed,
  double? distance,
});

/// Wie lange nach der letzten Änderung am Ausschnitt gerechnet wird.
///
/// Beim Ziehen am Griff ändert sich der Ausschnitt in JEDEM Frame, und die
/// Kennzahlen sind ein voller Durchlauf über die Punkte — der darf nicht
/// 60-mal je Sekunde laufen. Die Karte folgt trotzdem sofort: die schneidet
/// nur die Liste zu, sie rechnet nichts.
const _statsDebounce = Duration(milliseconds: 250);

/// Kennzahlen dessen, was die Karte gerade zeigt.
///
/// Ohne gesetzten Ausschnitt sind das die beim Beenden gespeicherten Werte
/// aus der Sessionzeile — dann wird hier nichts gerechnet und nichts geladen,
/// genau wie vorher. Erst ein Ausschnitt löst eine eigene Rechnung über die
/// beschnittene Punktliste aus.
final visibleStatsProvider = FutureProvider<DisplayStats?>((ref) async {
  final selected = ref.watch(selectedSessionProvider);
  if (selected == null) return null;

  // Nicht die Kopie aus dem Antippen, sondern der Stand aus der DB: die
  // Kennzahlen entstehen teilweise erst danach (recomputeOutdatedStats beim
  // App-Start). Ohne diesen Nachschlag zeigt die Leiste für eine in dem
  // Moment ausgewählte Session "—", bis man sie erneut antippt.
  final rows = ref.watch(sessionsStreamProvider).value;
  final session = rows?.firstWhere(
        (row) => row.id == selected.id,
        orElse: () => selected,
      ) ??
      selected;

  final range = ref.watch(trimRangeProvider);
  if (range == null) {
    return (
      peakSpeed: session.peakSpeed,
      avgMovingSpeed: session.avgMovingSpeed,
      distance: session.distance,
    );
  }

  // Abhängigkeiten VOR dem Warten anmelden — nach einem await ist `ref`
  // nicht mehr der richtige Ort dafür.
  final pointsFuture = ref.watch(visiblePointsProvider(selected.id).future);
  final boatId = session.boatId;
  final boatFuture = boatId == null
      ? null
      : ref.watch(boatByIdProvider(boatId).future);

  // Riverpod wirft die laufende Rechnung beim nächsten Frame ohnehin weg —
  // hier wird sie gar nicht erst begonnen. Der Rückgabewert nach einem
  // Abbruch wird nicht mehr gelesen.
  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future<void>.delayed(_statsDebounce);
  if (cancelled) return null;

  final points = await pointsFuture;
  if (points.isEmpty) return null;

  // Boot kann gelöscht sein — die Aufzeichnung überlebt es, die
  // Wendenerkennung fällt dann auf den Standardwinkel zurück.
  final tackAngle = (await boatFuture)?.tackAngle ?? kDefaultTackAngle;
  final stats = computeSessionStats(points, tackAngleDeg: tackAngle);

  return (
    peakSpeed: stats.peakSpeed,
    avgMovingSpeed: stats.avgMovingSpeed,
    distance: stats.distanceMeters,
  );
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
