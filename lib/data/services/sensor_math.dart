import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

// Mounting: landscape, volume buttons up → x-axis points toward sky
double rawHeel(AccelerometerEvent e) => atan2(e.z, e.x) * (180 / pi);
double rawPitch(AccelerometerEvent e) => atan2(e.y, e.x) * (180 / pi);
