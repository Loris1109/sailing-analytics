import 'dart:math';

import 'package:sailing_analytics/data/database/tables.dart';
import 'package:sailing_analytics/data/entities/boat.dart';
import 'package:sailing_analytics/data/entities/gps_point.dart';
import 'package:sailing_analytics/data/entities/range_measurements.dart';
import 'package:sailing_analytics/data/entities/session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class UploadService {
  final SupabaseClient supabaseClient;
  const UploadService(this.supabaseClient);
  static const _batchSize = 500;

  Future<void> _ensureSignedIn() async {
    if (supabaseClient.auth.currentSession == null) {
      await supabaseClient.auth.signInAnonymously();
    }
  }

  Future<ResolvedTraining?> resolveTraining(String code) async {
    await _ensureSignedIn();
    final rows = await supabaseClient.rpc(
      'resolve_training',
      params: {'p_code': code},
    );
    if (rows is List && rows.isNotEmpty) {
      final row = rows.first;
      return ResolvedTraining(
        id: row['id'] as String,
        name: row['name'] as String,
        isOpen: row['is_open'] as bool,
      );
    }
    return null; // Code unbekannt
  }

  Future<void> uploadSession(
    SessionEntity session,
    BoatEntity? boat,
    List<GpsPointEntity> points,
    List<RangeMeasurementEntity> rangeMeasurements,
    String trainingId,
  ) async {
    await _ensureSignedIn();

    final uploadId = const Uuid().v5(
      Namespace.url.value,
      '${session.id}/$trainingId',
    );

    await supabaseClient.from('session_uploads').upsert({
      'id': uploadId,
      'training_id': trainingId,
      'name': session.name,
      'start_time': session.startTime.toUtc().toIso8601String(),
      'end_time': session.endTime?.toUtc().toIso8601String(),
      'distance': session.distance,
      'wind_direction': session.windDirection,
      'boat_name': boat?.name,
      'sail_number': boat?.sailNumber,
      'boat_class': boat?.boatClass,
    });

    for (var i = 0; i < points.length; i += _batchSize) {
      final batch = points.sublist(i, min(i + _batchSize, points.length));
      await supabaseClient
        .from('gps_points')
        .upsert(
          batch.asMap().entries.map((entry) {
            final p = entry.value;
            return {
              'id': const Uuid().v5(
                Namespace.url.value,
                '$uploadId/${i + entry.key}',
              ),
              'upload_id': uploadId,
              'timestamp': p.timestamp.toUtc().toIso8601String(),
              'lat': p.lat,
              'lon': p.lon,
              'sog': p.sog,
              'cog': p.cog,
              'heel': p.heel,
              'pitch': p.pitch,
              'mag_heading': p.magHeading,
              'accuracy': p.accuracy,
            };
          }).toList(),
        );
    }
    await uploadRangeMeasurements(uploadId, rangeMeasurements);
  }

  Future<void> uploadRangeMeasurements(
  String uploadId,
  List<RangeMeasurementEntity> measurements,
) async {
  for (var i = 0; i < measurements.length; i += _batchSize) {
    final batch = measurements.sublist(i, min(i + _batchSize, measurements.length));
    await supabaseClient.from('range_measurements').upsert(
      batch.map((m) => {
        'id': m.id,
        'upload_id': uploadId,
        'peer_id': m.peerId,
        'tech': m.tech,
        'rssi': m.rssi,
        'timestamp': m.timestamp.toUtc().toIso8601String(),
      }).toList(),
    );
  }
}
}

class ResolvedTraining {
  final String id;
  final String name;
  final bool isOpen;

  const ResolvedTraining({
    required this.id,
    required this.name,
    required this.isOpen,
  });
}
