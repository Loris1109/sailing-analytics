import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleAdvertisement {
  final String peerId;
  final int rssi;
  final DateTime timestamp;

  BleAdvertisement({
    required this.peerId,
    required this.rssi,
    required this.timestamp,
  });
}

class BleService {
  // Callbacks für Scan-Results
  Function(List<ScanResult>)? onScanResults;
  final peripheral = FlutterBlePeripheral();
  final manufacturerID = 0xFFFF;

  // State
  StreamSubscription? _scanSub;
  Timer? _rateTimer;
  int _eventCounter = 0;
  int eventsPerSecond = 0;
  bool isScanning = false;
  bool isAdvertising = false;

  static Future<bool> requestPermission() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
    ].request();

    if (!statuses.values.every((s) => s.isGranted)) {
      dev.log('❌ BLE permission denied');
      return false;
    }

    if (await FlutterBluePlus.isSupported == false) {
      dev.log('❌ BLE not supported');
      return false;
    }

    if (!kIsWeb && Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    return true;
  }

  // ─── Advertising ───────────────────────────────────────────
  Future<void> startAdvertising(String sailNumber) async {
    dev.log('🚀 BLE Advertising STARTING: $sailNumber');
    try {
      final list = utf8.encode(sailNumber);
      final payload = Uint8List.fromList(list);
      dev.log('  Payload: ${list.length} bytes = $sailNumber');

      await peripheral.start(
        advertiseData: AdvertiseDataCore(
          manufacturerId: manufacturerID,
          manufacturerData: payload,
        ),
        androidSettings: AndroidAdvertiseSettings(
          advertiseSettings: AdvertiseSettings(
            advertiseMode: AdvertiseMode.advertiseModeLowLatency,
            txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
            timeout: 0,
         ),
        ),
      );
      isAdvertising = true;
      dev.log('✅ BLE Advertising STARTED: $sailNumber');
    } catch (e) {
      dev.log('❌ BLE Advertising FAILED: $e', error: e);
      rethrow;
    }
  }

  Future<void> stopAdvertising() async {
    dev.log('⏹️ BLE Advertising STOPPING');
    try {
      await peripheral.stop();
      isAdvertising = false;
      dev.log('✅ BLE Advertising STOPPED');
    } catch (e) {
      dev.log('⚠️ Error stopping advertising: $e', error: e);
    }
  }

  // ─── Scanning ──────────────────────────────────────────────
  Future<void> startScanning() async {
    dev.log('🔍 BLE Scan STARTING');

    // Warten bis Adapter wirklich AN ist
    dev.log('  Waiting for Bluetooth adapter to be ON...');
    await FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on)
        .first;
    dev.log('  ✅ Bluetooth adapter is ON');

    // Listener registrieren BEVOR startScan()
    _scanSub = FlutterBluePlus.onScanResults.listen(_onScanResults);

    // Jetzt startScan()
    dev.log('  Starting FlutterBluePlus.startScan()...');
    await FlutterBluePlus.startScan(
      withMsd: [MsdFilter(manufacturerID)],
      continuousUpdates: true,
      oneByOne: true,
      androidScanMode: AndroidScanMode.lowLatency,
      androidUsesFineLocation: true,
    );

    // Rate Timer starten
    _rateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      eventsPerSecond = _eventCounter;
      _eventCounter = 0;
    });

    isScanning = true;
    dev.log('✅ BLE Scan STARTED');
  }

  Future<void> stopScanning() async {
    dev.log('⏹️ BLE Scan STOPPING');
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    _rateTimer?.cancel();
    _rateTimer = null;
    eventsPerSecond = 0;
    _eventCounter = 0;
    isScanning = false;
    dev.log('✅ BLE Scan STOPPED');
  }

  void _onScanResults(List<ScanResult> results) {
    if (results.isEmpty) return;

    dev.log('  📡 Raw scan results: ${results.length} devices');
    // Filter & zähle
    final filtered = <ScanResult>[];
    for (final r in results) {
      if (r.advertisementData.manufacturerData.containsKey(manufacturerID)) {
        final bytes = r.advertisementData.manufacturerData[manufacturerID]!;
        final peerId = String.fromCharCodes(bytes);
        dev.log('📡 BLE Advertisement RECEIVED: $peerId (RSSI: ${r.rssi}dBm)');
        filtered.add(r);
        _eventCounter++;
      }
    }

    // Callback aufrufen
    if (filtered.isNotEmpty) {
      onScanResults?.call(filtered);
    }
  }
}
