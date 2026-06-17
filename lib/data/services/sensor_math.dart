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
double headingFromMag(MagnetometerEvent m, AccelerometerEvent a) {
  // "Oben"-Einheitsvektor aus dem Beschleunigungssensor
  final aMag = sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
  final gx = a.x / aMag;
  final gy = a.y / aMag;
  final gz = a.z / aMag;

  // Magnetometer auf die Horizontalebene projizieren
  final mDotG = m.x * gx + m.y * gy + m.z * gz;
  final hmx = m.x - mDotG * gx;
  final hmy = m.y - mDotG * gy;
  final hmz = m.z - mDotG * gz;

  // Vorwärtsachse des Handys (welche Achse zeigt zum Bug?)
  // ← das musst du herausfinden, siehe unten
  const fwdX = 0.0, fwdY = 0.0, fwdZ = -1.0;

  // Vorwärtsachse ebenfalls auf Horizontalebene projizieren
  final fDotG = fwdX * gx + fwdY * gy + fwdZ * gz;
  final pfx = fwdX - fDotG * gx;
  final pfy = fwdY - fDotG * gy;
  final pfz = fwdZ - fDotG * gz;

  // Ostrichtung: cross(g_up, horiz_mag)
  final ex = gy * hmz - gz * hmy;
  final ey = gz * hmx - gx * hmz;
  final ez = gx * hmy - gy * hmx;

  // Winkel von Nordmagnet zu Bug, im Uhrzeigersinn
  final sinH = pfx * ex + pfy * ey + pfz * ez;
  final cosH = pfx * hmx + pfy * hmy + pfz * hmz;

  final h = atan2(sinH, cosH) * (180 / pi);
  return h < 0 ? h + 360 : h;
}
