import 'package:flutter/material.dart';
import 'package:sailing_analytics/icons/boat_icons.dart';
import 'package:sailing_analytics/screens/home/shadow_icon_button.dart';
import 'package:sailing_analytics/screens/home/widgets/compassPanel/BoatMenu/add_boat_dialog.dart';
import 'package:sailing_analytics/screens/home/widgets/panel_bg.dart';

class BoatMenuHeader extends StatelessWidget {
  final VoidCallback onClose;

  const BoatMenuHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return CompassPanelBg(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SizedBox(
        height: 28,
        width: double.infinity,
        child: Center(
          child: Row(
            children: [
              ShadowIconButton(
                icon: BoatIcons.addboat,
                size: 20,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const AddBoatDialog(),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Boote',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              ShadowIconButton(
                icon: Icons.close_rounded,
                size: 20,
                onTap: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onPressed() {}
}
