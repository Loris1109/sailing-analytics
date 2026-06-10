import 'package:flutter/material.dart';
import 'package:sailing_analytics/screens/home/widgets/compassPanel/BoatMenu/boat_menu_body.dart';
import 'package:sailing_analytics/screens/home/widgets/compassPanel/BoatMenu/boat_menu_header.dart';

class BoatMenu extends StatelessWidget {
  const BoatMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(padding: const EdgeInsets.only(top: 22), child: BoatMenuBody()),
        BoatMenuHeader(onClose: () => Navigator.of(context).pop()),
      ],
    );
  }
}
