import 'package:flutter/material.dart';
import 'package:sailing_analytics/data/entities/session_with_boat.dart';

class SessionListItem extends StatelessWidget {
  final SessionWithBoat sessionWithBoat;
  final bool isSelected;
  final VoidCallback? onTap;

  const SessionListItem({
    super.key,
    required this.sessionWithBoat,
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
                color: _colorForDate(sessionWithBoat.session.startTime),
              ),
            ),
            const SizedBox(width: 12),

            // Name + Kurzinfo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sessionWithBoat.session.name,
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

            // Distanz – Placeholder bis Berechnung implementiert
            Text(
              _formatDistance(sessionWithBoat.session.distance),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double? m) {
    if (m == null) return '—';
    if (m > 1000) return '${(m / 1000).toStringAsFixed(1)} km';
    return '${m.round()} m';
  }

  String _shortInfo() {
    final date = _formatDate(sessionWithBoat.session.startTime);
    final duration = _formatDuration();
    return '$date  ·  $duration  ·  ${sessionWithBoat.boat?.sailNumber}';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) return 'Today';
    return '${dt.day}.${dt.month}.${dt.year % 100}';
  }

  String _formatDuration() {
    if (sessionWithBoat.session.endTime == null) return '—';
    final diff = sessionWithBoat.session.endTime!.difference(
      sessionWithBoat.session.startTime,
    );
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }

  Color _colorForDate(DateTime date) {
    final days = date.difference(DateTime(2000)).inDays;
    const goldenRatio = 0.618033988749895;
    final hue = ((days * goldenRatio) % 1.0) * 360;
    return HSVColor.fromAHSV(1.0, hue, 0.65, 0.85).toColor();
  }
}
