import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tacktics/data/entities/session.dart';
import 'package:tacktics/data/services/trim.dart';
import 'package:tacktics/providers/repository_providers.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

/// Schreibt eine GPX-Datei und öffnet das Teilen-Blatt.
///
/// Eine Stelle für beide Knöpfe: der im CollapsedBody ruft sie ohne [range]
/// auf und exportiert damit die ganze Session, der im Trim-Panel mit dem
/// aufgezogenen Ausschnitt. Der Unterschied zwischen beiden ist genau dieser
/// eine Parameter — zwei Kopien des Ablaufs wären zwei Orte, an denen man
/// eine Änderung am Format vergessen kann.
Future<void> shareSessionGpx(
  BuildContext context,
  WidgetRef ref, {
  required SessionEntity session,
  TrimRange? range,

  /// Titel für den Ausschnitt. Nur zusammen mit [range] sinnvoll; ohne ihn
  /// trägt die Datei den Sessionnamen.
  String? clipName,
}) async {
  final repo = ref.read(sessionRepositoryProvider);

  final allPoints = await repo.getPointsForSession(session.id);
  final points = range?.apply(allPoints) ?? allPoints;

  if (points.isEmpty) {
    if (context.mounted) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.info(
          message: range == null
              ? 'Diese Session hat keine GPS-Punkte.'
              : 'Dieser Ausschnitt hat keine GPS-Punkte.',
        ),
      );
    }
    return;
  }

  // Messungen mitbeschneiden: sie hängen an Punkten, die außerhalb des
  // Ausschnitts gar nicht mehr in der Datei stehen. Nebenbei wird der
  // Export dadurch schneller — buildGpx sucht je Punkt linear durch diese
  // Liste, das ist der teuerste Teil des Ganzen.
  final allMeasurements = await ref
      .read(rangeMeasurementRepositoryProvider)
      .getRangeMeasurementsForSession(session.id);
  final measurements = range == null
      ? allMeasurements
      : allMeasurements.where((m) => range.contains(m.timestamp)).toList();

  // Boot kann gelöscht worden sein — Export läuft dann ohne Bootsinfos
  final boatId = session.boatId;
  final boat = boatId == null
      ? null
      : await ref.read(boatRepositoryProvider).getBoatById(boatId);

  final service = ref.read(gpxExportServiceProvider);
  final gpx = service.buildGpx(
    session,
    boat,
    points,
    measurements,
    clipName: clipName,
  );

  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/${service.fileNameFor(session, clipName: clipName)}',
  );
  await file.writeAsString(gpx);

  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path, mimeType: 'application/gpx+xml')]),
  );
}
