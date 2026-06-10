import 'package:flutter/material.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/body/collapsed_body.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/body/expanded_body.dart';

class SlideMenuBody extends StatelessWidget {
  final bool showExpanded;
  final double currentHeight;

  const SlideMenuBody({
    super.key,
    required this.showExpanded,
    required this.currentHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: showExpanded ? const ExpandedBody() : const CollapsedBody(),
          ),
        ],
      ),
    );
  }
}
