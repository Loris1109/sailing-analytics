import 'package:flutter/material.dart';

class ShadowIconButton extends StatefulWidget {
  final IconData icon;
  final String? label;
  final double size;
  final VoidCallback? onTap;

  const ShadowIconButton({
    super.key,
    required this.icon,
    this.label,
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
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            size: widget.size,
            shadows: _pressed
                ? []
                : const [Shadow(color: Colors.black38, blurRadius: 15.0)],
          ),
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
