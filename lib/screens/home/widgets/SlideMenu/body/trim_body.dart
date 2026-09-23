import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tacktics/providers/repository_providers.dart';
import 'package:tacktics/providers/session_providers.dart';
import 'package:tacktics/providers/ui_providers.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/gpx_share.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/save_clip_dialog.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:tacktics/screens/home/shadow_icon_button.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/session_stats_bar.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/speed_profile_chart.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/trim_brush.dart';

/// Die Arbeitsfläche des Trim-Modus: das Speed-Profil der Session, über dem
/// später die zwei Handles den sichtbaren Ausschnitt aufziehen.
///
/// Das Profil ist der Grund, warum hier kein nackter Zeitstrahl steht: beim
/// Ziehen sieht man, WAS man auswählt — die Anfahrt als schmales Band, den
/// Regattakurs als hohes, zerklüftetes, die Pausen als Lücke.
class TrimBody extends ConsumerWidget {
  const TrimBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(selectedSessionProvider);

    // Boot kann gelöscht sein — die Aufzeichnung überlebt es, die Farbskala
    // fällt dann wie bei der Karte auf 10 kn zurück.
    final boatId = session?.boatId;
    final boat = boatId != null ? ref.watch(boatByIdProvider(boatId)).value : null;
    final maxKnots = boat?.maxSpeed ?? 10.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                color: Colors.black12,
                child: session == null
                    ? null
                    : switch (ref.watch(speedProfileProvider(session.id))) {
                        AsyncData(:final value) => value == null
                            ? const _Hint('Zu wenige Punkte für ein Profil')
                            : Stack(
                                children: [
                                  SpeedProfileChart(
                                    profile: value,
                                    maxKnots: maxKnots,
                                  ),
                                  TrimBrush(profile: value),
                                ],
                              ),
                        AsyncError() => const _Hint('Profil nicht verfügbar'),
                        // Lädt: die graue Fläche steht schon, ein Spinner
                        // würde bei einer halben Sekunde nur blitzen.
                        _ => null,
                      },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Zurück in den Normalmodus. Der Ausschnitt bleibt dabei
              // bestehen — sonst könnte man ihn nie auf der ganzen Karte
              // ansehen, ohne dass das Panel im Weg steht.
              ShadowIconButton(
                icon: Icons.close_rounded,
                onTap: () => ref.read(menuModeProvider.notifier).exit(),
              ),
              const SizedBox(width: 16),
              // Zurück auf die ganze Session. Der einzige Weg dorthin: die
              // Griffe von Hand wieder ganz nach außen zu schieben, trifft
              // den Rand nie genau.
              ShadowIconButton(
                icon: Icons.restart_alt_rounded,
                enabled: ref.watch(trimRangeProvider) != null,
                blockedMessage: 'Es ist kein Ausschnitt gesetzt.',
                onTap: () => ref.read(trimRangeProvider.notifier).clear(),
              ),
              // Dieselbe Leiste wie im Normalmodus, an derselben Stelle. Sie
              // zeigt die Kennzahlen des Ausschnitts und ist hier der Grund,
              // überhaupt zu schieben: ohne sie sähe man beim Ziehen nur die
              // Karte und müsste den Modus verlassen, um die Zahlen zu lesen.
              const Expanded(child: SessionStatsBar()),
              // Sichert den Ausschnitt unter einem Namen. Gespeichert wird
              // nur die Zeitspanne — die Punkte bleiben einmal in der
              // Session liegen, egal wie viele Ausschnitte darauf zeigen.
              ShadowIconButton(
                icon: Icons.bookmark_add_rounded,
                enabled: session != null && ref.watch(trimRangeProvider) != null,
                blockedMessage: 'Zieh zuerst einen Ausschnitt auf.',
                onTap: () => _saveClip(context, ref),
              ),
              const SizedBox(width: 12),
              // Exportiert den Ausschnitt statt der ganzen Session. Ohne
              // gesetzten Ausschnitt ist das die ganze Session — dieselbe
              // Bedeutung wie überall sonst im Trim-Modus.
              ShadowIconButton(
                icon: Icons.share_rounded,
                enabled: session != null,
                blockedMessage: 'Wähle zuerst eine Session aus.',
                onTap: () => _shareClip(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fragt den Namen ab und legt den Ausschnitt an.
///
/// Liest Session und Spanne beim Tippen frisch statt die Werte von oben zu
/// benutzen — zwischen Aufbau und Tipp kann sich beides geändert haben.
Future<void> _saveClip(BuildContext context, WidgetRef ref) async {
  final session = ref.read(selectedSessionProvider);
  final range = ref.read(trimRangeProvider);
  if (session == null || range == null) return;

  final name = await showSaveClipDialog(
    context,
    start: range.start,
    end: range.end,
  );
  if (name == null) return;

  await ref
      .read(sessionRepositoryProvider)
      .saveClip(sessionId: session.id, name: name, range: range);

  if (context.mounted) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(message: '„$name" gespeichert'),
    );
  }
}

/// Exportiert den aufgezogenen Ausschnitt als GPX.
///
/// Der Name der Datei kommt, wenn möglich, vom gespeicherten Ausschnitt:
/// wer „Rennen 2" angesehen und dann geteilt hat, erwartet „Rennen 2" im
/// Dateinamen und nicht eine Uhrzeitspanne. Gibt es keinen passenden
/// Eintrag, tut es die Spanne.
Future<void> _shareClip(BuildContext context, WidgetRef ref) async {
  final session = ref.read(selectedSessionProvider);
  if (session == null) return;

  final range = ref.read(trimRangeProvider);
  String? clipName;
  if (range != null) {
    final clips = ref.read(sessionClipsProvider(session.id)).value ?? [];
    final saved = clips.where((c) => c.range == range).firstOrNull;
    clipName = saved?.name ?? '${_hm(range.start)}–${_hm(range.end)}';
  }

  await shareSessionGpx(
    context,
    ref,
    session: session,
    range: range,
    clipName: clipName,
  );
}

String _hm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    ),
  );
}
