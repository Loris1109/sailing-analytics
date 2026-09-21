import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tacktics/providers/session_providers.dart';

/// Kennzahlen dessen, was die Karte gerade zeigt.
///
/// Ohne gesetzten Ausschnitt sind das die Werte der ganzen Session, die beim
/// Beenden einmal gerechnet wurden und als Spalten daneben stehen — die
/// Leiste rührt die Punktliste dann nicht an. Ist ein Ausschnitt gesetzt,
/// rechnet [visibleStatsProvider] über die beschnittene Liste nach. Welcher
/// Fall gilt und was das kostet, entscheidet der Provider; hier steht nur
/// noch die Darstellung.
///
/// Muss `const` konstruierbar bleiben. CollapsedBody baut sie als
/// `const SessionStatsBar()` — bei identischer Widget-Instanz überspringt
/// Flutter den Teilbaum, sonst liefe sie bei jedem Frame der
/// SlideMenu-Animation erneut durch.
class SessionStatsBar extends ConsumerWidget {
  const SessionStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `.value` und nicht `.when`: während der Provider nach einer Änderung am
    // Ausschnitt neu rechnet, bleiben die zuletzt gültigen Zahlen stehen.
    // Ein Wechsel auf "—" und zurück wäre bei jedem Zug ein Flackern.
    final stats = ref.watch(visibleStatsProvider).value;

    // Jedes _StatItem ist Expanded — drei gleich breite Spalten, damit
    // "Ø Fahrt" neben "Dist" nicht umbricht.
    return Row(
      children: [
        // Über 2 s gemittelt, nicht ein einzelner GPS-Sample — ein Ausreißer
        // wäre sonst der Rekord.
        _StatItem(label: 'Max 2s', value: _knots(stats?.peakSpeed)),
        // Ohne Stillstand: Warten vor dem Start verwässert den Schnitt sonst.
        _StatItem(label: 'Ø Fahrt', value: _knots(stats?.avgMovingSpeed)),
        _StatItem(label: 'Dist', value: _distance(stats?.distance)),
      ],
    );
  }

  static String? _knots(double? kn) =>
      kn == null ? null : '${kn.toStringAsFixed(1)} kn';

  static String? _distance(double? m) {
    if (m == null) return null;
    return m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.round()} m';
  }
}

class _StatItem extends StatelessWidget {
  final String label;

  /// Fertig formatiert — null zeigt "—". Nicht jede Kennzahl ist eine Zahl
  /// mit fester Nachkommastelle, die Formatierung gehört zum jeweiligen Wert.
  final String? value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          Text(
            value ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
