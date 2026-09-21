import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tacktics/providers/session_providers.dart';
import 'package:tacktics/providers/ui_providers.dart';
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
              // Teilt später den Ausschnitt statt der ganzen Session.
              const ShadowIconButton(icon: Icons.share_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

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
