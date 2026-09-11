import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/providers/ui_providers.dart';

/// Kennzahlen der ausgewählten Session.
///
/// Liest bewusst nur die Session, nicht ihre Punkte: die Werte stehen als
/// Spalten daneben und wurden beim Beenden einmal gerechnet (siehe
/// session_stats.dart). Die Leiste ist damit O(1) und rebuildet nur beim
/// Sessionwechsel.
///
/// Muss `const` konstruierbar bleiben. CollapsedBody baut sie als
/// `const SessionStatsBar()` — bei identischer Widget-Instanz überspringt
/// Flutter den Teilbaum, sonst liefe sie bei jedem Frame der
/// SlideMenu-Animation erneut durch.
class SessionStatsBar extends ConsumerWidget {
  const SessionStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(selectedSessionProvider);

    // Jedes _StatItem ist Expanded — vier gleich breite Spalten, damit
    // "Ø Fahrt" neben "Dist" nicht umbricht.
    return Row(
      children: [
        // Über 2 s gemittelt, nicht ein einzelner GPS-Sample — ein Ausreißer
        // wäre sonst der Rekord.
        _StatItem(label: 'Max 2s', value: _knots(session?.peakSpeed)),
        // Ohne Stillstand: Warten vor dem Start verwässert den Schnitt sonst.
        _StatItem(label: 'Ø Fahrt', value: _knots(session?.avgMovingSpeed)),
        _StatItem(label: 'Dist', value: _distance(session?.distance)),
        // Wenden, nicht Manöver: Halsen erkennt die COG-Schwelle nicht,
        // siehe maneuverThresholdDeg.
        _StatItem(label: 'Wenden', value: session?.tacks?.toString()),
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
