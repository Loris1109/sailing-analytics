import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/controllers/recording_controller.dart';
import 'package:sailing_analytics/providers/sensor_providers.dart';
import 'widgets/gps_status.dart';
import 'widgets/heading_display.dart';

class HeadingScreen extends ConsumerWidget {
  const HeadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordingControllerProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /* Consumer(
            builder: (context, ref, _) {
              final mag = ref.watch(rawMagProvider);
              return mag.when(
                data: (m) => Text(
                  'mx:${m.x.toStringAsFixed(1)}  my:${m.y.toStringAsFixed(1)}  mz:${m.z.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.yellow, fontSize: 14),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              );
            },
          ), */
          Align(
            alignment: Alignment.topCenter,
            child: GpsStatus(
              pointsSaved: state.pointsSaved,
              lastAccuracy: state.lastAccuracy,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HeadingDisplay(
                    magHeading: state.lastMagHeading,
                    isRacingview: false,
                  ),
                  Text(
                    'Heading',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 255, 0, 191),
                      fontSize: 58,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
