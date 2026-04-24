import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rfid/rfid.dart';

import 'home_page.dart';
import 'l10n.dart';

/// 连接方式枚举 / Connection mode
enum ConnMode { integrated, bleScan, bleManual }

/// 连接页：支持一体机直连 / BLE 扫描 / 手动输入 MAC
class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _rfid = Rfid();

  ConnMode _mode = ConnMode.integrated;

  final List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanResultsSub;

  final _macCtrl = TextEditingController();

  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off && _isScanning) {
        FlutterBluePlus.stopScan();
        if (mounted) setState(() => _isScanning = false);
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSub?.cancel();
    _macCtrl.dispose();
    super.dispose();
  }

  Future<void> _releaseBleBeforeRfidSdk(String mac) async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await _scanResultsSub?.cancel();
    _scanResultsSub = null;
    final macNorm = mac.replaceAll(':', '').toUpperCase();
    try {
      for (final d in FlutterBluePlus.connectedDevices) {
        final idNorm = d.remoteId.str.replaceAll(':', '').toUpperCase();
        if (idNorm == macNorm) {
          try {
            await d.disconnect();
          } catch (_) {}
          await Future<void>.delayed(const Duration(milliseconds: 250));
          break;
        }
      }
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> _connectIntegrated() async {
    if (_isConnecting) return;
    setState(() => _isConnecting = true);
    try {
      final ret = await _rfid.initSdk();
      if (!mounted) return;
      if (ret == 0) {
        _navigateHome('UART');
      } else {
        _showSnack('${context.l10n.connectFailed}: $ret');
      }
    } catch (e) {
      if (mounted) _showSnack('${context.l10n.initFailed}: $e');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _connectManualMac() async {
    final mac = _macCtrl.text.trim();
    if (mac.isEmpty) {
      _showSnack(context.l10n.enterMac);
      return;
    }
    await _connectBle(mac);
  }

  Future<void> _startScan() async {
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _showSnack(context.l10n.enableBluetooth);
      return;
    }
    setState(() {
      _scanResults.clear();
      _isScanning = true;
    });
    await _scanResultsSub?.cancel();
    _scanResultsSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        for (final r in results) {
          final idx = _scanResults
              .indexWhere((e) => e.device.remoteId == r.device.remoteId);
          if (idx >= 0) {
            _scanResults[idx] = r;
          } else {
            _scanResults.add(r);
          }
        }
      });
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _selectDevice(ScanResult r) async {
    if (_isScanning) {
      await FlutterBluePlus.stopScan();
      if (mounted) setState(() => _isScanning = false);
    }
    await _connectBle(r.device.remoteId.str);
  }

  Future<void> _connectBle(String mac) async {
    if (_isConnecting) return;
    setState(() => _isConnecting = true);
    try {
      await _releaseBleBeforeRfidSdk(mac);
      if (!mounted) return;
      final ret = await _rfid
          .initSdkBle(mac)
          .timeout(const Duration(seconds: 45));
      if (!mounted) return;
      if (ret == 0) {
        _navigateHome(mac);
      } else {
        _showSnack('${context.l10n.connectFailed}: $ret');
      }
    } on TimeoutException {
      if (mounted) _showSnack(context.l10n.connectTimeout);
    } catch (e) {
      if (mounted) _showSnack('${context.l10n.initFailed}: $e');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _navigateHome(String label) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomePage(rfid: _rfid, mac: label),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.connectTitle),
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isConnecting
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(context.l10n.connecting),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SegmentedButton<ConnMode>(
                    segments: [
                      ButtonSegment(
                        value: ConnMode.integrated,
                        icon: const Icon(Icons.usb),
                        label: Text(context.l10n.modeIntegrated),
                      ),
                      ButtonSegment(
                        value: ConnMode.bleScan,
                        icon: const Icon(Icons.bluetooth_searching),
                        label: Text(context.l10n.modeBleScan),
                      ),
                      ButtonSegment(
                        value: ConnMode.bleManual,
                        icon: const Icon(Icons.edit),
                        label: Text(context.l10n.modeManual),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) {
                      setState(() {
                        _mode = s.first;
                        _scanResults.clear();
                      });
                    },
                  ),
                ),
                const Divider(height: 24),
                Expanded(child: _buildModeBody()),
              ],
            ),
    );
  }

  Widget _buildModeBody() {
    switch (_mode) {
      case ConnMode.integrated:
        return _buildIntegratedBody();
      case ConnMode.bleScan:
        return _buildBleScanBody();
      case ConnMode.bleManual:
        return _buildBleManualBody();
    }
  }

  Widget _buildIntegratedBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.usb, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              context.l10n.integratedDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _connectIntegrated,
              icon: const Icon(Icons.link),
              label: Text(context.l10n.connect),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBleScanBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(context.l10n.devicesFound(_scanResults.length),
                  style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              FilledButton.icon(
                onPressed: _isScanning ? null : _startScan,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(_isScanning ? context.l10n.scanning : context.l10n.scan),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: _scanResults.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = _scanResults[i];
              final name = r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : context.l10n.unknown;
              return ListTile(
                leading: const Icon(Icons.bluetooth),
                title: Text(name),
                subtitle: Text(r.device.remoteId.str),
                trailing: Text('${r.rssi} dBm',
                    style: Theme.of(context).textTheme.bodySmall),
                onTap: () => _selectDevice(r),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBleManualBody() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_note, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          TextField(
            controller: _macCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.macHint,
              hintText: 'AA:BB:CC:DD:EE:FF',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.bluetooth),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _connectManualMac,
            icon: const Icon(Icons.link),
            label: Text(context.l10n.connect),
          ),
        ],
      ),
    );
  }
}
