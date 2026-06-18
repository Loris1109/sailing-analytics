import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:latlong2/latlong.dart';
import 'package:sailing_analytics/providers/sensor_providers.dart';
import '../data/entities/gps_point.dart';
import '../data/repositories/session_repository.dart';
import '../data/services/gps_service.dart';
import '../data/services/sensor_math.dart';
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
  StreamSubscription? _accelSub;
  StreamSubscription? _orientationSub;

  double _heel = 0;
  double _pitch = 0;
  double _magHeading = 0;

  @override
  RecordingState build() => const RecordingState();

  Future<void> startRecording({
    required String name,
    required String boatId,
  }) async {
    // Doppelstart würde die alten Subscriptions unkündbar überschreiben
    if (state.isRecording) return;

    final hasPermission = await GpsService.requestPermission();
    if (!hasPermission) {
      state = state.copyWith(permissionDenied: true);
      return;
    }

    final repo = ref.read(sessionRepositoryProvider);
    final sessionId = await repo.createSession(name: name, boatId: boatId);

    _gpsSub = GpsService.getStream().listen(
      (pos) => _onPosition(pos, sessionId, repo),
    );

    // Sensoren kontinuierlich mithören — _onPosition sampelt beim Speichern
    // den jeweils letzten Wert. Kalibrierung ändert sich nur im Dialog,
    // einmal lesen beim Start reicht.
    final calibration = ref.read(calibrationOffsetProvider);
    _accelSub = SensorService.getAccelerometerStream().listen((e) {
      _heel = rawHeel(e) - calibration.heel;
      _pitch = rawPitch(e) - calibration.pitch;
    });
    _orientationSub = SensorService.getOrientationStream().listen((e) {
      final az = e.eulerAngles.azimuth;
      _magHeading = az < 0 ? az * (180 / pi) + 360 : az * (180 / pi);
    });

    state = RecordingState(isRecording: true, activeSessionId: sessionId);
  }

  DateTime? _lastPositionTime;

  // Referenz für den Sprung-Filter: der letzte AKZEPTIERTE Punkt —
  // nicht der letzte empfangene, sonst validieren Ausreißer einander
  LatLng? _lastAcceptedPos;
  DateTime? _lastAcceptedTime;

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
      'GPS point received — gap: ${gap != null ? '${gap}ms' : 'first point'}, '
      'accuracy: ${pos.accuracy.toStringAsFixed(1)}m',
    );
    _lastPositionTime = now;

    // ── GPS-Korrekturen ────────────────────────────────────────────
    // Alle Filter, die Roh-Fixe verwerfen oder korrigieren, leben hier.
    // Verworfene Punkte werden geloggt, damit die Schwellen mit echten
    // Wasserdaten kalibriert werden können.

    // Stufe 1: ungenaue Fixe verwerfen
    if (pos.accuracy > 20) {
      dev.log(
        'Point rejected — accuracy ${pos.accuracy.toStringAsFixed(1)}m > 20m',
      );
      return;
    }

    // Stufe 2: physikalisch unmögliche Sprünge verwerfen
    final newPos = LatLng(pos.latitude, pos.longitude);
    if (_lastAcceptedPos != null && _lastAcceptedTime != null) {
      final meters = const Distance()(_lastAcceptedPos!, newPos);
      final seconds = now.difference(_lastAcceptedTime!).inMilliseconds / 1000;
      if (seconds > 0) {
        final impliedKnots = (meters / seconds) * 1.94384;
        if (impliedKnots > 40) {
          dev.log(
            'Point rejected — implied speed ${impliedKnots.toStringAsFixed(1)}kn '
            '(${meters.toStringAsFixed(1)}m in ${seconds.toStringAsFixed(1)}s)',
          );
          return;
        }
      }
    }
    _lastAcceptedPos = newPos;
    _lastAcceptedTime = now;

    // Stufe 3 (geplant): Stillstands-Filter — Punkt verwerfen, wenn
    // pos.speed < 0.3 m/s und meters < pos.accuracy. Erst nach Auswertung
    // der Wassertest-Logs entscheiden (Trade-off: Lücken bei Flaute/Kenterung).

    // Stufe 4 (geplant): Glättung (gleitender Mittelwert / Kalman),
    // falls Stufe 1+2 auf dem Wasser nicht reichen.
    // ───────────────────────────────────────────────────────────────

    await repo.savePoint(
      GpsPointEntity(
        sessionId: sessionId,
        timestamp: now,
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
    await _accelSub?.cancel();
    await _orientationSub?.cancel();
    _gpsSub = null;
    _accelSub = null;
    _orientationSub = null;

    // Filter-Referenzen zurücksetzen — die nächste Session darf nicht
    // gegen den letzten Punkt dieser Session vergleichen
    _lastAcceptedPos = null;
    _lastAcceptedTime = null;
    _lastPositionTime = null;

    final finishedId = state.activeSessionId;
    if (finishedId != null) {
      final repo = ref.read(sessionRepositoryProvider);
      await repo.completeSession(finishedId);
    }

    state = RecordingState(completedSessionId: finishedId);
  }
}
