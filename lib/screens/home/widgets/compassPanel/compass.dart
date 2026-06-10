import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/providers/ui_providers.dart';

class Compass extends ConsumerWidget {
  const Compass({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windDirection = ref.watch(windDirectionProvider);

    return GestureDetector(
      onPanUpdate: (details) {
        const size = 80.0;
        final center = Offset(size / 2, size / 2);
        final dx = details.localPosition.dx - center.dx;
        final dy = details.localPosition.dy - center.dy;
        double degrees = atan2(dx, -dy) * 180 / pi;
        if (degrees < 0) degrees += 360;
        ref.read(windDirectionProvider.notifier).set(degrees);
      },
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Hintergrund-Kreis
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEEEEEE),
                boxShadow: const [
                  BoxShadow(blurRadius: 8, color: Colors.black26),
                ],
              ),
            ),

            // Nord (oben) – vertikal
            Positioned(
              top: -4,
              left: 39,
              child: Container(
                width: 2,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.black,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
            ),
            // Süd (unten) – vertikal
            Positioned(
              bottom: -4,
              left: 39,
              child: Container(
                width: 2,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.black,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
            ),
            // West (links) – horizontal
            Positioned(
              left: -4,
              top: 39,
              child: Container(
                width: 14,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.black,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
            ),
            // Ost (rechts) – horizontal
            Positioned(
              right: -4,
              top: 39,
              child: Container(
                width: 14,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.black,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
            ),

            // Rotierende Nadel
            Transform.rotate(
              angle: windDirection * pi / 180,
              child: Transform.translate(
                offset: Offset(0, -40), // Radius = 80px / 2 = 40px nach oben
                child: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.black,
                  size: 32,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black26)],
                ),
              ),
            ),

            // Grad-Text
            Text(
              '${windDirection.round()}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w500,
                letterSpacing: -3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
