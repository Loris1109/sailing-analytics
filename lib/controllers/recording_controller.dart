import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:latlong2/latlong.dart';
import 'package:tacktics/data/repositories/range_measurements_repository.dart';
import 'package:tacktics/data/services/ble_service.dart';
import 'package:tacktics/providers/ble_state_provider.dart';
import 'package:tacktics/providers/sensor_providers.dart';
import 'package:uuid/uuid.dart';
import '../data/entities/gps_point.dart';
import '../data/entities/range_measurements.dart';
import '../data/repositories/session_repository.dart';
import '../data/services/gps_service.dart';
import '../data/services/sensor_math.dart';
import '../data/services/sensor_service.dart';
import '../providers/repository_providers.dart';

/// Warum ein Startversuch nicht zu einer Aufzeichnung geführt hat.
///
/// Es gibt bewusst keinen BLE-Fall: Bluetooth kann den Start nicht mehr
/// verhindern, siehe RecordingController._startBleIfPossible.
enum StartFailure {
  /// Standortdienst im Gerät ausgeschaltet.
  locationServiceOff,

  /// Freigabe abgelehnt — beim nächsten Versuch wird wieder gefragt.
  locationDenied,

  /// Dauerhaft abgelehnt. Nur noch über die Systemeinstellungen zu lösen.
  locationDeniedForever,

  /// Es läuft bereits eine Aufzeichnung.
  alreadyRecording,
}

class RecordingState {
  final bool isRecording;
  final String? activeSessionId;
  final String? completedSessionId;
  final int pointsSaved;
  final double? lastSog;
  final double? lastCog;
  final double? lastMagHeading;
  final double? lastAccuracy;

  const RecordingState({
    this.isRecording = false,
    this.activeSessionId,
    this.completedSessionId,
    this.pointsSaved = 0,
    this.lastSog,
    this.lastCog,
    this.lastMagHeading,
    this.lastAccuracy,
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
    // copyWith kann ein nullbares Feld sonst nie zurück auf null setzen
    bool clearCompletedSessionId = false,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      completedSessionId: clearCompletedSessionId
          ? null
          : (completedSessionId ?? this.completedSessionId),
      pointsSaved: pointsSaved ?? this.pointsSaved,
      lastSog: lastSog ?? this.lastSog,
      lastCog: lastCog ?? this.lastCog,
      lastMagHeading: lastMagHeading ?? this.lastMagHeading,
      lastAccuracy: lastAccuracy ?? this.lastAccuracy,
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

  // Advertisements, die älter als das hier sind, gelten als veraltet und
  // werden nicht mehr mit einem neuen GPS-Punkt verknüpft
  static const _maxAdvertisementAge = Duration(seconds: 1);

  @override
  RecordingState build() => const RecordingState();

  /// Quittiert die zuletzt aufgezeichnete Session.
  ///
  /// Der Auto-Select im HomeScreen soll genau einmal greifen. Ohne das
  /// Zurücksetzen selektiert ihn jede spätere Änderung an der Session-Tabelle
  /// erneut — Umbenennen, Wind setzen, eine andere Session löschen — und man
  /// käme nie wieder in den Zustand "nichts ausgewählt".
  void consumeCompletedSession() {
    state = state.copyWith(clearCompletedSessionId: true);
  }

  /// Startet eine Aufzeichnung. Gibt `null` zurück, wenn sie läuft — sonst
  /// den Grund, aus dem sie es nicht tut.
  ///
  /// Genau EINE Sache darf den Start verhindern: der Standort. Ohne ihn gibt
  /// es nichts aufzuzeichnen. Alles andere — Bluetooth, Benachrichtigungen,
  /// ein inzwischen gelöschtes Boot — ist Zusatzausrüstung und degradiert,
  /// statt abzubrechen. Und jeder Abbruch, der doch passiert, wird
  /// zurückgemeldet: ein stilles `return` hat den Aufrufer vorher trotzdem
  /// zum Racing-Screen weiterziehen lassen.
  Future<StartFailure?> startRecording({
    required String name,
    required String boatId,
  }) async {
    dev.log('🎬 RECORDING START REQUESTED: $name');
    if (state.isRecording) {
      dev.log('⚠️ Recording already in progress, ignoring');
      return StartFailure.alreadyRecording;
    }

    final readiness = await GpsService.ensureReady();
    if (readiness != LocationReadiness.ready) {
      dev.log('❌ Standort nicht verfügbar: $readiness');
      return switch (readiness) {
        LocationReadiness.serviceDisabled => StartFailure.locationServiceOff,
        LocationReadiness.deniedForever => StartFailure.locationDeniedForever,
        _ => StartFailure.locationDenied,
      };
    }
    dev.log('✅ GPS permission granted');

    // Gleich hinterher, solange der Nutzer ohnehin bei den Dialogen ist.
    // Blockiert bewusst nicht — siehe ensureNotificationPermission.
    await GpsService.ensureNotificationPermission();

    final rmRepo = ref.read(rangeMeasurementRepositoryProvider);
    final sessionRepo = ref.read(sessionRepositoryProvider);
    final sessionId = await sessionRepo.createSession(
      name: name,
      boatId: boatId,
    );
    dev.log('✅ Session created: $sessionId');

    // Ohne `!`: das Boot kann zwischen der Prüfung im Aufrufer und hier
    // gelöscht worden sein. Die Nummer braucht nur das BLE-Advertising —
    // fehlt sie, wird eben nicht gesendet, aufgezeichnet wird trotzdem.
    final activeBoat = await ref.read(boatRepositoryProvider).getActiveBoat();
    dev.log('✅ Active boat: ${activeBoat?.sailNumber}');

    await _startBleIfPossible(activeBoat?.sailNumber);

    // GPS: Start listening
    _gpsSub = GpsService.getStream().listen(
      (pos) => _onPosition(pos, sessionId, sessionRepo, rmRepo),
    );
    dev.log('✅ GPS Stream subscribed');

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

    dev.log('✅ Recording started successfully');
    state = RecordingState(isRecording: true, activeSessionId: sessionId);
    return null;
  }

  /// Startet Advertising und Scan, wenn es geht — und schweigt, wenn nicht.
  ///
  /// Bluetooth trägt bei Tacktics das Peer-Ranging zu anderen Booten. Das ist
  /// eine Zusatzfunktion; eine Regatta ohne sie aufzuzeichnen ist allemal
  /// besser, als sie gar nicht aufzuzeichnen. Vorher brach ein abgelehnter
  /// Dialog den ganzen Start ab.
  ///
  /// Der try/catch ist nicht vorsorglich: `BleService.requestPermission` ruft
  /// `FlutterBluePlus.turnOn()` auf, und das WIRFT, wenn der Nutzer den
  /// System-Dialog ablehnt. Ungefangen riss die Exception den Start mit.
  Future<void> _startBleIfPossible(String? sailNumber) async {
    try {
      if (!await BleService.requestPermission()) {
        dev.log('ℹ️ BLE nicht freigegeben — Aufzeichnung läuft ohne');
        return;
      }
      final ble = ref.read(bleStateProvider.notifier);
      if (sailNumber != null) {
        await ble.startAdvertising(sailNumber);
        dev.log('✅ BLE Advertising started');
      }
      await ble.startScanning();
      dev.log('✅ BLE Scan subscribed');
    } catch (e) {
      dev.log('ℹ️ BLE nicht verfügbar, Aufzeichnung läuft ohne: $e');
    }
  }

  DateTime? _lastPositionTime;

  // Referenz für den Sprung-Filter: der letzte AKZEPTIERTE Punkt —
  // nicht der letzte empfangene, sonst validieren Ausreißer einander
  LatLng? _lastAcceptedPos;
  DateTime? _lastAcceptedTime;

  // Letzter Kurs, den die Plattform WIRKLICH gemeldet hat — siehe _cogOf.
  double? _lastValidCog;

  /// Kurs über Grund, oder der letzte echte, wenn dieser Fix keinen hat.
  ///
  /// `pos.heading` ist KEIN Kompasskurs, sondern der aus der Bewegung
  /// abgeleitete Kurs über Grund. Meldet die Plattform keinen — Gerät steht,
  /// Fix ohne Bearing, Position vom Netzwerk statt vom GPS — liefert
  /// geolocator 0.0 als Platzhalter, und 0.0 ist von einem echten Nordkurs
  /// nicht zu unterscheiden. `hasHeading` ist das einzige, was die beiden
  /// trennt.
  ///
  /// Ungeprüft übernommen schlug jeder solche Fix in der Auswertung als
  /// Kurssprung auf Nord durch und damit als Wende, die nie stattgefunden hat.
  /// Den letzten echten Kurs zu halten ist die ehrlichere Annahme: ein Boot
  /// behält seinen Kurs, wenn das GPS kurz nichts dazu sagt.
  double _cogOf(Position pos) {
    if (pos.hasHeading) _lastValidCog = pos.heading % 360;
    return _lastValidCog ?? 0;
  }

  Future<void> _onPosition(
    Position pos,
    String sessionId,
    SessionRepository sessionRepo,
    RangeMeasurementRepository rmRepo,
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

    // RSSI-Puffer bei JEDEM Fix leeren, auch bei einem gleich verworfenen —
    // sonst sammelt der Puffer über die Verwurfs-Strecke hinweg weiter und
    // der nächste Median mittelt über mehrere Sekunden Bootsbewegung
    final medians = ref.read(bleStateProvider.notifier).drainMedianRssi();

    // ── GPS-Korrektionen ────────────────────────────────────────────
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

    // Einmal auswerten: _cogOf schreibt _lastValidCog fort, zwei Aufrufe pro
    // Fix wären zwar folgenlos, aber irreführend.
    final cog = _cogOf(pos);

    final gpsPointId = await sessionRepo.savePoint(
      GpsPointEntity(
        id: const Uuid().v4(),
        sessionId: sessionId,
        timestamp: now,
        lat: pos.latitude,
        lon: pos.longitude,
        sog: pos.speed * 1.94384, // m/s → knots
        cog: cog,
        heel: _heel,
        pitch: _pitch,
        magHeading: _magHeading,
        accuracy: pos.accuracy,
      ),
    );

    // BLE-Peers mit diesem GPS-Punkt verknüpfen — nur wenn ihr letztes
    // Advertisement noch aktuell ist, sonst würde eine veraltete RSSI-Messung
    // fälschlich als "jetzt gemessen" markiert
    final lastAdvertisements = ref.read(bleStateProvider).lastAdvertisements;
    dev.log('📊 Processing ${lastAdvertisements.length} BLE advertisements for GPS point ${gpsPointId.substring(0, 8)}...');

    for (final ad in lastAdvertisements.values) {
      final age = now.difference(ad.timestamp);
      if (age > _maxAdvertisementAge) {
        dev.log('⏭️ Skipping stale ad from ${ad.peerId} (age: ${age.inMilliseconds}ms > ${_maxAdvertisementAge.inMilliseconds}ms)');
        continue;
      }
      // Median über alle Pakete seit dem letzten Fix; Fallback auf den
      // Rohwert, falls dieses Boot seit dem letzten Leeren nichts gesendet hat
      final rssi = medians[ad.peerId] ?? ad.rssi;
      dev.log('💾 Saving RSSI: ${ad.peerId} = ${rssi}dBm for GPS point ${gpsPointId.substring(0, 8)}...');
      await rmRepo.insertRangeMeasurement(
        RangeMeasurementEntity(
          id: const Uuid().v4(),
          sessionId: sessionId,
          gpsPointId: gpsPointId,
          peerId: ad.peerId,
          tech: 'ble',
          rssi: rssi,
          timestamp: now,
        ),
      );
    }

    state = state.copyWith(
      pointsSaved: state.pointsSaved + 1,
      lastSog: pos.speed * 1.94384,
      lastCog: cog,
      lastMagHeading: _magHeading,
      lastAccuracy: pos.accuracy,
    );
  }

  Future<void> stopRecording() async {
    dev.log('⏹️ RECORDING STOP REQUESTED');
    await _gpsSub?.cancel();
    await _accelSub?.cancel();
    await _orientationSub?.cancel();
    _gpsSub = null;
    _accelSub = null;
    _orientationSub = null;
    dev.log('✅ All subscriptions cancelled');

    // BLE: Stop. Gefangen wie beim Start — lief die Aufzeichnung ohne
    // Bluetooth, gibt es hier nichts zu stoppen, und ein Fehler beim
    // Aufräumen darf die Session nicht unbeendet zurücklassen.
    try {
      final bleNotifier = ref.read(bleStateProvider.notifier);
      await bleNotifier.stopAdvertising();
      await bleNotifier.stopScanning();
      dev.log('✅ BLE gestoppt');
    } catch (e) {
      dev.log('ℹ️ BLE-Stopp übersprungen: $e');
    }

    // Filter-Referenzen zurücksetzen — die nächste Session darf nicht
    // gegen den letzten Punkt dieser Session vergleichen
    _lastAcceptedPos = null;
    _lastAcceptedTime = null;
    _lastPositionTime = null;
    _lastValidCog = null;

    final finishedId = state.activeSessionId;
    if (finishedId != null) {
      final sessionRepo = ref.read(sessionRepositoryProvider);
      await sessionRepo.completeSession(finishedId);
    }

    state = RecordingState(completedSessionId: finishedId);
  }
}
