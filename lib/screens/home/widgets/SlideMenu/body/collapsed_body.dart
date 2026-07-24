import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sailing_analytics/ble-spike/ble_spike_screen.dart';
import 'package:sailing_analytics/controllers/recording_controller.dart';
import 'package:sailing_analytics/data/entities/session.dart';
import 'package:sailing_analytics/providers/repository_providers.dart';
import 'package:sailing_analytics/providers/ui_providers.dart';
import 'package:sailing_analytics/screens/home/shadow_icon_button.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/body/callibration_dialog.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/body/session_stats_bar.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/body/rec_button.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/body/upload_dialog.dart';
import 'package:sailing_analytics/screens/home/widgets/compassPanel/BoatMenu/boat_menu.dart';
import 'package:sailing_analytics/screens/racing/racing_container_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class CollapsedBody extends ConsumerWidget {
  const CollapsedBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(recordingControllerProvider.notifier);
    final selectedSession = ref.watch(selectedSessionProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // REC-Knopf
          RecButton(onTap: () => _startSession(context, ref, controller)),

          // Session Stats
          const Expanded(child: SessionStatsBar()),

          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              // GPX-Export — nur aktiv wenn eine Session ausgewählt ist
              ShadowIconButton(
                icon: Icons.share_rounded,
                onTap: selectedSession == null
                    ? null
                    : () => _exportGpx(context, ref, selectedSession),
              ),

              // In ein Training einreichen — nur aktiv wenn Session ausgewählt
              ShadowIconButton(
                icon: Icons.upload_rounded,
                color: Colors.black,
                onTap: selectedSession == null
                    ? null
                    : () => showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => UploadDialog(session: selectedSession),
                      ),
                /* onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Demnächst verfügbar'),
                    content: const Text(
                      'Das Einreichen von Sessions ist Teil der Coach Platform, '
                      'welche genauere Analysen der gesamten Trainingsgruppe ermöglichen soll. '
                      'Diese Funktion wird in der kommenden Version freigeschaltet.',
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ), */
              ),

              // SPIKE: temporärer Einstieg in den BLE-Test — fliegt nach dem
              // Spike wieder raus
              ShadowIconButton(
                icon: Icons.bluetooth_searching,
                color: Colors.blue,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BleSpikeScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportGpx(
    BuildContext context,
    WidgetRef ref,
    SessionEntity session,
  ) async {
    final points = await ref
        .read(sessionRepositoryProvider)
        .getPointsForSession(session.id);

    if (points.isEmpty) {
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.info(
            message: 'Diese Session hat keine GPS-Punkte.',
          ),
        );
      }
      return;
    }

    // Boot kann gelöscht worden sein — Export läuft dann ohne Bootsinfos
    final boat = await ref
        .read(boatRepositoryProvider)
        .getBoatById(session.boatId);

    final service = ref.read(gpxExportServiceProvider);
    final gpx = service.buildGpx(session, boat, points);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${service.fileNameFor(session)}');

    await file.writeAsString(gpx);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/gpx+xml')]),
    );
  }

  Future<void> _startSession(
    BuildContext context,
    WidgetRef ref,
    RecordingController controller,
  ) async {
    final activeBoot = await ref.read(boatRepositoryProvider).getActiveBoat();

    if (activeBoot == null) {
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.info(
            message:
                'Bitte wähle zuerst ein Boot aus um eine Session zu starten.',
          ),
        );
        showModalBottomSheet(
          context: context,
          isScrollControlled: false,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const BoatMenu(),
        );
      }
      return;
    }
    final now = DateTime.now();
    if (!context.mounted) return;
    // Kalibrierung
    final calibrated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CalibrationDialog(),
    );
    if (calibrated != true) return; // User hat abgebrochen

    await controller.startRecording(
      name: 'Training ${now.day}.${now.month}.${now.year % 100}',
      boatId: activeBoot.id,
    );

    if (context.mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RacingContainerScreen()));
    }
  }
}
