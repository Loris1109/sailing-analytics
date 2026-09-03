import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/ble_state_provider.dart';

class BleDebugOverlay extends ConsumerWidget {
  const BleDebugOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleStateProvider);

    return Positioned(
      top: 80,
      right: 0,
      left: 0,
      child: Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📡 BLE Debug',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      _StatusBadge(
                        label: 'Advertising',
                        isActive: bleState.isAdvertising,
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(
                        label: 'Scanning',
                        isActive: bleState.isScanning,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Events Rate
              Text(
                'Events/sec: ${bleState.eventsPerSecond}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              // Advertisements List
              Text(
                'Seen Peers (${bleState.lastAdvertisements.length}):',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              if (bleState.lastAdvertisements.isEmpty)
                const Text(
                  '  ❌ Keine Advertisements empfangen',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                )
              else
                ...bleState.lastAdvertisements.values.map((ad) {
                  final age = DateTime.now().difference(ad.timestamp).inMilliseconds;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '  • ${ad.peerId}: ${ad.rssi}dBm (${age}ms ago)',
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isActive;

  const _StatusBadge({
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
