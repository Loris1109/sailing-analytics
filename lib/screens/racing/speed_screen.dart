import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/controllers/recording_controller.dart';
import 'package:sailing_analytics/providers/sensor_providers.dart';
import 'package:sailing_analytics/screens/racing/widgets/heel_indicator.dart';
import 'widgets/gps_status.dart';
import 'widgets/speed_display.dart';

class SpeedScreen extends ConsumerWidget {
  const SpeedScreen({super.key});

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
                  SpeedDisplay(sog: state.lastSog, isRacingview: false),
                  Text(
                    'Speed',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 0, 242, 255),
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
