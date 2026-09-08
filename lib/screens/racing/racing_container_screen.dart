import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:sailing_analytics/controllers/recording_controller.dart';
import 'package:sailing_analytics/data/services/volume_key_service.dart';
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
  static const _pageCount = 3;

  final _pageController = PageController();
  final _volumeKeys = VolumeKeyService();
  StreamSubscription<VolumeKeyEvent>? _volumeSub;

  int _currentPage = 0;

  // Riegel, damit ein zweites Tastenevent nicht den Dialog UND danach den
  // Screen poppt — und Schalter für den Countdown, der hinter dem Dialog
  // nicht doppelt laufen soll
  bool _confirmOpen = false;

  bool _showHint = true;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    WakelockPlus.enable();
    _volumeSub = _volumeKeys.events.listen(_onVolumeKey);
    _volumeKeys.start();
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  void _onVolumeKey(VolumeKeyEvent event) {
    if (_confirmOpen) {
      // Der Dialog läuft über dieselben Tasten wie alles andere — wer ihn per
      // Langdruck geöffnet hat, hat vermutlich nasse Hände. Der Riegel fällt
      // sofort, nicht erst nach dem await in _confirmStop, sonst würde ein
      // schnelles zweites Event auf den Screen darunter durchschlagen.
      setState(() => _confirmOpen = false);
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop(event.action == VolumeKeyAction.longPress);
      return;
    }

    if (event.action == VolumeKeyAction.longPress) {
      _confirmStop();
      return;
    }

    switch (event.key) {
      case VolumeKey.down:
        _goToPage((_currentPage + 1) % _pageCount);
      case VolumeKey.up:
        _goToPage((_currentPage + _pageCount - 1) % _pageCount);
    }
  }

  Future<void> _confirmStop() async {
    if (_confirmOpen) return;
    setState(() => _confirmOpen = true);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StopSessionDialog(holding: _volumeKeys.holding),
    );

    if (!mounted) return;
    setState(() => _confirmOpen = false);
    if (confirmed == true) await _stopSession();
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
    _hintTimer?.cancel();
    _volumeSub?.cancel();
    // stop() gibt auf iOS die gemerkte Lautstärke zurück und muss vor dem
    // dispose() durchlaufen — in dispose() lässt sich darauf nicht warten
    unawaited(_volumeKeys.stop().then((_) => _volumeKeys.dispose()));
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final holdSeconds = VolumeKeyService.holdDuration.inSeconds;

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
                  child: Text(
                    '↑ / ↓  Screen wechseln  ·  '
                    'Taste ${holdSeconds}s halten = Session beenden',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Hinter dem Dialog übernimmt dessen eigener Countdown
        if (!_confirmOpen)
          Center(child: _HoldCountdown(holding: _volumeKeys.holding)),
      ],
    );
  }
}

class _StopSessionDialog extends StatelessWidget {
  final Stream<VolumeKey?> holding;

  const _StopSessionDialog({required this.holding});

  @override
  Widget build(BuildContext context) {
    final holdSeconds = VolumeKeyService.holdDuration.inSeconds;

    return AlertDialog(
      title: const Text('Session beenden'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Die Aufzeichnung wird gestoppt und gespeichert.'),
          const SizedBox(height: 16),
          _HoldCountdown(
            holding: holding,
            compact: true,
            idleLabel: 'Taste ${holdSeconds}s halten bestätigt',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Beenden'),
        ),
      ],
    );
  }
}

/// Zeigt, wie lange eine Lautstärketaste noch gehalten werden muss.
///
/// Erscheint bewusst erst nach [_revealAfter]: auf iOS erzeugt auch ein
/// kurzer Druck einen Tick, ohne diese Verzögerung würde der Countdown bei
/// jedem Seitenwechsel kurz aufblitzen.
class _HoldCountdown extends StatefulWidget {
  final Stream<VolumeKey?> holding;

  /// Kompakt für den Dialog, groß und mittig für die Racing-View.
  final bool compact;

  /// Was im kompakten Modus steht, solange nichts gehalten wird. Ohne das
  /// würde der Dialog beim Drücken in der Höhe springen.
  final String? idleLabel;

  const _HoldCountdown({
    required this.holding,
    this.compact = false,
    this.idleLabel,
  });

  @override
  State<_HoldCountdown> createState() => _HoldCountdownState();
}

class _HoldCountdownState extends State<_HoldCountdown> {
  static const _revealAfter = Duration(milliseconds: 400);
  static const _refresh = Duration(milliseconds: 50);

  StreamSubscription<VolumeKey?>? _sub;
  Timer? _ticker;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _sub = widget.holding.listen(_onHolding);
  }

  void _onHolding(VolumeKey? key) {
    _ticker?.cancel();
    _ticker = null;

    if (key == null) {
      if (mounted) setState(() => _startedAt = null);
      return;
    }

    _startedAt = DateTime.now();
    _ticker = Timer.periodic(_refresh, (_) {
      if (mounted) setState(() {});
    });
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startedAt = _startedAt;
    final elapsed = startedAt == null
        ? null
        : DateTime.now().difference(startedAt);
    final visible = elapsed != null && elapsed >= _revealAfter;

    if (!visible) return _idle();

    final total = VolumeKeyService.holdDuration;
    final progress = (elapsed.inMilliseconds / total.inMilliseconds).clamp(
      0.0,
      1.0,
    );
    final remaining =
        ((total - elapsed).inMilliseconds / 1000).clamp(0.0, double.infinity);
    // Dezimalkomma — der Rest der Oberfläche ist ebenfalls deutsch
    final value = remaining.toStringAsFixed(1).replaceAll('.', ',');

    // Im Ring steht die nackte Zahl, den Kontext liefert die Zeile darunter.
    // Im Satz des Dialogs bleibt die Einheit stehen, sonst wäre er kaputt.
    return widget.compact
        ? _compact(progress, 'Noch $value s halten')
        : _large(progress, value);
  }

  Widget _idle() {
    final idleLabel = widget.idleLabel;
    if (!widget.compact || idleLabel == null) {
      return const SizedBox.shrink();
    }
    // Gleiche Höhe wie der aktive Zustand, damit nichts springt
    return _compactRow(
      const SizedBox(width: 20, height: 20),
      idleLabel,
      muted: true,
    );
  }

  Widget _compact(double progress, String label) => _compactRow(
    SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(value: progress, strokeWidth: 2.5),
    ),
    label,
  );

  Widget _compactRow(Widget leading, String label, {bool muted = false}) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            style: muted
                ? style?.copyWith(color: Theme.of(context).hintColor)
                : style,
          ),
        ),
      ],
    );
  }

  Widget _large(double progress, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      // Ohne Material-Vorfahren malt Flutter den Fallback-Textstil mit gelber
      // Doppelunterstreichung — der Screen ist ein nackter Stack ohne Scaffold
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 128,
              height: 128,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Positioned.fill erzwingt feste Constraints. Ohne das
                  // fällt der Indicator auf seine Minimalgröße von 36 px
                  // zurück und die Zahl läuft über den Ring.
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  // FittedBox statt fester Schriftgröße: der Text schrumpft
                  // notfalls selbst, statt aus dem Ring zu laufen
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: FittedBox(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'halten zum Beenden',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
