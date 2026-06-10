import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/data/entities/gps_point.dart';
import 'package:sailing_analytics/providers/repository_providers.dart';

class DbTestScreen extends ConsumerWidget {
  const DbTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(sessionRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DB Test'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DriftDbViewer(ref.read(databaseProvider)),
              ),
            ),
            child: const Text('View DB'),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: repo.watchSessions(),
        builder: (context, snapshot) {
          final sessions = snapshot.data ?? [];
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (_, i) {
              final s = sessions[i];
              return ListTile(
                title: Text(s.name),
                subtitle: Text(
                  '${s.isComplete ? 'complete' : 'in progress'} · ${s.boatId}',
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final id = await repo.createSession(
            name: 'Test Session',
            boatId: '',
          );
          for (int i = 0; i < 3; i++) {
            await repo.savePoint(
              GpsPointEntity(
                sessionId: id,
                timestamp: DateTime.now(),
                lat: 52.5 + (i * 0.001),
                lon: 13.4 + (i * 0.001),
                sog: 5.0 + i,
                cog: 180.0,
                heel: 10.0,
                pitch: 0.0,
                magHeading: 182.0,
                accuracy: 3.0,
              ),
            );
          }
          await repo.completeSession(id);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
