import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tacktics/providers/ui_providers.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/slide_menu_body.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/slide_menu_header.dart';

/// Das Panel am unteren Rand, aufgespannt von ZWEI unabhängigen Achsen:
/// [menuModeProvider] (normal | trim) und [isExpandedProvider] (zu | offen).
/// Vier Kombinationen, vier Inhalte — siehe SlideMenuBody.
///
/// Die Höhe wird ABGELEITET, nicht gehalten: sie ergibt sich aus den beiden
/// Providern, und nur während einer Ziehgeste gibt es mit [_dragHeight] einen
/// eigenen Wert. Sonst müsste jeder, der den Modus oder den Offen-Zustand
/// ändert, daran denken, die Höhe nachzuziehen — und der Moduswechsel käme
/// aus einem ganz anderen Widget (dem Scheren-Knopf im CollapsedBody), das
/// von Höhen nichts wissen sollte.
class SlideMenu extends ConsumerStatefulWidget {
  const SlideMenu({super.key});

  @override
  ConsumerState<SlideMenu> createState() => _SlideMenuState();
}

class _SlideMenuState extends ConsumerState<SlideMenu> {
  /// Nur während einer Ziehgeste gesetzt, danach wieder null.
  double? _dragHeight;

  /// Zugeklappte Höhe je Modus. Der Trim-Modus braucht mehr: Speed-Profil,
  /// Handles und eine Knopfreihe passen nicht in die 130 der Statistikleiste.
  double _collapsedHeight(MenuMode mode) =>
      mode == MenuMode.trim ? 190.0 : 130.0;

  double get _expandedHeight => MediaQuery.of(context).size.height * 0.6;

  double _targetHeight(MenuMode mode, bool isExpanded) =>
      isExpanded ? _expandedHeight : _collapsedHeight(mode);

  /// Die Höhe, von der eine Geste aus weiterrechnet: der laufende Zug, sonst
  /// der abgeleitete Ruhezustand.
  double get _gestureBase =>
      _dragHeight ??
      _targetHeight(ref.read(menuModeProvider), ref.read(isExpandedProvider));

  void _onDragUpdate(DragUpdateDetails details) {
    final mode = ref.read(menuModeProvider);
    final next = _gestureBase - details.delta.dy;
    setState(() {
      _dragHeight = next.clamp(_collapsedHeight(mode), _expandedHeight);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final mode = ref.read(menuModeProvider);
    final velocity = details.velocity.pixelsPerSecond.dy;
    final height = _gestureBase;
    late bool shouldExpand;

    if (velocity < -300) {
      shouldExpand = true; // schnell nach oben geschnippt → expandieren
    } else if (velocity > 300) {
      shouldExpand = false; // schnell nach unten geschnippt → kollabieren
    } else {
      // langsam losgelassen → Midpoint-Logik als Fallback
      final midpoint = (_collapsedHeight(mode) + _expandedHeight) / 2;
      shouldExpand = height > midpoint;
    }

    // Erst die Geste beenden, dann den Zustand setzen: ab hier ist die Höhe
    // wieder abgeleitet und folgt dem Provider von allein.
    setState(() => _dragHeight = null);
    ref.read(isExpandedProvider.notifier).setExpanded(shouldExpand);
  }

  void _togglePanel() => ref.read(isExpandedProvider.notifier).toggle();

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(menuModeProvider);
    final isExpanded = ref.watch(isExpandedProvider);
    final height = _dragHeight ?? _targetHeight(mode, isExpanded);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: SlideMenuBody(
            mode: mode,
            // Aus der laufenden Höhe, nicht aus `isExpanded`: der Inhalt soll
            // schon beim ersten gezogenen Pixel wechseln, nicht erst beim
            // Loslassen.
            showExpanded: height > _collapsedHeight(mode),
            currentHeight: height,
            // Während der Geste hängt eine Animation am Finger hinterher.
            animate: _dragHeight == null,
          ),
        ),
        SlideMenuHeader(
          mode: mode,
          isExpanded: isExpanded,
          onSwipe: _onDragUpdate,
          onSwipeEnd: _onDragEnd,
          onTap: _togglePanel,
        ),
      ],
    );
  }
}
