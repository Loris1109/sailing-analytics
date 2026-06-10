import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../data/entities/gps_point.dart';
import '../data/repositories/session_repository.dart';
import '../data/services/gps_service.dart';
import '../data/services/sensor_service.dart';
import '../providers/repository_providers.dart';

class RecordingState {
  final bool isRecording;
  final String? activeSessionId;
  final String? completedSessionId;
  final int pointsSaved;
  final double? lastSog;
  final double? lastCog;
  final double? lastMagHeading;
  final double? lastAccuracy;
  final bool permissionDenied;

  const RecordingState({
    this.isRecording = false,
    this.activeSessionId,
    this.completedSessionId,
    this.pointsSaved = 0,
    this.lastSog,
    this.lastCog,
    this.lastMagHeading,
    this.lastAccuracy,
    this.permissionDenied = false,
  });

  RecordingState copyWith({
    bool? isRecording,
    String? activeSessionId,
    String? completedSessionId,
    int? pointsSaved,
    double? lastSog,
    double? lastCog,
    double? lastMagHeading,
    double? lastAccuracy,
    bool? permissionDenied,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      completedSessionId: completedSessionId ?? this.completedSessionId,
      pointsSaved: pointsSaved ?? this.pointsSaved,
      lastSog: lastSog ?? this.lastSog,
      lastCog: lastCog ?? this.lastCog,
      lastMagHeading: lastMagHeading ?? this.lastMagHeading,
      lastAccuracy: lastAccuracy ?? this.lastAccuracy,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }
}

final recordingControllerProvider =
    NotifierProvider<RecordingController, RecordingState>(
      RecordingController.new,
    );

class RecordingController extends Notifier<RecordingState> {
  StreamSubscription<Position>? _gpsSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  double _heel = 0;
  double _pitch = 0;
  double _magHeading = 0;

  @override
  RecordingState build() => const RecordingState();

  Future<void> startRecording({
    required String name,
    required String boatId,
  }) async {
    final hasPermission = await GpsService.requestPermission();
    if (!hasPermission) {
      state = state.copyWith(permissionDenied: true);
      return;
    }

    final repo = ref.read(sessionRepositoryProvider);
    final sessionId = await repo.createSession(
      name: name,
      boatId: boatId,
    );

    _gyroSub = SensorService.getGyroscopeStream().listen((e) {
      _heel = _calculateHeel(e);
      _pitch = _calculatePitch(e);
    });

    _magSub = SensorService.getMagnetometerStream().listen((e) {
      _magHeading = _calculateHeading(e);
    });

    _gpsSub = GpsService.getStream().listen(
      (pos) => _onPosition(pos, sessionId, repo),
    );

    state = RecordingState(isRecording: true, activeSessionId: sessionId);
  }

  DateTime? _lastPositionTime;

  Future<void> _onPosition(
    Position pos,
    String sessionId,
    SessionRepository repo,
  ) async {
    final now = DateTime.now();
    final gap = _lastPositionTime != null
        ? now.difference(_lastPositionTime!).inMilliseconds
        : null;
    dev.log(
      'GPS point received — gap: ${gap != null ? '${gap}ms' : 'first point'}',
    );
    _lastPositionTime = now;

    await repo.savePoint(
      GpsPointEntity(
        sessionId: sessionId,
        timestamp: DateTime.now(),
        lat: pos.latitude,
        lon: pos.longitude,
        sog: pos.speed * 1.94384, // m/s → knots
        cog: pos.heading % 360,
        heel: _heel,
        pitch: _pitch,
        magHeading: _magHeading,
        accuracy: pos.accuracy,
      ),
    );
    state = state.copyWith(
      pointsSaved: state.pointsSaved + 1,
      lastSog: pos.speed * 1.94384,
      lastCog: pos.heading % 360,
      lastMagHeading: _magHeading,
      lastAccuracy: pos.accuracy,
    );
  }

  Future<void> stopRecording() async {
    await _gpsSub?.cancel();
    await _gyroSub?.cancel();
    await _magSub?.cancel();
    _gpsSub = null;
    _gyroSub = null;
    _magSub = null;

    final finishedId = state.activeSessionId;
    if (finishedId != null) {
      final repo = ref.read(sessionRepositoryProvider);
      await repo.completeSession(finishedId);
    }

    state = RecordingState(completedSessionId: finishedId);
  }

  //Heel on Phone in Landscape
  double _calculateHeel(GyroscopeEvent e) => e.z;
  //Pitch on Phone in Landscape
  double _calculatePitch(GyroscopeEvent e) => e.y;

  double _calculateHeading(MagnetometerEvent e) {
    double h = atan2(e.y, e.x) * (180 / pi);
    return h < 0 ? h + 360 : h;
  }
}
