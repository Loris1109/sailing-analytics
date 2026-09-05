import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:sailing_analytics/controllers/recording_controller.dart';
import 'speed_screen.dart';
import 'heading_screen.dart';
import 'racing_screen.dart';

const platform = MethodChannel('com.example.sailing_analytics/volume_buttons');

enum VolumeKey { up, down }

class RacingContainerScreen extends ConsumerStatefulWidget {
  const RacingContainerScreen({super.key});

  @override
  ConsumerState<RacingContainerScreen> createState() =>
      _RacingContainerScreenState();
}

class _RacingContainerScreenState extends ConsumerState<RacingContainerScreen> {
  static const _bothButtonWindow = Duration(milliseconds: 750);
  static const _pageCount = 3;

  final _pageController = PageController();
  int _currentPage = 0;

  Timer? _volumeTimer;
  VolumeKey? _pendingKey;

  bool _showHint = true;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    WakelockPlus.enable();
    _setupVolumeButtonListener();
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  void _setupVolumeButtonListener() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'volumeKey') {
        final key = call.arguments as String;
        _onVolumeKey(key == 'up' ? VolumeKey.up : VolumeKey.down);
      }
    });
  }

  void _onVolumeKey(VolumeKey key) {
    if (_pendingKey != null && _pendingKey != key) {
      // Different key pressed while one is pending → both buttons → stop
      _volumeTimer?.cancel();
      _volumeTimer = null;
      _pendingKey = null;
      _stopSession();
      return;
    }

    _volumeTimer?.cancel();
    _pendingKey = key;
    _volumeTimer = Timer(_bothButtonWindow, () {
      final k = _pendingKey;
      _pendingKey = null;
      _volumeTimer = null;
      if (k == VolumeKey.down) {
        _goToPage((_currentPage + 1) % _pageCount);
      } else if (k == VolumeKey.up) {
        _goToPage((_currentPage + _pageCount - 1) % _pageCount);
      }
    });
  }

  void _goToPage(int page) {
    setState(() => _currentPage = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _stopSession() async {
    final controller = ref.read(recordingControllerProvider.notifier);
    await controller.stopRecording();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _volumeTimer?.cancel();
    _hintTimer?.cancel();
    platform.setMethodCallHandler(null);
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [SpeedScreen(), HeadingScreen(), RacingScreen()],
        ),
        AnimatedOpacity(
          opacity: _showHint ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: const Text(
                    '↑ / ↓  Screen wechseln  ·  Beide Tasten = Session beenden',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
