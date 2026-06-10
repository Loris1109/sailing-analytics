import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:sailing_analytics/controllers/recording_controller.dart';
import 'package:sailing_analytics/data/entities/gps_point.dart';
import 'package:sailing_analytics/providers/ui_providers.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/slide_menu.dart';
import 'package:sailing_analytics/screens/home/widgets/compassPanel/compass_panel.dart';
import 'package:sailing_analytics/screens/home/widgets/map.dart';
import 'package:sailing_analytics/providers/session_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _mapController = MapController();
  double _mapRotation = 0.0;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    setState(() => _mapRotation = event.camera.rotation * -1);
  }

  @override
  Widget build(BuildContext context) {
    final selectedSession = ref.watch(selectedSessionProvider);
    final gpsPoints = selectedSession != null
        ? ref
              .watch(sessionPointsProvider(selectedSession.id))
              .when(
                data: (pts) => pts,
                error: (_, _) => <GpsPointEntity>[],
                loading: () => <GpsPointEntity>[],
              )
        : <GpsPointEntity>[];

    final curPosition = ref
        .watch(currentPositionProvider)
        .when(data: (pos) => pos, error: (_, _) => null, loading: () => null);

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
            }
          }
        }
      });
    });

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            mapController: _mapController,
            gpsPoints: gpsPoints,
            curPosition: curLatLng,
            onMapEvent: _onMapEvent,
          ), // SlideMenu am unteren Rand
          Positioned(bottom: 0, left: 0, right: 0, child: SlideMenu()),

          SafeArea(
            child: Stack(
              children: [Positioned(top: 16, right: 16, child: CompassPanel())],
            ),
          ), // for notch/safe area on top
        ],
      ),
    );
  }
}
