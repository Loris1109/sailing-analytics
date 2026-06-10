import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/providers/boat_providers.dart';
import 'package:sailing_analytics/providers/repository_providers.dart';
import 'package:sailing_analytics/screens/home/widgets/compassPanel/BoatMenu/boat_list_item.dart';

class BoatMenuBody extends ConsumerWidget {
  const BoatMenuBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boats = ref
        .watch(boatsProvider)
        .when(data: (s) => s, error: (_, _) => [], loading: () => []);

    if (boats.isEmpty) {
      return Container(
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
        child: const Center(
          child: Text(
            'Keine Boote vorhanden',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
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
            child: ListView.separated(
              itemCount: boats.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 40),
              itemBuilder: (context, index) {
                final boat = boats[index];

                return Dismissible(
                  key: Key(boat.id),
                  direction:
                      DismissDirection.startToEnd, // nur rechts = löschen
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
                        title: const Text('Boot löschen?'),
                        content: Text(boat.name),
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
                    // if (result == true) {
                    //   if (ref.read(selectedSessionProvider)?.id == session.id) {
                    //     ref.read(selectedSessionProvider.notifier).clear();
                    //   }
                    // }

                    return result ?? false;
                  },
                  onDismissed: (_) {
                    // Nur noch DB-Delete – selectedSession ist bereits null
                    ref.read(boatRepositoryProvider).deleteBoat(boat.id);
                  },
                  child: BoatListItem(
                    boat: boat,
                    isSelected: ref
                        .watch(activeBoatProvider)
                        .when(
                          data: (active) => active?.id == boat.id,
                          error: (_, _) => false,
                          loading: () => false,
                        ),
                    onTap: () =>
                        ref.read(boatRepositoryProvider).setActiveBoat(boat.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
