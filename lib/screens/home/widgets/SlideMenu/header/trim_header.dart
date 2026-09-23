import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tacktics/providers/ui_providers.dart';

/// Kopfzeile des Trim-Modus.
///
/// Gleiche Form wie der CollapsedHeader — links und rechts eine Zeit, in der
/// Mitte ein Titel. Hier stehen die Grenzen des Ausschnitts und wandern beim
/// Ziehen mit; ohne gesetzten Ausschnitt die der ganzen Session. So braucht
/// die Leiste selbst keine Zahlen anzuzeigen und bleibt beim Ziehen frei.
class TrimHeader extends ConsumerWidget {
  const TrimHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(selectedSessionProvider);
    final range = ref.watch(trimRangeProvider);

    return Row(
      children: [
        Text(
          _formatTime(range?.start ?? session?.startTime),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Expanded(
          child: Center(
            child: Text(
              // Der Titel sagt, was die beiden Zeiten bedeuten — sonst sähe
              // ein gesetzter Ausschnitt aus wie eine kürzere Session.
              range == null ? 'Ganze Session' : 'Ausschnitt',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Text(
          _formatTime(range?.end ?? session?.endTime),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
