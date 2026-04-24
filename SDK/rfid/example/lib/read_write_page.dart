import 'package:flutter/material.dart';
import 'package:rfid/rfid.dart';

import 'l10n.dart';

/// 读写页：读标签 / 写标签 / 写EPC / 点亮LED
class ReadWritePage extends StatefulWidget {
  final Rfid rfid;
  const ReadWritePage({super.key, required this.rfid});

  @override
  State<ReadWritePage> createState() => _ReadWritePageState();
}

class _ReadWritePageState extends State<ReadWritePage> {
  final _epcCtrl     = TextEditingController();
  final _pwdCtrl     = TextEditingController(text: '00000000');
  final _newEpcCtrl  = TextEditingController();
  final _writeDataCtrl = TextEditingController();

  // 读参数
  int _readMemBank = 1; // 0=Reserved 1=EPC 2=TID 3=User
  int _wordAdd = 0;
  int _wordCnt = 6;

  // 写参数
  int _writeMemBank = 1;
  int _writeWordAdd = 0;

  String _result = '';
  bool _busy = false;

  void _setResult(String r) {
    if (mounted) setState(() => _result = r);
  }

  Future<void> _readTag() async {
    setState(() => _busy = true);
    try {
      final r = await widget.rfid.readTag(
        epc: _epcCtrl.text.isEmpty ? null : _epcCtrl.text,
        memBank: _readMemBank,
        wordAdd: _wordAdd,
        wordCnt: _wordCnt,
        password: _pwdCtrl.text.isEmpty ? null : _pwdCtrl.text,
      );
      _setResult(context.l10n.readTagResult(r.code, r.data));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _writeTag() async {
    if (_writeDataCtrl.text.isEmpty) {
      _setResult(context.l10n.enterWriteData);
      return;
    }
    setState(() => _busy = true);
    try {
      final ret = await widget.rfid.writeTag(
        epc: _epcCtrl.text.isEmpty ? null : _epcCtrl.text,
        password: _pwdCtrl.text.isEmpty ? null : _pwdCtrl.text,
        memBank: _writeMemBank,
        wordAdd: _writeWordAdd,
        data: _writeDataCtrl.text,
      );
      _setResult('${context.l10n.write}: $ret');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _writeEpc() async {
    if (_newEpcCtrl.text.isEmpty) {
      _setResult(context.l10n.enterNewEpc);
      return;
    }
    setState(() => _busy = true);
    try {
      final ret = await widget.rfid.writeTagEpc(
        epc: _epcCtrl.text.isEmpty ? null : _epcCtrl.text,
        password: _pwdCtrl.text.isEmpty ? null : _pwdCtrl.text,
        newEpc: _newEpcCtrl.text,
      );
      _setResult('${context.l10n.writeEpc}: $ret');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _lightUp() async {
    setState(() => _busy = true);
    try {
      final ret = await widget.rfid.lightUpLedTag(
        epc: _epcCtrl.text.isEmpty ? null : _epcCtrl.text,
        password: _pwdCtrl.text.isEmpty ? null : _pwdCtrl.text,
      );
      _setResult('${context.l10n.lightLed}: $ret');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _epcCtrl.dispose();
    _pwdCtrl.dispose();
    _newEpcCtrl.dispose();
    _writeDataCtrl.dispose();
    super.dispose();
  }

  String _memBankDisplayName(AppLocalizations l, int i) {
    switch (i) {
      case 0:
        return l.memReserved;
      case 1:
        return l.memEpc;
      case 2:
        return l.memTid;
      case 3:
        return l.memUser;
      default:
        return '$i';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 公共参数 ──────────────────────────────────────────────────────
          _SectionTitle(l.commonParams),
          TextField(
            controller: _epcCtrl,
            decoration: InputDecoration(
                labelText: l.epcFilter,
                border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pwdCtrl,
            decoration: InputDecoration(
                labelText: l.password8hex,
                border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          // ── 读标签 ────────────────────────────────────────────────────────
          _SectionTitle(l.readTag),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _readMemBank,
                decoration: InputDecoration(
                    labelText: l.memBankLabel,
                    border: const OutlineInputBorder()),
                items: List.generate(
                  4,
                  (i) => DropdownMenuItem(
                      value: i,
                      child: Text(
                          l.memBankItemLabel(i, _memBankDisplayName(l, i)))),
                ),
                onChanged: (v) => setState(() => _readMemBank = v!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: '$_wordAdd',
                decoration: InputDecoration(
                    labelText: l.wordAddLabel,
                    border: const OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (v) => _wordAdd = int.tryParse(v) ?? 0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: '$_wordCnt',
                decoration: InputDecoration(
                    labelText: l.wordCntLabel,
                    border: const OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (v) => _wordCnt = int.tryParse(v) ?? 6,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          FilledButton(
              onPressed: _busy ? null : _readTag,
              child: Text(l.read)),
          const SizedBox(height: 16),

          // ── 写标签 ────────────────────────────────────────────────────────
          _SectionTitle(l.writeTag),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _writeMemBank,
                decoration: InputDecoration(
                    labelText: l.memBankLabel,
                    border: const OutlineInputBorder()),
                items: List.generate(
                  4,
                  (i) => DropdownMenuItem(
                      value: i,
                      child: Text(
                          l.memBankItemLabel(i, _memBankDisplayName(l, i)))),
                ),
                onChanged: (v) => setState(() => _writeMemBank = v!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: '$_writeWordAdd',
                decoration: InputDecoration(
                    labelText: l.wordAddLabel,
                    border: const OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (v) => _writeWordAdd = int.tryParse(v) ?? 0,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _writeDataCtrl,
            decoration: InputDecoration(
                labelText: l.writeData,
                border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          FilledButton(
              onPressed: _busy ? null : _writeTag,
              child: Text(l.write)),
          const SizedBox(height: 16),

          // ── 写 EPC ────────────────────────────────────────────────────────
          _SectionTitle(l.writeEpc),
          TextField(
            controller: _newEpcCtrl,
            decoration: InputDecoration(
                labelText: l.newEpc,
                border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          FilledButton(
              onPressed: _busy ? null : _writeEpc,
              child: Text(l.writeEpc)),
          const SizedBox(height: 16),

          // ── 点亮 LED ──────────────────────────────────────────────────────
          _SectionTitle(l.lightLed),
          FilledButton.icon(
            onPressed: _busy ? null : _lightUp,
            icon: const Icon(Icons.lightbulb_outline),
            label: Text(l.lightLedBtn),
          ),
          const SizedBox(height: 24),

          // ── 结果 ──────────────────────────────────────────────────────────
          if (_result.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _result,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );
  }
}
