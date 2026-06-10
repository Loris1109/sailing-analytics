import 'package:flutter/material.dart';

class ShadowIconButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  const ShadowIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 24,
  });

  @override
  State<ShadowIconButton> createState() => _ShadowIconButtonState();
}

class _ShadowIconButtonState extends State<ShadowIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: (_) => enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: (_) => enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Icon(
        widget.icon,
        size: widget.size,
        color: enabled ? null : Theme.of(context).disabledColor,
        shadows: enabled && !_pressed
            ? const [Shadow(color: Colors.black26, blurRadius: 15.0)]
            : [],
      ),
    );
  }
}
