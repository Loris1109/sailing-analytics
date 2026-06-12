import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/data/entities/gps_point.dart';
import 'package:sailing_analytics/data/services/performance_calc.dart';
import 'package:sailing_analytics/providers/session_providers.dart';
import 'package:sailing_analytics/providers/ui_providers.dart';

class SessionStatsBar extends ConsumerWidget {
  const SessionStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(selectedSessionProvider);

    final points = session != null
        ? ref.watch(sessionPointsProvider(session.id)).value ??
              <GpsPointEntity>[]
        : <GpsPointEntity>[];

    final speeds = points.map((p) => p.sog).toList();
    final maxSpeed = speeds.isEmpty ? null : speeds.reduce(max);
    final avgSpeed = speeds.isEmpty
        ? null
        : speeds.reduce((a, b) => a + b) / speeds.length;

    // Ø VMG über die Am-Wind-Punkte (|TWA| < 90°) — über Wenden hinweg
    // gemittelt wäre der Wert sonst wertlos. Ohne Windrichtung bleibt "—".
    final wind = session?.windDirection;
    double? avgVmgUpwind;
    if (wind != null && points.isNotEmpty) {
      final upwindVmgs = points
          .map((p) => vmg(p.sog, twa(p.cog, wind)))
          .where((v) => v > 0)
          .toList();
      if (upwindVmgs.isNotEmpty) {
        avgVmgUpwind =
            upwindVmgs.reduce((a, b) => a + b) / upwindVmgs.length;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(label: 'Max', value: maxSpeed, unit: 'kn'),
        _StatItem(label: 'AVG', value: avgSpeed, unit: 'kn'),
        _StatItem(label: 'Dist', value: session?.distance, unit: 'm'),
        _StatItem(label: 'VMG', value: avgVmgUpwind, unit: 'kn'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;

  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final display = value != null ? '${value!.toStringAsFixed(1)} $unit' : '—';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          display,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
