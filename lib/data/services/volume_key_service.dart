import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:volume_controller/volume_controller.dart';

enum VolumeKey { up, down }

enum VolumeKeyAction { tap, longPress }

class VolumeKeyEvent {
  final VolumeKey key;
  final VolumeKeyAction action;

  const VolumeKeyEvent(this.key, this.action);
}

/// Die Hardware-Lautstärketasten als Bedienelement für die Racing-View.
///
/// Die beiden Plattformen liefern grundverschiedene Signale:
///
/// **Android** gibt echte Key-Events her. `MainActivity` schluckt sie und
/// reicht Druck und Loslassen durch — die Haltedauer ist damit exakt bekannt
/// und die Systemlautstärke ändert sich nie.
///
/// **iOS** gibt keine Tastendrücke heraus. Dort wird die Systemlautstärke
/// beobachtet: jeder Schritt weg vom Ankerwert ist ein Tick, danach wird
/// sofort zurückgesetzt, damit der nächste Druck wieder eine Änderung erzeugen
/// kann — an 0.0 oder 1.0 käme sonst kein Event mehr. Ein Halten ist dort eine
/// Serie von Ticks, das Loslassen wird aus deren Ausbleiben geschlossen.
class VolumeKeyService {
  static const _channel = MethodChannel(
    'com.example.sailing_analytics/volume_buttons',
  );

  /// Wie lange gehalten werden muss, damit es als Langdruck zählt.
  static const holdDuration = Duration(seconds: 2);

  /// iOS: Pause zwischen zwei Lautstärkeschritten, ab der eine Serie als
  /// beendet gilt. Muss deutlich über der Auto-Repeat-Rate von iOS (~100 ms)
  /// liegen, sonst zerfällt ein Halten in lauter Einzeldrücke.
  static const _repeatGap = Duration(milliseconds: 350);

  /// iOS: Lautstärke, auf die nach jedem Tick zurückgesetzt wird. Mittig,
  /// damit in beide Richtungen Luft bleibt.
  static const _anchorVolume = 0.5;

  /// Toleranz beim Vergleich mit dem Anker. iOS rastet in 16 Stufen
  /// (0.0625), der Wert liegt bequem darunter.
  static const _anchorEpsilon = 0.01;

  final _events = StreamController<VolumeKeyEvent>.broadcast();
  final _holding = StreamController<VolumeKey?>.broadcast();

  Stream<VolumeKeyEvent> get events => _events.stream;

  /// Die Taste, die gerade auf einen Langdruck zuläuft — `null`, sobald
  /// losgelassen wurde oder der Langdruck ausgelöst hat. Damit kann die UI
  /// mitzählen, wie lange noch zu halten ist.
  Stream<VolumeKey?> get holding => _holding.stream;

  /// Nur Android meldet ein echtes Loslassen; auf iOS ersetzt [_repeatGap] es.
  final bool _hasReleaseEvents = Platform.isAndroid;

  bool _running = false;
  double? _volumeBeforeStart;

  VolumeKey? _activeKey;
  VolumeKey? _holdingNotified;
  Timer? _holdTimer;
  Timer? _gapTimer;
  bool _longPressFired = false;

  Future<void> start() async {
    if (_running) return;
    _running = true;

    if (Platform.isAndroid) {
      _channel.setMethodCallHandler(_onPlatformCall);
      // Erst ab hier schluckt die Activity die Tasten — sonst könnte man im
      // Rest der App die Lautstärke nicht mehr verstellen
      await _channel.invokeMethod('setIntercepting', true);
      return;
    }

    _volumeBeforeStart = await VolumeController.instance.getVolume();
    VolumeController.instance.showSystemUI = false;
    await VolumeController.instance.setVolume(_anchorVolume);
    VolumeController.instance.addListener(
      _onVolumeChanged,
      fetchInitialVolume: false,
    );
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _cancelGesture();

    if (Platform.isAndroid) {
      await _channel.invokeMethod('setIntercepting', false);
      _channel.setMethodCallHandler(null);
      return;
    }

    VolumeController.instance.removeListener();
    VolumeController.instance.showSystemUI = true;

    final restore = _volumeBeforeStart;
    _volumeBeforeStart = null;
    if (restore != null) {
      await VolumeController.instance.setVolume(restore);
    }
  }

  void dispose() {
    _cancelGesture();
    _events.close();
    _holding.close();
  }

  // ─── Android ───────────────────────────────────────────────────

  Future<void> _onPlatformCall(MethodCall call) async {
    final key = switch (call.arguments) {
      'up' => VolumeKey.up,
      'down' => VolumeKey.down,
      _ => null,
    };
    if (key == null) return;

    switch (call.method) {
      case 'volumeKeyDown':
        _tick(key);
      case 'volumeKeyUp':
        _release(key);
    }
  }

  // ─── iOS ───────────────────────────────────────────────────────

  void _onVolumeChanged(double volume) {
    final delta = volume - _anchorVolume;
    // Das Zurücksetzen erzeugt selbst ein Event — das ist genau der Anker
    if (delta.abs() < _anchorEpsilon) return;

    _tick(delta > 0 ? VolumeKey.up : VolumeKey.down);

    // Wieder scharf machen, sonst läuft die Lautstärke in den Anschlag und
    // weitere Drücke erzeugen kein Event mehr
    VolumeController.instance.setVolume(_anchorVolume);
  }

  // ─── Gestenerkennung (gemeinsam) ───────────────────────────────

  void _tick(VolumeKey key) {
    if (_activeKey != key) {
      _cancelGesture();
      _activeKey = key;
      _longPressFired = false;
      _notifyHolding(key);
      _holdTimer = Timer(holdDuration, () {
        _longPressFired = true;
        // Countdown ist durch — die UI blendet ihn aus, bevor der Dialog kommt
        _notifyHolding(null);
        _emit(key, VolumeKeyAction.longPress);
      });
    }

    // Auf Android beendet das Loslassen die Geste, auf iOS die Stille
    if (!_hasReleaseEvents) {
      _gapTimer?.cancel();
      _gapTimer = Timer(_repeatGap, _endGesture);
    }
  }

  void _release(VolumeKey key) {
    if (_activeKey != key) return;
    _endGesture();
  }

  void _endGesture() {
    final key = _activeKey;
    final longPressFired = _longPressFired;
    _cancelGesture();
    // Nach einem Langdruck folgt kein Tap mehr — sonst löste jedes Halten
    // beide Aktionen aus
    if (key != null && !longPressFired) {
      _emit(key, VolumeKeyAction.tap);
    }
  }

  void _cancelGesture() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _gapTimer?.cancel();
    _gapTimer = null;
    _activeKey = null;
    _longPressFired = false;
    _notifyHolding(null);
  }

  void _emit(VolumeKey key, VolumeKeyAction action) {
    if (!_events.isClosed) _events.add(VolumeKeyEvent(key, action));
  }

  /// Nur bei echtem Wechsel senden — `_cancelGesture` läuft auch dann, wenn
  /// gar keine Geste offen war, und würde sonst null-Events streuen.
  void _notifyHolding(VolumeKey? key) {
    if (_holdingNotified == key) return;
    _holdingNotified = key;
    if (!_holding.isClosed) _holding.add(key);
  }
}
