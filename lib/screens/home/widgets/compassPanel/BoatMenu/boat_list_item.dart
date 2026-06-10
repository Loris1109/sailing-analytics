import 'package:flutter/material.dart';
import 'package:sailing_analytics/data/entities/boat.dart';

class BoatListItem extends StatelessWidget {
  final BoatEntity boat;
  final bool isSelected;
  final VoidCallback? onTap;

  const BoatListItem({
    super.key,
    required this.boat,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Farbiger Punkt
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colorForSelected(isSelected),
              ),
            ),
            const SizedBox(width: 12),

            // Name + Kurzinfo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boat.sailNumber,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _shortInfo(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortInfo() {
    //name falls vorhanden + Klasse
    if (boat.name.isNotEmpty) {
      return '${boat.name} • ${boat.boatClass}';
    }
    return boat.boatClass;
  }

  Color _colorForSelected(bool selected) {
    return selected ? Colors.blue : Colors.grey;
  }
}
