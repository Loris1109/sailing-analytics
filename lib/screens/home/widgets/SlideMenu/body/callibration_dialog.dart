import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sailing_analytics/data/services/sensor_service.dart';
import 'package:sailing_analytics/providers/sensor_providers.dart';

class CalibrationDialog extends ConsumerStatefulWidget {
  const CalibrationDialog({super.key});

  @override
  ConsumerState<CalibrationDialog> createState() => _CalibrationDialogState();
}

class _CalibrationDialogState extends ConsumerState<CalibrationDialog> {
  bool _measuring = false;
  int _countdown = 3;
  Timer? _timer;

  void _startMeasurement() {
    final events = <AccelerometerEvent>[];
    StreamSubscription? sub;

    setState(() {
      _measuring = true;
      _countdown = 3;
    });

    sub = SensorService.getAccelerometerStream().listen((e) => events.add(e));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 1) {
        timer.cancel();
        sub?.cancel();
        ref.read(calibrationOffsetProvider.notifier).calibrate(events);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 1,
      child: AlertDialog(
        title: const Text('Kalibrierung'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bringe dein Handy ans Boot und lege es gerade.'),
            const SizedBox(height: 16),
            if (_measuring) ...[
              Text(
                '$_countdown',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Messung läuft...'),
            ],
          ],
        ),
        actions: _measuring
            ? []
            : [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: _startMeasurement,
                  child: const Text('Kalibrieren'),
                ),
              ],
      ),
    );
  }
}
