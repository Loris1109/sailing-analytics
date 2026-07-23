import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

// Mounting: landscape, volume buttons up → x-axis points toward sky
// x=durch die Volumetasen, y=zur kamera, z=zum user
double rawHeel(AccelerometerEvent e) => atan2(e.y, e.x) * (180 / pi);
double rawPitch(AccelerometerEvent e) => atan2(e.x, e.z) * (180 / pi);
