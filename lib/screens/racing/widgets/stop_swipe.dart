// lib/screens/racing/widgets/stop_swipe.dart

import 'package:flutter/material.dart';

class StopSwipe extends StatelessWidget {
  const StopSwipe({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Icon(Icons.keyboard_arrow_up, color: Colors.grey[700], size: 10),
          Text(
            'swipe up to end session',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 10,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
