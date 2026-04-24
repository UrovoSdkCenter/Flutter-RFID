import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rfid/rfid.dart';

import 'connect_page.dart';
import 'l10n.dart';
import 'scan_page.dart';
import 'read_write_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final Rfid rfid;
  final String mac;

  const HomePage({super.key, required this.rfid, required this.mac});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;

  /// 递增后 [SettingsPage] 会再次 [_SettingsPageState._loadAll]，避免连接刚成功时首帧拉取失败。
  int _settingsRefreshGen = 0;

  /// 已在 [_disconnect] 中调用 [Rfid.releaseSdk] 后置位，避免 [dispose] 重复释放。
  bool _sdkReleased = false;
  bool _disconnecting = false;

  StreamSubscription<Map<Object?, Object?>>? _linkSub;

  @override
  void initState() {
    super.initState();
    _linkSub = Rfid.rawEventStream.listen((Map<Object?, Object?> e) {
      if (e['eventType'] != 'event_connection') return;
      final raw = e['data'];
      if (raw is! Map) return;
      final connected = raw['connected'] == true;
      if (!mounted) return;
      if (connected) {
        setState(() {});
        return;
      }
      if (_sdkReleased || _disconnecting) return;
      setState(() {});
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null && mounted) {
        messenger.showSnackBar(SnackBar(content: Text(context.l10n.linkLost)));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _settingsRefreshGen++);
    });
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _settingsRefreshGen++);
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    if (!_sdkReleased) {
      widget.rfid.releaseSdk();
    }
    super.dispose();
  }

  Future<void> _disconnect() async {
    if (_disconnecting || _sdkReleased) return;
    setState(() => _disconnecting = true);
    try {
      await widget.rfid.releaseSdk();
    } catch (_) {
      // 仍返回连接页以便换方式重试；dispose 不再二次 release
    }
    _sdkReleased = true;
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ConnectPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pages = <Widget>[
      ScanPage(rfid: widget.rfid),
      ReadWritePage(rfid: widget.rfid),
      SettingsPage(
        rfid: widget.rfid,
        refreshGeneration: _settingsRefreshGen,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.homeAppBarTitle(widget.mac)),
        actions: [
          FutureBuilder<bool>(
            future: widget.rfid.isConnected(),
            builder: (_, snap) {
              final ok = snap.data ?? false;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.circle, size: 14,
                    color: ok ? Colors.green : Colors.red),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.link_off),
            tooltip: l.disconnect,
            onPressed: _disconnecting ? null : _disconnect,
          ),
        ],
      ),
      body: IndexedStack(index: _tabIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) {
          setState(() {
            _tabIndex = i;
            if (i == 2) _settingsRefreshGen++;
          });
        },
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.wifi_tethering), label: l.tabInventory),
          NavigationDestination(
              icon: const Icon(Icons.edit_note), label: l.tabReadWrite),
          NavigationDestination(
              icon: const Icon(Icons.settings), label: l.tabSettings),
        ],
      ),
    );
  }
}
