// lib/data/services/performance_calc.dart
// TWA/VMG are derived data: computed on the fly from COG/SOG + wind direction,
// never stored — the user can correct the wind afterwards and everything
// recalculates automatically.

import 'dart:math';

/// True Wind Angle in degrees, normalized to -180..+180.
/// Positive = wind from starboard, negative = wind from port.
/// [windFromDeg] is where the wind comes FROM (compass convention).
double twa(double cogDeg, double windFromDeg) {
  // +540 keeps the value positive before %, result lands in -180..+180
  return (windFromDeg - cogDeg + 540) % 360 - 180;
}

/// Velocity Made Good in knots.
/// Positive = sailing towards the wind (upwind), negative = away from it.
double vmg(double sogKn, double twaDeg) {
  return sogKn * cos(twaDeg * pi / 180);
}
