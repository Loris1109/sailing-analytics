// lib/screens/racing/widgets/heading_display.dart

import 'package:flutter/material.dart';

class HeadingDisplay extends StatelessWidget {
  final double? magHeading;
  final bool? isRacingview;

  const HeadingDisplay({this.magHeading, this.isRacingview, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: magHeading?.toStringAsFixed(0) ?? '--',
                style: TextStyle(
                  color: const Color.fromARGB(255, 255, 0, 191),
                  fontSize: isRacingview == true ? 192 : 256,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -4,
                  height: 0.9,
                ),
              ),
              TextSpan(
                text: ' °',
                style: TextStyle(
                  color: const Color.fromARGB(255, 255, 0, 191),
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
