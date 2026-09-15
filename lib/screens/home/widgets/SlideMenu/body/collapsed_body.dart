import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tacktics/controllers/recording_controller.dart';
import 'package:tacktics/data/entities/session.dart';
import 'package:tacktics/providers/repository_providers.dart';
import 'package:tacktics/providers/ui_providers.dart';
import 'package:tacktics/screens/home/shadow_icon_button.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/callibration_dialog.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/session_stats_bar.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/rec_button.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/upload_dialog.dart';
import 'package:tacktics/screens/home/widgets/compassPanel/BoatMenu/boat_menu.dart';
import 'package:tacktics/screens/racing/racing_container_screen.dart';
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
                enabled: selectedSession != null,
                blockedMessage: 'Wähle zuerst eine Session aus.',
                // Beim Tippen frisch lesen statt die Kopie von oben zu
                // benutzen: das spart ein `!`, dessen Gültigkeit sonst nur
                // daran hinge, dass `enabled` daneben richtig gesetzt ist.
                onTap: () {
                  final session = ref.read(selectedSessionProvider);
                  if (session != null) _exportGpx(context, ref, session);
                },
              ),

              // In ein Training einreichen — Teil der Coach Platform und noch
              // nicht fertig, deshalb hinter dem Entwicklermodus. Der Button
              // bleibt sichtbar und erklärt sich, statt wortlos nichts zu tun.
              ShadowIconButton(
                icon: Icons.upload_rounded,
                color: Colors.black,
                devOnly: true,
                devBlockedMessage: 'Noch nicht verfügbar — tippen für Details',
                devBlockedDetails:
                    'Das Einreichen von Sessions gehört zur Coach Platform. '
                    'Sie soll Trainerinnen und Trainern erlauben, die '
                    'Aufzeichnungen einer ganzen Trainingsgruppe gemeinsam '
                    'auszuwerten und zu vergleichen, statt jede Session '
                    'einzeln anzusehen.\n\n'
                    'Die Funktion wird in einer der nächsten Versionen '
                    'freigeschaltet.',
                enabled: selectedSession != null,
                blockedMessage: 'Wähle zuerst eine Session aus.',
                onTap: () {
                  final session = ref.read(selectedSessionProvider);
                  if (session == null) return;
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => UploadDialog(session: session),
                  );
                },
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

    final rangeMeasurements = await ref
      .read(rangeMeasurementRepositoryProvider)
      .getRangeMeasurementsForSession(session.id);

    // Boot kann gelöscht worden sein — Export läuft dann ohne Bootsinfos
    final boatId = session.boatId;
    final boat = boatId == null
        ? null
        : await ref.read(boatRepositoryProvider).getBoatById(boatId);

    final service = ref.read(gpxExportServiceProvider);
    final gpx = service.buildGpx(session, boat, points, rangeMeasurements);

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
