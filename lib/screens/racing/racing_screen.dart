import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/controllers/recording_controller.dart';
import 'widgets/gps_status.dart';
import 'widgets/heading_display.dart';
import 'widgets/speed_display.dart';

class RacingScreen extends ConsumerWidget {
  const RacingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordingControllerProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
                    isRacingview: true,
                  ),
                  SpeedDisplay(sog: state.lastSog, isRacingview: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
