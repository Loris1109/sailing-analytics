import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tacktics/data/entities/session.dart';
import 'package:tacktics/providers/session_providers.dart';
import 'package:tacktics/providers/ui_providers.dart';

/// Kennzahlen der ausgewählten Session.
///
/// Liest bewusst nur die Session, nicht ihre Punkte: die Werte stehen als
/// Spalten daneben und wurden beim Beenden einmal gerechnet (siehe
/// session_stats.dart). Die Leiste rührt die Punktliste nicht an.
///
/// Muss `const` konstruierbar bleiben. CollapsedBody baut sie als
/// `const SessionStatsBar()` — bei identischer Widget-Instanz überspringt
/// Flutter den Teilbaum, sonst liefe sie bei jedem Frame der
/// SlideMenu-Animation erneut durch.
class SessionStatsBar extends ConsumerWidget {
  const SessionStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = _live(ref, ref.watch(selectedSessionProvider));

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

  /// Dieselbe Session, aber mit dem Stand aus der DB statt dem vom Antippen.
  ///
  /// `selectedSessionProvider` hält eine Kopie, die beim Auswählen entstanden
  /// ist. Die Kennzahlen entstehen teilweise erst DANACH: `recomputeOutdated
  /// Stats` rechnet Altsessions beim Start nach, und nach einer Änderung am
  /// Algorithmus auch alle anderen. Ohne diesen Nachschlag zeigt die Leiste
  /// für eine in dem Moment ausgewählte Session "—", bis man sie erneut
  /// antippt.
  ///
  /// Fällt auf die Kopie zurück, solange der Stream noch nichts geliefert hat
  /// oder die Zeile nicht (mehr) enthält — dann ist die Kopie das Beste, was
  /// da ist.
  static SessionEntity? _live(WidgetRef ref, SessionEntity? selected) {
    if (selected == null) return null;
    final rows = ref.watch(sessionsStreamProvider).value;
    if (rows == null) return selected;
    for (final row in rows) {
      if (row.id == selected.id) return row;
    }
    return selected;
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
