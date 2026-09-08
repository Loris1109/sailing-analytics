import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/icons/boat_icons.dart';
import 'package:sailing_analytics/icons/trail_icon.dart';
import 'package:sailing_analytics/providers/ui_providers.dart';
import 'package:sailing_analytics/screens/home/shadow_icon_button.dart';
import 'package:sailing_analytics/screens/home/widgets/compassPanel/BoatMenu/boat_menu.dart';
import 'package:sailing_analytics/screens/home/widgets/compassPanel/compass.dart';
import 'package:sailing_analytics/screens/home/widgets/compassPanel/feedback_dialog.dart';
import 'package:sailing_analytics/screens/home/widgets/panel_bg.dart';

class CompassPanel extends ConsumerStatefulWidget {
  const CompassPanel({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CompassPanelState();
}

class _CompassPanelState extends ConsumerState<CompassPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final pathMode = ref.watch(pathModeProvider);
    return CompassPanelBg(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Compass(),
            //Settings
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0.0, // Halbeumdrehung
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: ShadowIconButton(
                icon: Icons.settings_rounded,
                size: 64,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
            ),

            if (_expanded) ...[
              //Boote
              ShadowIconButton(
                icon: BoatIcons.boaticon,
                size: 52,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: false,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => const BoatMenu(),
                ),
              ),
              //Paths
              ShadowIconButton(
                icon: TrailIcon.trailicon,
                label: switch (pathMode) {
                  PathMode.speed => 'Speed',
                  PathMode.dynamicSpeed => 'Dynamic ',
                  PathMode.heel => 'Krängung',
                },
                size: 52,
                onTap: () => ref.read(pathModeProvider.notifier).next(),
              ),
              //Feedback
              ShadowIconButton(
                icon: Icons.feedback_rounded,
                size: 52,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const FeedbackDialog(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
