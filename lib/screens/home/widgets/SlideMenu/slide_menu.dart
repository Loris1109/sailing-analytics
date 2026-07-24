import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/providers/ui_providers.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/slide_menu_body.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/slide_menu_header.dart';

class SlideMenu extends ConsumerStatefulWidget {
  const SlideMenu({super.key});

  @override
  ConsumerState<SlideMenu> createState() => _SlideMenuState();
}

class _SlideMenuState extends ConsumerState<SlideMenu> {
  static const double collapsedHeight = 130.0;
  late double expandedHeight;
  late double _currentHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    expandedHeight = MediaQuery.of(context).size.height * 0.6;
    _currentHeight = collapsedHeight;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _currentHeight -= details.delta.dy;
      _currentHeight = _currentHeight.clamp(collapsedHeight, expandedHeight);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    late bool shouldExpand;

    if (velocity < -300) {
      shouldExpand = true; // schnell nach oben geflockt → expandieren
    } else if (velocity > 300) {
      shouldExpand = false; // schnell nach unten geflockt → kollabieren
    } else {
      // langsam losgelassen → Midpoint-Logik als Fallback
      final midpoint = (collapsedHeight + expandedHeight) / 2;
      shouldExpand = _currentHeight > midpoint;
    }
    setState(() {
      _currentHeight = shouldExpand ? expandedHeight : collapsedHeight;
    });
    ref.read(isExpandedProvider.notifier).setExpanded(shouldExpand);
  }

  void _togglePanel() {
    final isExpanded = ref.read(isExpandedProvider);
    setState(() {
      _currentHeight = isExpanded ? collapsedHeight : expandedHeight;
    });
    ref.read(isExpandedProvider.notifier).setExpanded(!isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = ref.watch(isExpandedProvider);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: SlideMenuBody(
            showExpanded: _currentHeight > collapsedHeight,
            currentHeight: _currentHeight,
          ),
        ),
        SlideMenuHeader(
          isExpanded: isExpanded,
          onSwipe: _onDragUpdate,
          onSwipeEnd: _onDragEnd,
          onTap: _togglePanel,
        ),
      ],
    );
  }
}
