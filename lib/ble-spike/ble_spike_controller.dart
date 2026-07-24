// SPIKE — Wegwerf-Code für den BLE-Ranging-Test (BA-Vorarbeit).
// Kein Riverpod, keine DB: bewusst simpel gehalten, fliegt nach dem Spike raus.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

/// 0xFFFF ist von der Bluetooth SIG für interne Tests reserviert —
/// genau richtig für den Spike. Scanner erkennt Peers an dieser ID.
const int kSpikeManufacturerId = 0xFFFF;

/// Ein empfangenes Advertisement eines Spike-Peers = ein Messpunkt.
class RangeEvent {
  final DateTime timestamp;
  final String peerId;
  final int rssi;
  final String label;

  RangeEvent(this.timestamp, this.peerId, this.rssi, this.label);
}

/// Anzeige-Info pro gehörtem Gerät (Peers und Fremdgeräte).
class SeenDevice {
  final String remoteId;
  final String name;
  final String? peerId; // nur gesetzt wenn es ein Spike-Peer ist
  int rssi;
  DateTime lastSeen;

  SeenDevice({
    required this.remoteId,
    required this.name,
    required this.peerId,
    required this.rssi,
    required this.lastSeen,
  });

  bool get isPeer => peerId != null;
}

class BleSpikeController extends ChangeNotifier {
  final _peripheral = FlutterBlePeripheral();

  bool isAdvertising = false;
  bool isScanning = false;

  /// Eigene Kennung im Advertisement (z. B. "P7P"). Vor dem Start setzen.
  String myId = 'P7P';

  /// Frei wählbares Label, wird in jede Logzeile geschrieben
  /// (z. B. "10m_quer" beim Landtest).
  String label = '';

  /// Alle gehörten Geräte, Key = remoteId (Achtung: MACs sind randomisiert,
  /// Peers identifizieren wir deshalb über die Manufacturer-Data, nie über die MAC).
  final Map<String, SeenDevice> seenDevices = {};

  /// Das eigentliche Messlog — nur Spike-Peers landen hier.
  final List<RangeEvent> log = [];

  /// Events/Sekunde von Peers (rollierend über 1 s), die Kernmetrik des Spikes.
  int eventsPerSecond = 0;
  int _eventCounter = 0;

  StreamSubscription<List<ScanResult>>? _scanSub;
  Timer? _rateTimer;

  /// Muss vor Advertise/Scan einmal durchlaufen. Gibt false zurück,
  /// wenn der User etwas abgelehnt hat.
  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  // ---------- Advertising (Beacon-Rolle) ----------

  Future<void> startAdvertising() async {
    await _peripheral.start(
      advertiseData: AdvertiseData(
        manufacturerId: kSpikeManufacturerId,
        manufacturerData: Uint8List.fromList(ascii.encode(myId)),
      ),
      advertiseSettings: AdvertiseSettings(
        // Legacy-Advertising: am breitesten unterstützt
        advertiseSet: false,
        // 0 = kein Timeout. Default wäre 400 ms — dann wäre nach einer
        // halben Sekunde Schluss!
        timeout: 0,
        // ~10 Advertisements/s statt ~1/s — unsere Messrate
        advertiseMode: AdvertiseMode.advertiseModeLowLatency,
        // volle Sendeleistung = maximale Reichweite. Messparameter der BA!
        txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      ),
    );
    isAdvertising = true;
    notifyListeners();
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stop();
    isAdvertising = false;
    notifyListeners();
  }

  // ---------- Scanning (Empfänger-Rolle) ----------

  Future<void> startScanning() async {
    // Warten bis der Adapter wirklich an ist, sonst scannt man ins Leere
    await FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on)
        .first;

    _scanSub = FlutterBluePlus.onScanResults.listen(_onScanResults);

    await FlutterBluePlus.startScan(
      // jedes einzelne Advertisement als eigenes Event — wir wollen
      // Messpunkte, nicht eine deduplizierte Geräteliste
      oneByOne: true,
      androidScanMode: AndroidScanMode.lowLatency,
      // wir nutzen RSSI zur Ortung, also ehrlich deklarieren
      androidUsesFineLocation: true,
      // kein timeout: läuft bis stopScanning()
    );

    _rateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      eventsPerSecond = _eventCounter;
      _eventCounter = 0;
      notifyListeners();
    });

    isScanning = true;
    notifyListeners();
  }

  Future<void> stopScanning() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    _rateTimer?.cancel();
    _rateTimer = null;
    eventsPerSecond = 0;
    _eventCounter = 0;
    isScanning = false;
    notifyListeners();
  }

  void _onScanResults(List<ScanResult> results) {
    final now = DateTime.now();

    // Mit oneByOne enthält die Liste genau ein Ergebnis
    for (final r in results) {
      final msd = r.advertisementData.manufacturerData;
      final payload = msd[kSpikeManufacturerId];
      final peerId = payload == null ? null : ascii.decode(payload);

      seenDevices[r.device.remoteId.str] = SeenDevice(
        remoteId: r.device.remoteId.str,
        name: r.advertisementData.advName,
        peerId: peerId,
        rssi: r.rssi,
        lastSeen: now,
      );

      // nur Spike-Peers sind Messpunkte
      if (peerId != null) {
        log.add(RangeEvent(now, peerId, r.rssi, label));
        _eventCounter++;
      }
    }
    notifyListeners();
  }

  // ---------- Export ----------

  Future<void> exportCsv() async {
    final buffer = StringBuffer('timestamp,label,my_id,peer_id,rssi\n');
    for (final e in log) {
      buffer.writeln(
        '${e.timestamp.toIso8601String()},${e.label},$myId,${e.peerId},${e.rssi}',
      );
    }

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(':', '-');
    final file = File('${dir.path}/ble_spike_${myId}_$stamp.csv');
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'text/csv')]),
    );
  }

  void clearLog() {
    log.clear();
    seenDevices.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    if (isScanning) stopScanning();
    if (isAdvertising) stopAdvertising();
    super.dispose();
  }
}
