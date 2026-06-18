import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:sailing_analytics/data/services/sensor_math.dart';
import 'package:sailing_analytics/data/services/sensor_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

class CalibrationOffset {
  final double heel;
  final double pitch;

  const CalibrationOffset({this.heel = 0, this.pitch = 0});
}

class CalibrationNotifier extends Notifier<CalibrationOffset> {
  @override
  CalibrationOffset build() => const CalibrationOffset();

  void calibrate(List<AccelerometerEvent> events) {
    if (events.isEmpty) return;
    final avgHeel = events.map(rawHeel).reduce((a, b) => a + b) / events.length;
    final avgPitch = events.map(rawPitch).reduce((a, b) => a + b) / events.length;
    state = CalibrationOffset(heel: avgHeel, pitch: avgPitch);
  }
}

final calibrationOffsetProvider =
    NotifierProvider<CalibrationNotifier, CalibrationOffset>(
      CalibrationNotifier.new,
    );

// Heading: Rotation Sensor (tilt-kompensiert, Gyroskop-geglättet)
final orientationProvider = StreamProvider.autoDispose<OrientationEvent>((ref) {
  return SensorService.getOrientationStream();
});

final headingProvider = Provider.autoDispose<double>((ref) {
  final az = ref.watch(orientationProvider).value?.eulerAngles.azimuth ?? 0.0;
  return az < 0 ? az * (180 / pi) + 360 : az * (180 / pi);
});

// Heel + Pitch: sensors_plus Accelerometer (keine Euler-Kopplungsprobleme)
final heelProvider = StreamProvider.autoDispose<double>((ref) {
  final offset = ref.watch(calibrationOffsetProvider);
  return SensorService.getAccelerometerStream().map(
    (e) => rawHeel(e) - offset.heel,
  );
});

final pitchProvider = StreamProvider.autoDispose<double>((ref) {
  final offset = ref.watch(calibrationOffsetProvider);
  return SensorService.getAccelerometerStream().map(
    (e) => rawPitch(e) - offset.pitch,
  );
});
