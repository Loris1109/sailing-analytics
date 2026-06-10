import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/data/entities/session.dart';
import 'package:sailing_analytics/providers/repository_providers.dart';
import 'package:sailing_analytics/providers/ui_providers.dart';

class CollapsedHeader extends ConsumerWidget {
  const CollapsedHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gate: nur anzeigen wenn eine Session in dieser App-Sitzung abgeschlossen wurde
    final session = ref.watch(selectedSessionProvider);
    return Row(
      children: [
        Text(
          _formatTime(session?.startTime),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: session != null
                  ? () => _showRenameDialog(context, ref, session)
                  : null,
              child: Text(
                session?.name ?? 'Session Starten oder Auswählen',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: session != null
                      ? TextDecoration
                            .underline // visuelles Feedback: antippbar
                      : TextDecoration.none,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        Text(
          _formatTime(session?.endTime),
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

Future<void> _showRenameDialog(
  BuildContext context,
  WidgetRef ref,
  SessionEntity session,
) async {
  final repo = ref.read(sessionRepositoryProvider);
  final selectedNotifier = ref.read(selectedSessionProvider.notifier);
  final controller = TextEditingController(text: session.name);

  // Dialog gibt String? zurück – direkt den neuen Namen
  final newName = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Session umbenennen'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (val) => Navigator.pop(ctx, val.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, null), // null = Abbrechen
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Speichern'),
        ),
      ],
    ),
  );

  //controller.dispose();

  if (newName == null || newName.isEmpty || newName == session.name) return;

  // Erst UI updaten (kein await) → kein Rebuild-Konflikt
  selectedNotifier.select(session.copyWith(name: newName));
  // Dann DB im Hintergrund – kein await nötig
  repo.updateSessionName(session.id, newName);
}
