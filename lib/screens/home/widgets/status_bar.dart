import 'package:flutter/material.dart';
import 'package:sailing_analytics/providers/ui_providers.dart';
import 'package:sailing_analytics/util/color_utils.dart';

class StatusBar extends StatelessWidget {
  final PathMode pathMode;
  final double maxKnots;
  final double minKnotsActual;
  final double maxKnotsActual;

  const StatusBar({
    super.key,
    required this.pathMode,
    required this.maxKnots,
    required this.maxKnotsActual,
    required this.minKnotsActual,
  });

  List<Color> _buildGradient() {
    const steps = 10;
    return switch (pathMode) {
      PathMode.speed || PathMode.dynamicSpeed => List.generate(steps, (i) {
        final knots = maxKnots - (i / (steps - 1)) * (maxKnots - 0);
        return speedToColor(knots, 0, maxKnots);
      }),
      PathMode.heel => List.generate(steps, (i) {
        final heel = 45.0 - (i / (steps - 1)) * 90.0; // +45 to -45 degrees
        return heelToColor(heel, 45.0);
      }),
    };
  }

  List<Widget> _buildLabels() {
    final style = const TextStyle(color: Colors.grey, fontSize: 10);
    return switch (pathMode) {
      PathMode.speed => [
        Text('${maxKnots.toStringAsFixed(1)} kn', style: style),
        Text('${0} kn', style: style),
      ],
      PathMode.dynamicSpeed => [
        Text('${maxKnotsActual.toStringAsFixed(1)} kn', style: style),
        Text('${minKnotsActual.toStringAsFixed(1)} kn', style: style),
      ],
      PathMode.heel => [
        Text('45°', style: style), // starboard (green, top)
        Text('0°', style: style), // neutral (purple, middle)
        Text('45°', style: style), // port (red, bottom)
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 14,
          height: 110,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _buildGradient(),
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(7),
            boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          height: 110,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildLabels(),
          ),
        ),
      ],
    );
  }
}
