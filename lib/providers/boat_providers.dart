// lib/providers/boat_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/data/entities/boat.dart';
import 'package:sailing_analytics/providers/repository_providers.dart';

final activeBoatProvider = StreamProvider<BoatEntity?>((ref) {
  return ref.watch(boatRepositoryProvider).watchActiveBoat();
});

final boatsProvider = StreamProvider<List<BoatEntity>>((ref) {
  return ref.watch(boatRepositoryProvider).watchBoats();
});
