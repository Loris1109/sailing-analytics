import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tacktics/controllers/recording_controller.dart';
import 'package:tacktics/data/services/gps_service.dart';
import 'package:tacktics/providers/repository_providers.dart';
import 'package:tacktics/providers/ui_providers.dart';
import 'package:tacktics/screens/home/shadow_icon_button.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/callibration_dialog.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/gpx_share.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/session_stats_bar.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/rec_button.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/upload_dialog.dart';
import 'package:tacktics/screens/home/widgets/compassPanel/BoatMenu/boat_menu.dart';
import 'package:tacktics/screens/racing/racing_container_screen.dart';
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

          // Trim — tauscht den Body gegen die Trim-Ansicht aus, statt einen
          // eigenen Screen zu öffnen: beim Aufziehen des Ausschnitts muss
          // man die Karte sehen.
          ShadowIconButton(
            icon: Icons.cut_rounded,
            enabled: selectedSession != null,
            // Markiert, dass die Karte gerade nur einen Ausschnitt zeigt.
            // Ohne das wäre der Trim-Modus nach dem Verlassen unsichtbar und
            // die halbe Session wäre grundlos verschwunden.
            active: ref.watch(trimRangeProvider) != null,
            blockedMessage: 'Wähle zuerst eine Session aus.',
            onTap: () {
              // Zusammen mit dem Modus auch einklappen: der Brush lebt im
              // zugeklappten Trim-Body. Wer aus der offenen Sessionliste
              // kommt, landet sonst in der leeren Ausschnittsliste.
              ref.read(isExpandedProvider.notifier).close();
              ref.read(menuModeProvider.notifier).enterTrim();
            },
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              // GPX-Export
              ShadowIconButton(
                icon: Icons.share_rounded,
                enabled: selectedSession != null,
                blockedMessage: 'Wähle zuerst eine Session aus.',
                onTap: () {
                  final session = ref.read(selectedSessionProvider);
                  if (session != null) {
                    shareSessionGpx(context, ref, session: session);
                  }
                },
              ),

              //Upload
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

    final failure = await controller.startRecording(
      name: 'Training ${now.day}.${now.month}.${now.year % 100}',
      boatId: activeBoot.id,
    );

    if (!context.mounted) return;

    // Erst prüfen, dann navigieren. Vorher ging es in jedem Fall weiter —
    // wer die Standortfreigabe ablehnte, landete auf einem Racing-Screen,
    // der nichts aufzeichnete und nicht sagte, warum.
    if (failure != null) {
      _showStartFailure(context, failure);
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RacingContainerScreen()));
  }

  /// Sagt, was schiefging — und wo es zu beheben ist.
  ///
  /// Der dauerhaft abgelehnte Fall bekommt die Einstellungen an einen Tipp
  /// auf die Meldung gehängt, statt den Nutzer von sich aus dorthin zu
  /// werfen: so weiß er vorher, wohin er geht und warum.
  void _showStartFailure(BuildContext context, StartFailure failure) {
    final (message, onTap) = switch (failure) {
      StartFailure.locationServiceOff => (
        'Der Standortdienst ist ausgeschaltet. Schalte GPS ein und versuch es erneut.',
        null,
      ),
      StartFailure.locationDenied => (
        'Ohne Standortfreigabe kann Tacktics nichts aufzeichnen.',
        null,
      ),
      StartFailure.locationDeniedForever => (
        'Die Standortfreigabe ist dauerhaft abgelehnt — tippen, um sie in den Einstellungen zu erlauben.',
        GpsService.openSettings,
      ),
      StartFailure.alreadyRecording => (
        'Es läuft bereits eine Aufzeichnung.',
        null,
      ),
    };

    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.error(message: message),
      onTap: onTap,
    );
  }
}
