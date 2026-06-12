import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/providers/session_providers.dart';

class ExpandedHeader extends ConsumerWidget {
  const ExpandedHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(sessionsStreamProvider).value?.length ?? 0;

    return Row(
      children: [
        const Expanded(
          child: Center(
            child: Text(
              'Sessions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Text(
          '$count total',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
