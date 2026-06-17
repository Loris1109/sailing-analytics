import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/providers/sensor_providers.dart';

class HeelIndicator extends ConsumerWidget {
  const HeelIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heel = ref.watch(heelProvider);

    final degrees = heel.when(
      data: (v) => v.toStringAsFixed(1),
      loading: () => '--',
      error: (_, __) => '--',
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$degrees°',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
