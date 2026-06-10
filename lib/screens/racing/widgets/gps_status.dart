// lib/screens/racing/widgets/gps_status.dart

import 'package:flutter/material.dart';

class GpsStatus extends StatelessWidget {
  final int pointsSaved;
  final double? lastAccuracy;

  const GpsStatus({required this.pointsSaved, this.lastAccuracy, super.key});

  @override
  Widget build(BuildContext context) {
    // green under 6m, orange under 10m, red above
    final color = lastAccuracy == null
        ? Colors.grey
        : lastAccuracy! <= 6
        ? Colors.green
        : lastAccuracy! <= 10
        ? Colors.orange
        : Colors.red;

    final label = lastAccuracy == null
        ? 'Searching...'
        : lastAccuracy! <= 6
        ? 'GPS locked'
        : lastAccuracy! <= 10
        ? 'GPS warming up'
        : 'GPS weak';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // accuracy dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
          const SizedBox(width: 16),
          // points counter — reassures user data is saving
          Text(
            '$pointsSaved pts saved',
            style: TextStyle(color: Colors.grey[700], fontSize: 10),
          ),
        ],
      ),
    );
  }
}
