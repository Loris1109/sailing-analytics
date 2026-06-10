import 'package:flutter/material.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/header/collapsed_header.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/header/expanded_header.dart';
import 'package:sailing_analytics/screens/home/widgets/panel_bg.dart';

class SlideMenuHeader extends StatelessWidget {
  final bool isExpanded;
  final void Function(DragUpdateDetails) onSwipe;
  final void Function(DragEndDetails) onSwipeEnd;

  const SlideMenuHeader({
    super.key,
    required this.isExpanded,
    required this.onSwipe,
    required this.onSwipeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: onSwipe,
      onVerticalDragEnd: onSwipeEnd,
      child: CompassPanelBg(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: SizedBox(
          height: 28,
          width: double.infinity,
          child: Center(
            child: isExpanded
                ? const ExpandedHeader()
                : const CollapsedHeader(),
          ),
        ),
      ),
    );
  }
}
