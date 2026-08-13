// SPIKE — Wegwerf-UI für den BLE-Ranging-Test. Siehe ble_spike_controller.dart.
import 'package:flutter/material.dart';
import 'package:sailing_analytics/ble-spike/ble_spike_controller.dart';

class BleSpikeScreen extends StatefulWidget {
  const BleSpikeScreen({super.key});

  @override
  State<BleSpikeScreen> createState() => _BleSpikeScreenState();
}

class _BleSpikeScreenState extends State<BleSpikeScreen> {
  final _controller = BleSpikeController();
  late final TextEditingController _labelField;
  bool _permissionsOk = false;

  @override
  void initState() {
    super.initState();
    _labelField = TextEditingController();
    _requestPermissions();
    _loadSailNumber();
  }

  Future<void> _loadSailNumber() async {
    // Keine Riverpod Abhängigkeit im Spike — einfach hardcoded für jetzt
    // Im produktiven Code würde das von BoatRepository kommen
    // TODO: später an echte Boot-Daten koppeln
    _controller.setSailNumber('Boat');
  }

  Future<void> _requestPermissions() async {
    final ok = await _controller.requestPermissions();
    if (mounted) setState(() => _permissionsOk = ok);
  }

  @override
  void dispose() {
    _controller.dispose();
    _labelField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Spike'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Log leeren',
            onPressed: _controller.clearLog,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'CSV exportieren',
            onPressed: () => _controller.exportCsv(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final peers = _controller.seenDevices.values
              .where((d) => d.isPeer)
              .toList();
          final others = _controller.seenDevices.values
              .where((d) => !d.isPeer)
              .toList()
            ..sort((a, b) => b.rssi.compareTo(a.rssi));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!_permissionsOk)
                Card(
                  color: Colors.red.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Bluetooth-Permissions fehlen.'),
                        ),
                        TextButton(
                          onPressed: _requestPermissions,
                          child: const Text('Erneut anfragen'),
                        ),
                      ],
                    ),
                  ),
                ),

              // ---- Konfiguration ----
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meine ID', style: Theme.of(context).textTheme.labelMedium),
                      Text(
                        _controller.myId,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _labelField,
                decoration: const InputDecoration(
                  labelText: 'Mess-Label (z. B. 10m_quer) — steht in jeder CSV-Zeile',
                ),
                onChanged: (v) => _controller.label = v,
              ),
              const SizedBox(height: 16),

              // ---- Start/Stop ----
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _permissionsOk
                          ? () => _controller.isAdvertising
                              ? _controller.stopAdvertising()
                              : _controller.startAdvertising()
                          : null,
                      child: Text(
                        _controller.isAdvertising
                            ? 'Advertising stoppen'
                            : 'Advertising starten',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _permissionsOk
                          ? () => _controller.isScanning
                              ? _controller.stopScanning()
                              : _controller.startScanning()
                          : null,
                      child: Text(
                        _controller.isScanning
                            ? 'Scan stoppen'
                            : 'Scan starten',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---- Status ----
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peer-Events/s: ${_controller.eventsPerSecond}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('Log-Einträge: ${_controller.log.length}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ---- Spike-Peers ----
              Text('Spike-Peers', style: Theme.of(context).textTheme.titleMedium),
              if (peers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Noch keine Peers gehört.'),
                ),
              for (final d in peers)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.sailing, color: Colors.blue),
                  title: Text(d.peerId!),
                  subtitle: Text(
                    'zuletzt ${_ago(d.lastSeen)} · ${d.remoteId}',
                  ),
                  trailing: Text(
                    '${d.rssi} dBm',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              const Divider(height: 32),

              // ---- Fremde Geräte (Beweis, dass der Scan grundsätzlich läuft) ----
              Text(
                'Andere BLE-Geräte (${others.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final d in others.take(15))
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.bluetooth, color: Colors.grey),
                  title: Text(d.name.isEmpty ? '(ohne Name)' : d.name),
                  subtitle: Text(d.remoteId),
                  trailing: Text('${d.rssi} dBm'),
                ),
            ],
          );
        },
      ),
    );
  }

  String _ago(DateTime t) {
    final ms = DateTime.now().difference(t).inMilliseconds;
    return ms < 1500 ? 'gerade eben' : 'vor ${(ms / 1000).toStringAsFixed(0)} s';
  }
}
