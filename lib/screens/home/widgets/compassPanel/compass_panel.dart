import 'package:flutter/material.dart';
import 'package:sailing_analytics/icons/boat_icons.dart';
import 'package:sailing_analytics/screens/home/shadow_icon_button.dart';
import 'package:sailing_analytics/screens/home/widgets/compassPanel/BoatMenu/boat_menu.dart';
import 'package:sailing_analytics/screens/home/widgets/compassPanel/compass.dart';
import 'package:sailing_analytics/screens/home/widgets/panel_bg.dart';

class CompassPanel extends StatelessWidget {
  const CompassPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return CompassPanelBg(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Compass(),
          const SizedBox(height: 8),
          // Placeholder für Settings-Icon
          const SizedBox(
            width: 64,
            height: 64,
            child: Icon(Icons.settings_rounded, size: 64),
          ),
          const SizedBox(height: 8),
          ShadowIconButton(
            icon: BoatIcons.boaticon,
            size: 64,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: false,
              backgroundColor: Colors.transparent,
              builder: (ctx) => const BoatMenu(),
            ),
          ),
        ],
      ),
    );
  }
}
