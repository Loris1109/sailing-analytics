import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tacktics/data/entities/session_clip.dart';
import 'package:tacktics/providers/repository_providers.dart';
import 'package:tacktics/providers/session_providers.dart';
import 'package:tacktics/providers/ui_providers.dart';

/// Das aufgezogene Gegenstück zum TrimBody — dieselbe Geste wie im
/// Normalmodus (hochziehen zeigt die Liste), nur ist der Gegenstand hier
/// nicht die Sessionliste, sondern die gespeicherten Ausschnitte der
/// ausgewählten Session.
///
/// Ein Tipp legt den Ausschnitt auf die Karte und klappt zurück zum Profil:
/// damit ist das Durchsehen der einzelnen Rennen eine Geste pro Rennen.
class TrimClipsBody extends ConsumerWidget {
  const TrimClipsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(selectedSessionProvider);
    if (session == null) return const SizedBox.shrink();

    final clips = ref.watch(sessionClipsProvider(session.id)).value ?? [];

    if (clips.isEmpty) {
      // Sagt, wie man die Liste füllt, statt nur festzustellen, dass sie
      // leer ist — sonst sieht der Zustand aus wie ein Fehler.
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Zieh unten einen Ausschnitt auf und sichere ihn, '
            'um ihn hier wiederzufinden.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: clips.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        final clip = clips[index];
        final isActive = ref.watch(trimRangeProvider) == clip.range;

        // Gleiche Geste wie in der Sessionliste: nach rechts wischen löscht.
        return Dismissible(
          key: Key(clip.id),
          direction: DismissDirection.startToEnd,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            // Zeigt die Karte gerade diesen Ausschnitt, muss sie zurück auf
            // die ganze Session — sonst bliebe ein Schnitt stehen, zu dem
            // es keinen Eintrag mehr gibt.
            if (ref.read(trimRangeProvider) == clip.range) {
              ref.read(trimRangeProvider.notifier).clear();
            }
            ref.read(sessionRepositoryProvider).deleteClip(clip.id);
          },
          child: _ClipListItem(
            clip: clip,
            isActive: isActive,
            onTap: () {
              ref.read(trimRangeProvider.notifier).set(clip.range);
              // Zuklappen, nicht den Modus verlassen: man sieht das Ergebnis
              // sofort auf der Karte und im Profil und kann den nächsten
              // Lauf mit einer Geste holen.
              ref.read(isExpandedProvider.notifier).close();
            },
          ),
        );
      },
    );
  }
}

class _ClipListItem extends StatelessWidget {
  final SessionClipEntity clip;
  final bool isActive;
  final VoidCallback onTap;

  const _ClipListItem({
    required this.clip,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isActive ? Colors.black12 : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 18,
              color: Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clip.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_hm(clip.range.start)} – ${_hm(clip.range.end)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              _duration(clip.duration),
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

  static String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String _duration(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}min' : '${m}min';
  }
}
