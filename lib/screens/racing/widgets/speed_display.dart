// lib/screens/racing/widgets/speed_gauge.dart

import 'package:flutter/material.dart';

class SpeedDisplay extends StatelessWidget {
  final double? sog;
  final bool? isRacingview;

  const SpeedDisplay({this.sog, this.isRacingview, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                // show -- until first GPS fix arrives
                text: sog?.toStringAsFixed(2) ?? '--',
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 242, 255),
                  fontSize: isRacingview == true ? 160 : 256,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -4,
                  height: 0.9,
                ),
              ),
              TextSpan(
                text: ' kn',
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 242, 255),
                  fontSize: isRacingview == true ? 24 : 32,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
