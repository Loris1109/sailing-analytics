import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volume_listener/volume_listener.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:sailing_analytics/controllers/recording_controller.dart';
import 'speed_screen.dart';
import 'heading_screen.dart';
import 'racing_screen.dart';

class RacingContainerScreen extends ConsumerStatefulWidget {
  const RacingContainerScreen({super.key});

  @override
  ConsumerState<RacingContainerScreen> createState() =>
      _RacingContainerScreenState();
}

class _RacingContainerScreenState extends ConsumerState<RacingContainerScreen> {
  static const _bothButtonWindow = Duration(milliseconds: 500);
  static const _pageCount = 3;

  final _pageController = PageController();
  int _currentPage = 0;

  Timer? _volumeTimer;
  VolumeKey? _pendingKey;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    WakelockPlus.enable();
    VolumeListener.addListener(_onVolumeKey);
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
    VolumeListener.removeListener();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: const [SpeedScreen(), HeadingScreen(), RacingScreen()],
    );
  }
}
