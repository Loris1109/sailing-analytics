import 'package:flutter/material.dart';
import 'package:tacktics/data/services/speed_profile.dart';
import 'package:tacktics/util/color_utils.dart';

/// Das Speed-Profil als Balkenband: je Zeitfenster ein Balken von der
/// langsamsten zur schnellsten Fahrt darin, eingefärbt nach dem Mittel.
///
/// Dieselbe Farbskala wie die Karte im Speed-Modus (0 bis Bootsmaximum) —
/// ein grüner Abschnitt im Profil gehört zu einer grünen Spur auf der Karte.
/// Ohne diese Kopplung wären es zwei Bilder derselben Fahrt, die nichts
/// voneinander wissen.
class SpeedProfileChart extends StatelessWidget {
  final SpeedProfile profile;

  /// Obergrenze der FARBskala, nicht der Höhe. Kommt wie bei der Karte vom
  /// Boot, damit beide dasselbe Grün meinen.
  final double maxKnots;

  const SpeedProfileChart({
    super.key,
    required this.profile,
    required this.maxKnots,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _SpeedProfilePainter(profile: profile, maxKnots: maxKnots),
    );
  }
}

class _SpeedProfilePainter extends CustomPainter {
  final SpeedProfile profile;
  final double maxKnots;

  _SpeedProfilePainter({required this.profile, required this.maxKnots});

  /// Kleinste sichtbare Balkenhöhe. Bei konstanter Fahrt fallen min und max
  /// zusammen — ohne diesen Boden verschwände die Anfahrt, also ausgerechnet
  /// der Teil, den man wegschneiden will.
  static const _minBarHeight = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final buckets = profile.buckets;
    if (buckets.isEmpty || size.width <= 0 || size.height <= 0) return;

    // Höhenachse auf den schnellsten Punkt der Session: das Profil füllt
    // damit immer die ganze Leiste. Der Boden fängt eine Session ab, in der
    // das Boot nie in Fahrt kam — sonst teilte der Balken durch null.
    final scaleMax = profile.maxSog > 0.1 ? profile.maxSog : 1.0;
    final barWidth = size.width / buckets.length;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < buckets.length; i++) {
      final bucket = buckets[i];
      if (bucket == null) continue; // Lücke bleibt Lücke

      final top = size.height * (1 - bucket.max / scaleMax);
      final bottom = size.height * (1 - bucket.min / scaleMax);
      final height = (bottom - top).clamp(_minBarHeight, size.height);

      final left = i * barWidth;
      paint.color = speedToColor(bucket.avg, 0, maxKnots);
      canvas.drawRect(
        // Eine halbe Pixelbreite Überlappung nach rechts: aneinander
        // stoßende Rechtecke lassen sonst je nach Gerätedichte helle Nähte
        // stehen, und das Band sähe gestreift aus.
        Rect.fromLTWH(
          left,
          top.clamp(0.0, size.height - height),
          barWidth + 0.5,
          height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpeedProfilePainter old) =>
      !identical(old.profile, profile) || old.maxKnots != maxKnots;
}
