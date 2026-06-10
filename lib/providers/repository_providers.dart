// lib/providers/repository_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/data/services/gps_service.dart';
import 'package:sailing_analytics/data/services/gpx_export_service.dart';
import '../data/repositories/boat_repository.dart';
import '../data/database/app_database.dart';
import '../data/repositories/session_repository.dart';

// Database singleton — one instance for the whole app lifetime
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close); // close cleanly when app exits
  return db;
});

// Repository — depends on database
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(databaseProvider));
});

final boatRepositoryProvider = Provider<BoatRepository>((ref) {
  return BoatRepository(ref.watch(databaseProvider));
});

//Services - one per hardware source
final gpsServiceProvider = Provider<GpsService>((ref) {
  return GpsService();
});

// Pure string builder — no state, no hardware
final gpxExportServiceProvider = Provider<GpxExportService>((ref) {
  return GpxExportService();
});

//sensor service
