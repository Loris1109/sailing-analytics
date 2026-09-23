import 'package:flutter/material.dart';
import 'package:tacktics/providers/ui_providers.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/header/collapsed_header.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/header/expanded_header.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/header/trim_header.dart';
import 'package:tacktics/screens/home/widgets/panel_bg.dart';

class SlideMenuHeader extends StatelessWidget {
  final MenuMode mode;
  final bool isExpanded;
  final void Function(DragUpdateDetails) onSwipe;
  final void Function(DragEndDetails) onSwipeEnd;
  final VoidCallback onTap;

  const SlideMenuHeader({
    super.key,
    required this.mode,
    required this.isExpanded,
    required this.onSwipe,
    required this.onSwipeEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onVerticalDragUpdate: onSwipe,
      onVerticalDragEnd: onSwipeEnd,
      child: CompassPanelBg(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: SizedBox(
          height: 28,
          width: double.infinity,
          child: Column(
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Center(
                  // Gleiche Aufteilung wie im Body, damit Kopf und Inhalt
                  // nicht auseinanderlaufen können.
                  child: switch ((mode, isExpanded)) {
                    (MenuMode.normal, false) => const CollapsedHeader(),
                    (MenuMode.normal, true) => const ExpandedHeader(),
                    (MenuMode.trim, _) => const TrimHeader(),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
