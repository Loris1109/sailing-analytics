// lib/data/services/sensor_math.dart
// Pure angle math from sensor events — shared by the sensor providers (UI)
// and the RecordingController. Calibration is applied AFTER these raw
// angles, in angle space: heel = rawHeel(e) - offset.heel

import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

/// Roh-Krängung in Grad aus dem Gravitationsvektor — vor Kalibrierung
double rawHeel(AccelerometerEvent e) => atan2(e.z, e.y) * (180 / pi);

/// Roh-Neigung in Grad — vor Kalibrierung
double rawPitch(AccelerometerEvent e) => atan2(e.y, e.x) * (180 / pi);

/// Magnetkompass-Kurs in Grad, 0..360
double headingFromMag(MagnetometerEvent e) {
  final h = atan2(e.y, e.x) * (180 / pi);
  return h < 0 ? h + 360 : h;
}
