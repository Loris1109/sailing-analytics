import 'package:flutter/material.dart';

Color speedToColor(double knots, double minKnots, double maxKnots) {
  final t = ((knots - minKnots) / (maxKnots - minKnots)).clamp(0.0, 1.0);
  final hue = 240.0 * (1.0 - t);
  return HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
}

Color heelToColor(double heel, double maxHeel) {
  final t = (heel / maxHeel).clamp(-1.0, 1.0);
  const neutral = Color(0xFFCE93D8);
  return t >= 0
      ? Color.lerp(neutral, Colors.green.shade900, t)!
      : Color.lerp(neutral, Colors.red.shade900, -t)!;
}
