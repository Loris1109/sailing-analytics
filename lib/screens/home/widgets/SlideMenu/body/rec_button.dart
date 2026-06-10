import 'package:flutter/material.dart';

class RecButton extends StatelessWidget {
  final VoidCallback onTap;

  const RecButton({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
        ),
        child: const Icon(Icons.circle, color: Colors.white, size: 24),
      ),
    );
  }
}
