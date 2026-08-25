import 'dart:io';

import 'package:flutter/foundation.dart';
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

class BLEService {
  static Future<bool> requestPermission() async {
    // 1️ App-Permissions checken (das was du machen musst)
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
    ].request();

    if (!statuses.values.every((s) => s.isGranted)) {
      //Bluetooth permissions denied"
      return false;
    }

    // 2️ Device-Level: Ist Bluetooth an?
    if (await FlutterBluePlus.isSupported == false) {
      //Bluetooth not supported
      return false;
    }

    // Optional: Bluetooth an, wenn aus
    if (!kIsWeb && Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    return true;
  }

  // ownerPeerId = die Segelnummer deines Boots (z. B. "GER1775")
  static Stream<BleAdvertisement> startScan(String ownerPeerId) {
    return FlutterBluePlus.onScanResults
        .expand((results) => results)
        .where((r) => r.advertisementData.manufacturerData.containsKey(0xFFFF))
        .map((r) {
          final bytes = r.advertisementData.manufacturerData[0xFFFF]!;
          return BleAdvertisement(
            peerId: String.fromCharCodes(bytes),
            rssi: r.rssi,
            timestamp: DateTime.now(),
          );
        })
        .where((advertisement) => advertisement.peerId != ownerPeerId);
  }

  static Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }
}
