import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/data/services/sensor_math.dart';
import 'package:sailing_analytics/data/services/sensor_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

// --- Kalibrierung ---
// Gespeichert wird der WINKEL, den das ruhig liegende Handy gemeldet hat
// ("so sieht gerade aus") — nicht der rohe Beschleunigungsvektor.
// Heel/Pitch sind dann einfach: Rohwinkel minus Offset.

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
    final avgPitch =
        events.map(rawPitch).reduce((a, b) => a + b) / events.length;
    state = CalibrationOffset(heel: avgHeel, pitch: avgPitch);
  }
}

final calibrationOffsetProvider =
    NotifierProvider<CalibrationNotifier, CalibrationOffset>(
      CalibrationNotifier.new,
    );

// --- Live-Sensorwerte für die UI ---
// autoDispose: die Sensoren laufen nur, solange ein Widget zuschaut.
// Der RecordingController hört während der Aufnahme selbst auf die
// Service-Streams und hängt nicht an diesen Providern.

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

final headingProvider = StreamProvider.autoDispose<double>((ref) {
  final controller = StreamController<double>();
  AccelerometerEvent? lastAccel;

  final accelSub = SensorService.getAccelerometerStream().listen((a) {
    lastAccel = a;
  });

  final magSub = SensorService.getMagnetometerStream().listen((m) {
    if (lastAccel != null) {
      controller.add(headingFromMag(m, lastAccel!));
    }
  });

  ref.onDispose(() {
    accelSub.cancel();
    magSub.cancel();
    controller.close();
  });

  return controller.stream;
});
final rawMagProvider = StreamProvider.autoDispose<MagnetometerEvent>((ref) {
  return SensorService.getMagnetometerStream();
});
