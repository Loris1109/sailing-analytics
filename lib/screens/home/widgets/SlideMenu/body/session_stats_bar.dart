import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/providers/session_providers.dart';
import 'package:sailing_analytics/providers/ui_providers.dart';

class SessionStatsBar extends ConsumerWidget {
  const SessionStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(selectedSessionProvider);

    final points = session != null
        ? ref
              .watch(sessionPointsProvider(session.id))
              .when(data: (pts) => pts, error: (_, _) => [], loading: () => [])
        : [];

    final speeds = points.map((p) => p.sog as double).toList();
    final maxSpeed = speeds.isEmpty ? null : speeds.reduce(max);
    final avgSpeed = speeds.isEmpty
        ? null
        : speeds.reduce((a, b) => a + b) / speeds.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(label: 'Max', value: maxSpeed, unit: 'kn'),
        _StatItem(label: 'AVG', value: avgSpeed, unit: 'kn'),
        _StatItem(label: 'Dist', value: session?.distance, unit: 'm'),
        const _StatItem(label: 'VMG', value: null, unit: 'kn'),
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
