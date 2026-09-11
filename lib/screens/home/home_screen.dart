import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:sailing_analytics/controllers/recording_controller.dart';
import 'package:sailing_analytics/data/entities/gps_point.dart';
import 'package:sailing_analytics/providers/repository_providers.dart';
import 'package:sailing_analytics/providers/ui_providers.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/slide_menu.dart';
import 'package:sailing_analytics/screens/home/widgets/compassPanel/compass_panel.dart';
import 'package:sailing_analytics/screens/home/widgets/map.dart';
import 'package:sailing_analytics/providers/session_providers.dart';
import 'package:sailing_analytics/screens/home/widgets/status_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Sessions reparieren, die nie beendet wurden — leerer Akku,
    // Hitzeabschaltung, Absturz. Beim Start läuft garantiert keine Aufnahme,
    // hier ist der Eingriff also sicher.
    unawaited(() async {
      final repo = ref.read(sessionRepositoryProvider);
      await repo.recoverIncompleteSessions();
      // Danach, nicht davor: die eben reparierten Sessions bekommen ihre
      // Kennzahlen schon aus completeSession und fallen hier nicht mehr an.
      await repo.recomputeOutdatedStats();
    }());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSession = ref.watch(selectedSessionProvider);
    final gpsPoints = selectedSession != null
        ? ref.watch(sessionPointsProvider(selectedSession.id)).value ??
              <GpsPointEntity>[]
        : <GpsPointEntity>[];

    final curPosition = ref.watch(currentPositionProvider).value;

    final curLatLng = curPosition != null
        ? LatLng(curPosition.latitude, curPosition.longitude)
        : null;

    ref.listen(windDirectionProvider, (_, newDirection) {
      _mapController.rotate(newDirection);
    });

    // Session ausgewählt → gespeicherte Windrichtung in den Kompass laden
    // (rotiert über den Listener oben auch gleich die Karte mit)
    ref.listen(selectedSessionProvider, (_, session) {
      if (session?.windDirection != null) {
        ref.read(windDirectionProvider.notifier).set(session!.windDirection!);
      }
    });

    ref.listen(recordingControllerProvider, (prev, next) {
      if (prev != null && !prev.isRecording && next.isRecording) {
        ref.read(selectedSessionProvider.notifier).clear();
      }
    });

    ref.listen(sessionsStreamProvider, (_, next) {
      next.whenData((sessions) {
        final selected = ref.read(selectedSessionProvider);

        // Session wurde gelöscht → deselektieren
        if (selected != null && !sessions.any((s) => s.id == selected.id)) {
          ref.read(selectedSessionProvider.notifier).clear();
          return;
        }

        // Nichts ausgewählt + Session wurde aufgenommen → auto-select
        if (selected == null) {
          final completedId = ref
              .read(recordingControllerProvider)
              .completedSessionId;
          if (completedId != null) {
            final matches = sessions.where((s) => s.id == completedId);
            if (matches.isNotEmpty) {
              ref.read(selectedSessionProvider.notifier).select(matches.first);
              // Genau einmal auto-selektieren. Ohne das Quittieren greift der
              // Block bei jeder weiteren Änderung an der Session-Tabelle
              // erneut. Bewusst erst nach dem Treffer: taucht die Zeile im
              // Stream noch nicht auf, soll der nächste Durchlauf es wieder
              // versuchen dürfen.
              ref
                  .read(recordingControllerProvider.notifier)
                  .consumeCompletedSession();
            }
          }
        }
      });
    });

    // boatId ist null, wenn das Boot inzwischen gelöscht wurde
    final boatId = selectedSession?.boatId;
    final boat = boatId != null
        ? ref.watch(boatByIdProvider(boatId)).value
        : null;

    final maxKnots = boat?.maxSpeed ?? 10.0;

    final pathMode = ref.watch(pathModeProvider);

    final speedRange = selectedSession != null
        ? ref.watch(sessionSpeedRangeProvider(selectedSession.id)).value
        : null;
    final minKnotsActual = speedRange?.min ?? 0.0;
    final maxKnotsActual = speedRange?.max ?? maxKnots;

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            mapController: _mapController,
            gpsPoints: gpsPoints,
            curPosition: curLatLng,

            pathMode: pathMode,
            maxKnots: maxKnots,
          ), // SlideMenu am unteren Rand
          Positioned(bottom: 0, left: 0, right: 0, child: SlideMenu()),

          SafeArea(
            child: Stack(
              children: [
                Positioned(top: 16, right: 16, child: CompassPanel()),
                if (gpsPoints.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: StatusBar(
                      pathMode: pathMode,
                      maxKnots: maxKnots,
                      minKnotsActual: minKnotsActual,
                      maxKnotsActual: maxKnotsActual,
                    ),
                  ),
              ],
            ),
          ), // for notch/safe area on top
        ],
      ),
    );
  }
}
