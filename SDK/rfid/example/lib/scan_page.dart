import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rfid/rfid.dart';

import 'l10n.dart';

/// 盘存页：连续盘存 / 单次盘存，实时展示标签列表
class ScanPage extends StatefulWidget {
  final Rfid rfid;
  const ScanPage({super.key, required this.rfid});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  // epc -> {EPC, TID, RSSI, BID, count}
  final Map<String, Map<String, dynamic>> _tags = {};
  StreamSubscription? _sub;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _sub = Rfid.rawEventStream.listen(_onEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    if (_scanning) widget.rfid.stopInventory();
    super.dispose();
  }

  void _onEvent(Map<Object?, Object?> event) {
    final type = event['eventType'] as String?;
    if (type == 'event_inventory_tag') {
      final data = Map<String, dynamic>.from(event['data'] as Map);
      final epc = data['EPC'] as String? ?? '';
      if (!mounted) return;
      setState(() {
        if (_tags.containsKey(epc)) {
          _tags[epc]!['count'] = (_tags[epc]!['count'] as int) + 1;
          _tags[epc]!['RSSI'] = data['RSSI'];
        } else {
          _tags[epc] = {...data, 'count': 1};
        }
      });
    } else if (type == 'event_inventory_tag_end') {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _toggleContinuous() async {
    if (_scanning) {
      await widget.rfid.stopInventory();
      setState(() => _scanning = false);
    } else {
      setState(() {
        _tags.clear();
        _scanning = true;
      });
      await widget.rfid.startInventory();
    }
  }

  Future<void> _singleScan() async {
    setState(() => _tags.clear());
    await widget.rfid.inventorySingle();
  }

  @override
  Widget build(BuildContext context) {
    final tagList = _tags.values.toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _toggleContinuous,
                  icon: Icon(_scanning ? Icons.stop : Icons.play_arrow),
                  label: Text(_scanning
                      ? context.l10n.stopInventory
                      : context.l10n.startInventory),
                  style: _scanning
                      ? FilledButton.styleFrom(backgroundColor: Colors.red)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _scanning ? null : _singleScan,
                icon: const Icon(Icons.looks_one),
                label: Text(context.l10n.singleScan),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() => _tags.clear()),
                icon: const Icon(Icons.delete_outline),
                label: Text(context.l10n.clear),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(context.l10n.totalTags(tagList.length),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: tagList.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final t = tagList[i];
              return ListTile(
                dense: true,
                title: Text(
                  t['EPC'] as String? ?? '',
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 13),
                ),
                subtitle: Text(
                  context.l10n.tagSubtitle(
                    '${t['TID'] ?? ''}',
                    '${t['RSSI'] ?? ''}',
                    '${t['BID'] ?? ''}',
                  ),
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  '×${t['count']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
