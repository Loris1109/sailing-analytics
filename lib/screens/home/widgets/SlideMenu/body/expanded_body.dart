import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/providers/repository_providers.dart';
import 'package:sailing_analytics/providers/session_providers.dart';
import 'package:sailing_analytics/providers/ui_providers.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/body/session_list_item.dart';

class ExpandedBody extends ConsumerWidget {
  const ExpandedBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsWithBoats = ref.watch(sessionsWithBoatProvider).value ?? [];

    if (sessionsWithBoats.isEmpty) {
      return const Center(
        child: Text(
          'Keine Sessions vorhanden',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: sessionsWithBoats.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 40),
      itemBuilder: (context, index) {
        final sessionWithBoat = sessionsWithBoats[index];

        return Dismissible(
          key: Key(sessionWithBoat.session.id),
          direction: DismissDirection.startToEnd, // nur rechts = löschen
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            final result = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Session löschen?'),
                content: Text(sessionWithBoat.session.name),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Abbrechen'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Löschen'),
                  ),
                ],
              ),
            );

            // Erst HomeScreen zurücksetzen, DANN Animation starten
            if (result == true) {
              if (ref.read(selectedSessionProvider)?.id ==
                  sessionWithBoat.session.id) {
                ref.read(selectedSessionProvider.notifier).clear();
              }
            }

            return result ?? false;
          },
          onDismissed: (_) {
            // Nur noch DB-Delete – selectedSession ist bereits null
            ref
                .read(sessionRepositoryProvider)
                .deleteSession(sessionWithBoat.session.id);
          },
          child: SessionListItem(
            sessionWithBoat: sessionWithBoat,
            isSelected:
                ref.watch(selectedSessionProvider)?.id ==
                sessionWithBoat.session.id,
            onTap: () {
              ref
                  .read(selectedSessionProvider.notifier)
                  .select(sessionWithBoat.session);
              ref.read(isExpandedProvider.notifier).close(); // Menü schließen
            },
          ),
        );
      },
    );
  }
}
