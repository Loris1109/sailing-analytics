import 'package:flutter/material.dart';
import 'package:tacktics/providers/ui_providers.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/collapsed_body.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/expanded_body.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/trim_body.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/body/trim_clips_body.dart';

class SlideMenuBody extends StatelessWidget {
  final MenuMode mode;
  final bool showExpanded;
  final double currentHeight;

  /// Ob der Höhenwechsel animiert werden soll. Beim Moduswechsel und beim
  /// Einrasten nach einer Geste: ja. WÄHREND einer Geste: nein — sonst läuft
  /// das Panel dem Finger hinterher.
  final bool animate;

  const SlideMenuBody({
    super.key,
    required this.mode,
    required this.showExpanded,
    required this.currentHeight,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: animate ? const Duration(milliseconds: 180) : Duration.zero,
      curve: Curves.easeOut,
      height: currentHeight,
      decoration: const BoxDecoration(
        color: Color(0xFFEEEEEE),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            color: Colors.black26,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 22),
          Expanded(
            // Die zwei Achsen des Panels an EINER Stelle aufgelöst. Beide
            // Modi teilen sich dieselbe Geste: zugeklappt die Arbeitsfläche,
            // aufgezogen die dazugehörige Liste.
            child: switch ((mode, showExpanded)) {
              (MenuMode.normal, false) => const CollapsedBody(),
              (MenuMode.normal, true) => const ExpandedBody(),
              (MenuMode.trim, false) => const TrimBody(),
              (MenuMode.trim, true) => const TrimClipsBody(),
            },
          ),
        ],
      ),
    );
  }
}
