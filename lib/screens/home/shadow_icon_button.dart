import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tacktics/providers/ui_providers.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

/// Wie oft getippt werden muss, bis der Entwicklermodus aufgeht.
const _devTapsNeeded = 10;

/// Ab wie vielen fehlenden Tipps der Countdown sichtbar wird.
///
/// Nicht ab dem ersten: eine versteckte Geste, die sich sofort meldet, ist
/// nicht mehr versteckt. Erst kurz vor dem Ziel gibt es Rückmeldung — sonst
/// weiß man nicht, ob man bei drei oder bei sieben ist.
const _devCountdownFrom = 3;

/// So lange darf zwischen zwei Tipps vergehen, sonst beginnt die Zählung von
/// vorn. Ohne das summieren sich versehentliche Tipps über Tage zu einer
/// Freischaltung, die niemand ausgelöst hat.
const _devTapTimeout = Duration(seconds: 3);

class ShadowIconButton extends ConsumerStatefulWidget {
  final IconData icon;
  final String? label;
  final double size;
  final VoidCallback? onTap;
  final Color? color;

  /// Ob der Button benutzbar ist. Der alleinige Schalter dafür — `onTap`
  /// beschreibt nur noch, WAS passiert, nicht ob.
  ///
  /// Früher hat man das über `onTap: null` ausgedrückt. Beides nebeneinander
  /// hieße zwei Schreibweisen für dieselbe Sache, und nur eine davon zeigt
  /// [blockedMessage].
  final bool enabled;

  /// Ob der Button hinter dem Entwicklermodus liegt.
  ///
  /// Solange der nicht freigeschaltet ist, wird der Button ausgegraut, zeigt
  /// [devBlockedMessage] und löst [onTap] nicht aus. Die Tipps zählen dabei
  /// im Hintergrund auf die Freischaltgeste ein.
  final bool devOnly;

  /// Was angezeigt wird, wenn jemand auf den Button tippt, obwohl [enabled]
  /// false ist. Null heißt: kommentarlos nichts tun.
  ///
  /// Gilt NICHT für die Dev-Sperre — dafür gibt es [devBlockedMessage]. Die
  /// beiden Fälle sagen Verschiedenes: der eine "geht gerade nicht", der
  /// andere "gibt es noch nicht".
  final String? blockedMessage;

  /// Kurzhinweis eines dev-gesperrten Buttons.
  ///
  /// Erscheint beim ersten Tipp einer Folge, nicht bei jedem. Wer zehnmal
  /// hintereinander tippt, sucht die Freischaltung und liest nicht mit; zehn
  /// gestapelte Meldungen wären dort nur im Weg. Kurz vor dem Ziel übernimmt
  /// ohnehin der Countdown.
  ///
  /// Muss kurz bleiben: die Snackbar ist auf 80 px Höhe festgenagelt und
  /// schneidet nach zwei Zeilen mit "…" ab. Alles Längere gehört in
  /// [devBlockedDetails].
  final String? devBlockedMessage;

  /// Die ausführliche Erklärung — was die Funktion können wird und wann.
  ///
  /// Landet nicht in der Snackbar, sondern in einem Dialog, den man über
  /// einen Tipp auf die Snackbar erreicht. Dort gibt es keine Zeilengrenze,
  /// keine Zeitbegrenzung, und der Text skaliert mit der Systemschrift.
  ///
  /// Der Dialog geht bewusst NICHT von selbst auf: er würde den Button
  /// verdecken und müsste weggeklickt werden, und weil das länger dauert als
  /// der Tipp-Timeout, käme die Freischaltgeste nie über den ersten Tipp
  /// hinaus.
  ///
  /// Ist er gesetzt, sollte [devBlockedMessage] darauf hinweisen, dass es
  /// mehr zu lesen gibt — eine antippbare Snackbar sieht man ihr nicht an.
  final String? devBlockedDetails;

  const ShadowIconButton({
    super.key,
    required this.icon,
    this.label,
    this.onTap,
    this.size = 24,
    this.color,
    this.enabled = true,
    this.devOnly = false,
    this.blockedMessage,
    this.devBlockedMessage,
    this.devBlockedDetails,
  });

  @override
  ConsumerState<ShadowIconButton> createState() => _ShadowIconButtonState();
}

class _ShadowIconButtonState extends ConsumerState<ShadowIconButton> {
  bool _pressed = false;

  /// Bewusst lokal, nicht im Provider: die Geste soll auf EINEM Button
  /// stattfinden. Dass der State beim Verlassen des Bildschirms verfällt, ist
  /// hier der gewünschte Nebeneffekt.
  int _devTaps = 0;
  DateTime? _lastDevTap;

  void _handleTap() {
    final unlocked = ref.read(devUnlockProvider);

    // Reihenfolge ist entscheidend: die Dev-Geste kommt VOR der Prüfung auf
    // `enabled`. Sonst wäre ein gesperrter Button, der gerade auch inaktiv ist
    // — beim Upload-Button der Normalfall, solange keine Session gewählt ist —
    // nie freizuschalten, weil der Tipp vorher geschluckt würde.
    if (widget.devOnly && !unlocked) {
      _registerDevTap();
      return;
    }

    if (!widget.enabled) {
      _showBlocked();
      return;
    }

    widget.onTap?.call();
  }

  void _registerDevTap() {
    final now = DateTime.now();
    final expired =
        _lastDevTap == null || now.difference(_lastDevTap!) > _devTapTimeout;
    _devTaps = expired ? 1 : _devTaps + 1;
    _lastDevTap = now;

    if (_devTaps >= _devTapsNeeded) {
      _devTaps = 0;
      ref.read(devUnlockProvider.notifier).unlock();
      _snack('Entwicklermodus freigeschaltet');
      return;
    }

    final remaining = _devTapsNeeded - _devTaps;
    if (remaining <= _devCountdownFrom) {
      // Kurz vor dem Ziel zählt der Countdown — er verdrängt die Erklärung,
      // weil hier niemand mehr die Funktionsbeschreibung sucht.
      _snack('Noch $remaining …');
    } else if (expired) {
      // Erster Tipp einer Folge: hier liest jemand tatsächlich mit.
      final message = widget.devBlockedMessage;
      final details = widget.devBlockedDetails;
      if (message != null) {
        _snack(
          message,
          onTap: details == null ? null : () => _showDetails(details),
        );
      }
    }
  }

  /// Der lange Text, auf Anforderung. Erreichbar über einen Tipp auf die
  /// Snackbar — die sitzt am oberen Rand und verdeckt den Button nicht, die
  /// Freischaltgeste bleibt also parallel benutzbar.
  void _showDetails(String details) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Noch nicht verfügbar'),
        content: Text(details),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Gegenstück zur Freischaltgeste. Wird in [build] nur verdrahtet, wenn der
  /// Modus offen ist — auf einem gesperrten Button darf ein Langdruck nichts
  /// tun, sonst verrät er, dass dort überhaupt etwas zu holen ist.
  void _handleLongPress() {
    _devTaps = 0;
    _lastDevTap = null;
    ref.read(devUnlockProvider.notifier).lock();
    _snack('Entwicklermodus gesperrt');
  }

  void _showBlocked() {
    final message = widget.blockedMessage;
    if (message != null) _snack(message);
  }

  void _snack(String message, {VoidCallback? onTap}) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.info(message: message),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = ref.watch(devUnlockProvider);
    final devLocked = widget.devOnly && !unlocked;

    // Beide Sperren grauen aus. Der dev-gesperrte Button versteckt sich also
    // nicht, er sagt über devBlockedMessage, was er einmal können wird — die
    // Freischaltgeste dahinter bleibt trotzdem unsichtbar.
    final looksDisabled = devLocked || !widget.enabled;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _handleTap,
      // Nur am freigeschalteten Button. `null` heißt für den GestureDetector,
      // dass er den Langdruck gar nicht erst erkennt — ein gesperrter Button
      // verhält sich damit exakt wie jeder andere.
      onLongPress: widget.devOnly && unlocked ? _handleLongPress : null,
      child: Opacity(
        opacity: looksDisabled ? 0.35 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: widget.size,
              color: widget.color,
              shadows: _pressed || looksDisabled
                  ? []
                  : const [Shadow(color: Colors.black38, blurRadius: 15.0)],
            ),
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
