import 'dart:developer' as dev;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/services/ble_service.dart';

class BleState {
  final bool isScanning;
  final bool isAdvertising;
  final int eventsPerSecond;
  final Map<String, BleAdvertisement> lastAdvertisements;
  final String? error;

  const BleState({
    this.isScanning = false,
    this.isAdvertising = false,
    this.eventsPerSecond = 0,
    this.lastAdvertisements = const {},
    this.error,
  });

  BleState copyWith({
    bool? isScanning,
    bool? isAdvertising,
    int? eventsPerSecond,
    Map<String, BleAdvertisement>? lastAdvertisements,
    String? error,
  }) {
    return BleState(
      isScanning: isScanning ?? this.isScanning,
      isAdvertising: isAdvertising ?? this.isAdvertising,
      eventsPerSecond: eventsPerSecond ?? this.eventsPerSecond,
      lastAdvertisements: lastAdvertisements ?? this.lastAdvertisements,
      error: error ?? this.error,
    );
  }
}

class BleStateNotifier extends StateNotifier<BleState> {
  final BleService _service;

  BleStateNotifier(this._service) : super(const BleState()) {
    // Scan Results Handler
    _service.onScanResults = _onScanResults;
  }

  void _onScanResults(List<ScanResult> results) {
    final now = DateTime.now();
    final updated = <String, BleAdvertisement>{...state.lastAdvertisements};

    for (final r in results) {
      final payload = r.advertisementData.manufacturerData[0xFFFF];
      if (payload == null) continue;

      final peerId = String.fromCharCodes(payload);
      updated[peerId] = BleAdvertisement(
        peerId: peerId,
        rssi: r.rssi,
        timestamp: now,
      );
    }

    state = state.copyWith(
      lastAdvertisements: updated,
      eventsPerSecond: _service.eventsPerSecond,
    );
  }

  Future<void> startAdvertising(String sailNumber) async {
    try {
      await _service.startAdvertising(sailNumber);
      state = state.copyWith(isAdvertising: true, error: null);
    } catch (e) {
      dev.log('❌ startAdvertising failed: $e', error: e);
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await _service.stopAdvertising();
      state = state.copyWith(isAdvertising: false, error: null);
    } catch (e) {
      dev.log('❌ stopAdvertising failed: $e', error: e);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> startScanning() async {
    try {
      await _service.startScanning();
      state = state.copyWith(isScanning: true, error: null);
    } catch (e) {
      dev.log('❌ startScanning failed: $e', error: e);
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> stopScanning() async {
    try {
      await _service.stopScanning();
      state = state.copyWith(
        isScanning: false,
        lastAdvertisements: {},
        eventsPerSecond: 0,
        error: null,
      );
    } catch (e) {
      dev.log('❌ stopScanning failed: $e', error: e);
      state = state.copyWith(error: e.toString());
    }
  }
}

final bleServiceProvider = Provider((ref) => BleService());

final bleStateProvider = StateNotifierProvider<BleStateNotifier, BleState>((ref) {
  return BleStateNotifier(ref.watch(bleServiceProvider));
});
