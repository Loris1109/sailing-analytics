import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../data/services/gps_service.dart';

class GpsTestScreen extends StatefulWidget {
  const GpsTestScreen({super.key});

  @override
  State<GpsTestScreen> createState() => _GpsTestScreenState();
}

class _GpsTestScreenState extends State<GpsTestScreen> {
  Position? _lastPosition;
  StreamSubscription<Position>? _sub;
  DateTime? _lastFixTime;
  int? _lastIntervalMs;

  @override
  void initState() {
    super.initState();
    _startGps();
  }

  Future<void> _startGps() async {
    final ready = await GpsService.requestPermission();
    if (!ready) return;

    _sub = GpsService.getStream().listen((Position pos) {
      final now = DateTime.now();
      final intervalMs = _lastFixTime != null
          ? now.difference(_lastFixTime!).inMilliseconds
          : null;
      _lastFixTime = now;

      setState(() {
        _lastPosition = pos;
        _lastIntervalMs = intervalMs;
      });

      debugPrint('─────────────────────────');
      debugPrint('Lat:      ${pos.latitude.toStringAsFixed(6)}');
      debugPrint('Lon:      ${pos.longitude.toStringAsFixed(6)}');
      debugPrint('SOG:      ${(pos.speed * 1.94384).toStringAsFixed(2)} kn');
      debugPrint('COG:      ${pos.heading.toStringAsFixed(1)}°');
      debugPrint('Accuracy: ${pos.accuracy.toStringAsFixed(1)} m');
      debugPrint(
        'Interval: ${intervalMs != null ? '${intervalMs}ms' : 'first fix'}',
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel(); // always cancel streams when leaving screen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = _lastPosition;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: pos == null
            ? const CircularProgressIndicator(color: Colors.green)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatRow(
                    'SOG',
                    '${(pos.speed * 1.94384).toStringAsFixed(2)} kn',
                    Colors.green,
                  ),
                  _StatRow(
                    'COG',
                    '${pos.heading.toStringAsFixed(1)}°',
                    Colors.amber,
                  ),
                  _StatRow(
                    'Lat',
                    pos.latitude.toStringAsFixed(6),
                    Colors.white70,
                  ),
                  _StatRow(
                    'Lon',
                    pos.longitude.toStringAsFixed(6),
                    Colors.white70,
                  ),
                  _StatRow(
                    'Accuracy',
                    '${pos.accuracy.toStringAsFixed(1)} m',
                    Colors.white70,
                  ),
                  _StatRow(
                    'Interval',
                    _lastIntervalMs != null ? '${_lastIntervalMs}ms' : '—',
                    _lastIntervalMs != null && _lastIntervalMs! <= 250
                        ? Colors.green
                        : Colors.orange,
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
