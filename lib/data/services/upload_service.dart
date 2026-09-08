import 'dart:developer' as dev;
import 'dart:math';

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
    dev.log(
      '📤 UPLOAD START: ${points.length} GPS points, ${rangeMeasurements.length} measurements',
    );
    await _ensureSignedIn();
    dev.log('✅ Supabase auth ensured');

    final uploadId = const Uuid().v5(
      Namespace.url.value,
      '${session.id}/$trainingId',
    );

    final currentUserId = supabaseClient.auth.currentUser?.id;

    await supabaseClient.from('session_uploads').upsert({
      'id': uploadId,
      'session_id': session.id,
      'training_id': trainingId,
      'name': session.name,
      'start_time': session.startTime.toUtc().toIso8601String(),
      'end_time': session.endTime?.toUtc().toIso8601String(),
      'distance': session.distance,
      'wind_direction': session.windDirection,
      'boat_name': boat?.name,
      'sail_number': boat?.sailNumber,
      'boat_class': boat?.boatClass,
      'uploader_id': currentUserId,
    });

    // Upload GPS points in batches
    dev.log('📤 Uploading GPS points (${points.length} total)...');
    for (var i = 0; i < points.length; i += _batchSize) {
      final batch = points.sublist(i, min(i + _batchSize, points.length));
      dev.log(
        '  📦 Batch ${i ~/ _batchSize + 1}/${(points.length / _batchSize).ceil()}: ${batch.length} points',
      );
      await supabaseClient
          .from('gps_points')
          .upsert(
            batch.asMap().entries.map((entry) {
              final p = entry.value;
              return {
                'id': p.id,
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
      dev.log('  ✅ Batch uploaded');
    }
    dev.log('✅ All GPS points uploaded');

    // Upload range measurements
    dev.log(
      '📤 Uploading RangeMeasurements (${rangeMeasurements.length} total)...',
    );

    for (var i = 0; i < rangeMeasurements.length; i += _batchSize) {
      final batch = rangeMeasurements.sublist(
        i,
        min(i + _batchSize, rangeMeasurements.length),
      );
      dev.log(
        '  📦 Batch ${i ~/ _batchSize + 1}/${(rangeMeasurements.length / _batchSize).ceil()}: ${batch.length} measurements',
      );
      await supabaseClient
          .from('range_measurements')
          .upsert(
            batch.asMap().entries.map((entry) {
              final p = entry.value;
              return {
                'id': p.id,
                'upload_id': uploadId,
                'gps_point_id': p.gpsPointId,
                'peer_id': p.peerId,
                'tech': p.tech,
                'rssi': p.rssi,
                'distance': p.distance,
                'quality': p.quality,
                'timestamp': p.timestamp.toUtc().toIso8601String(),
              };
            }).toList(),
          );
      dev.log('  ✅ Batch uploaded');
    }
    dev.log('✅ All RangeMeasurements uploaded');
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
