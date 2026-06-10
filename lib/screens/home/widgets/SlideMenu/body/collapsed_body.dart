import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/controllers/recording_controller.dart';
import 'package:sailing_analytics/providers/repository_providers.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/body/session_stats_bar.dart';
import 'package:sailing_analytics/screens/home/widgets/SlideMenu/body/rec_button.dart';
import 'package:sailing_analytics/screens/home/widgets/compassPanel/BoatMenu/boat_menu.dart';
import 'package:sailing_analytics/screens/racing/racing_container_screen.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class CollapsedBody extends ConsumerWidget {
  const CollapsedBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(recordingControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // REC-Knopf
          RecButton(onTap: () => _startSession(context, ref, controller)),

          // Session Stats
          const Expanded(child: SessionStatsBar()),

          // Upload – Placeholder
          IconButton(
            icon: const Icon(Icons.upload_rounded),
            onPressed: null, // noch nicht implementiert
          ),
        ],
      ),
    );
  }

  Future<void> _startSession(
    BuildContext context,
    WidgetRef ref,
    RecordingController controller,
  ) async {
    final activeBoot = await ref.read(boatRepositoryProvider).getActiveBoat();

    if (activeBoot == null) {
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.info(
            message:
                'Bitte wähle zuerst ein Boot aus um eine Session zu starten.',
          ),
        );
        showModalBottomSheet(
          context: context,
          isScrollControlled: false,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const BoatMenu(),
        );
      }
      return;
    }
    final now = DateTime.now();
    await controller.startRecording(
      name: 'Training ${now.day}.${now.month}.${now.year % 100}',
      boatId: activeBoot.id,
    );

    if (context.mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RacingContainerScreen()));
    }
  }
}
