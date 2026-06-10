import 'package:flutter/material.dart';

class CompassPanelBg extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const CompassPanelBg({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(50),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      padding: padding,
      child: child,
    );
  }
}
