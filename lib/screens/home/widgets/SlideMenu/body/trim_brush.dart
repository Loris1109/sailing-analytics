import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tacktics/data/services/speed_profile.dart';
import 'package:tacktics/data/services/trim.dart';
import 'package:tacktics/providers/ui_providers.dart';

/// Die zwei Griffe über dem Speed-Profil, mit denen der sichtbare Ausschnitt
/// aufgezogen wird. Liegt als Schicht ÜBER dem Profil — die Balken bleiben
/// sichtbar, außerhalb des Ausschnitts nur verschleiert.
///
/// Der Zustand liegt im [trimRangeProvider], nicht hier: die Karte liest
/// denselben Wert, und ein Ausschnitt, der beim Verlassen des Trim-Modus
/// verfiele, wäre nutzlos.
class TrimBrush extends ConsumerStatefulWidget {
  final SpeedProfile profile;

  const TrimBrush({super.key, required this.profile});

  @override
  ConsumerState<TrimBrush> createState() => _TrimBrushState();
}

enum _Handle { start, end }

class _TrimBrushState extends ConsumerState<TrimBrush> {
  /// Welcher Griff gerade gezogen wird. Beim Aufsetzen EINMAL bestimmt und
  /// bis zum Loslassen festgehalten: wer über den anderen Griff hinauszieht,
  /// soll nicht mitten in der Geste den Griff wechseln.
  _Handle? _dragging;

  static const _handleWidth = 14.0;

  /// Schmalster zulässiger Ausschnitt, als Anteil der Session. Verhindert,
  /// dass die Griffe sich kreuzen oder auf null zusammenfallen — ein leerer
  /// Ausschnitt wäre eine leere Karte ohne erkennbaren Grund.
  static const _minFraction = 0.02;

  void _onDragStart(DragStartDetails details, double width) {
    final (startT, endT) = _fractions();
    final x = details.localPosition.dx;
    _dragging = (x - startT * width).abs() <= (x - endT * width).abs()
        ? _Handle.start
        : _Handle.end;
  }

  void _onDragUpdate(DragUpdateDetails details, double width) {
    if (_dragging == null || width <= 0) return;
    final (startT, endT) = _fractions();
    final p = widget.profile;
    final t = details.localPosition.dx / width;

    final range = switch (_dragging!) {
      _Handle.start => TrimRange(
        p.timeAt(t.clamp(0.0, (endT - _minFraction).clamp(0.0, 1.0))),
        p.timeAt(endT),
      ),
      _Handle.end => TrimRange(
        p.timeAt(startT),
        p.timeAt(t.clamp((startT + _minFraction).clamp(0.0, 1.0), 1.0)),
      ),
    };

    ref.read(trimRangeProvider.notifier).set(range);
  }

  /// Die aktuellen Griffpositionen als Anteil 0..1. Ohne gesetzten Ausschnitt
  /// stehen sie an den Rändern — die ganze Session ist dann ausgewählt, und
  /// der erste Zug macht daraus einen echten Ausschnitt.
  (double, double) _fractions() {
    final range = ref.read(trimRangeProvider);
    if (range == null) return (0.0, 1.0);
    return (
      widget.profile.fractionAt(range.start),
      widget.profile.fractionAt(range.end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(trimRangeProvider);
    final startT = range == null ? 0.0 : widget.profile.fractionAt(range.start);
    final endT = range == null ? 1.0 : widget.profile.fractionAt(range.end);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          // Die ganze Fläche nimmt die Geste an, nicht nur der schmale Griff:
          // auf dem Wasser trifft niemand 14 px. Aufgesetzt wird irgendwo,
          // gezogen wird der nähere Griff.
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => _onDragStart(d, width),
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, width),
          onHorizontalDragEnd: (_) => _dragging = null,
          onHorizontalDragCancel: () => _dragging = null,
          child: Stack(
            children: [
              // Schleier statt Ausblenden: das Profil außerhalb bleibt als
              // Kontext lesbar, sonst wüsste man beim Ziehen nicht, was
              // hinter dem Griff noch kommt.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: startT * width,
                child: const _Veil(),
              ),
              Positioned(
                left: endT * width,
                right: 0,
                top: 0,
                bottom: 0,
                child: const _Veil(),
              ),
              ..._handle(startT, width),
              ..._handle(endT, width),
            ],
          ),
        );
      },
    );
  }

  /// Ein Griff in zwei Teilen: die durchgehende Kante zeigt, wo genau
  /// geschnitten wird, der Knubbel darauf ist das, was man anfasst. Getrennt,
  /// weil nur der Knubbel am Rand nach innen rutschen darf — die Kante muss
  /// stehen bleiben, sonst zeigt sie auf die falsche Zeit.
  List<Widget> _handle(double t, double width) {
    final x = t * width;
    final maxLeft = (width - _handleWidth).clamp(0.0, double.infinity);

    return [
      Positioned(
        left: (x - 1.5).clamp(0.0, (width - 3).clamp(0.0, double.infinity)),
        top: 0,
        bottom: 0,
        width: 3,
        child: const ColoredBox(color: Colors.black54),
      ),
      Positioned(
        left: (x - _handleWidth / 2).clamp(0.0, maxLeft),
        top: 0,
        bottom: 0,
        width: _handleWidth,
        child: Center(
          child: Container(
            width: _handleWidth,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(7),
              boxShadow: const [
                BoxShadow(blurRadius: 4, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}

class _Veil extends StatelessWidget {
  const _Veil();

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: Colors.white.withValues(alpha: 0.72));
}
