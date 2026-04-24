import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rfid/rfid.dart';

import 'l10n.dart';

/// 设置页：功率 / 频率 / Profile / 盘存参数 / 设备信息 / 电池
/// Settings page: power / frequency / profile / inventory params / device info / battery
class SettingsPage extends StatefulWidget {
  final Rfid rfid;

  /// 由 [HomePage] 在连接就绪后或进入设置 Tab 时递增，触发 [_SettingsPageState._loadAll]。
  final int refreshGeneration;

  const SettingsPage({
    super.key,
    required this.rfid,
    this.refreshGeneration = 0,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ── 功率 / Power ──────────────────────────────────────────────────────────
  int _power = 30;
  int _maxPower = 33;

  // ── 频率 / Frequency ──────────────────────────────────────────────────────
  List<String> _freqList = [];
  int _freqIndex = 0;

  // ── Profile ───────────────────────────────────────────────────────────────
  List<String> _profileList = [];
  int _profileIndex = 0;

  // ── 蜂鸣器 / Beep ─────────────────────────────────────────────────────────
  bool _beepEnabled = true;

  // ── 波特率 / Baud rate ────────────────────────────────────────────────────
  int _baudRate = 115200;
  static const _baudRateOptions = [9600, 19200, 38400, 57600, 115200];

  // ── 盘存参数 / Inventory params ───────────────────────────────────────────
  // Target: 0=A, 1=B, 2=AB
  int _target = 0;
  static const _targetLabels = ['A', 'B', 'AB'];

  // Session: 0~3
  int _session = 0;

  // Q值: 0~15
  int _qvalue = 4;

  // SceneMode: 0=Normal, 1=Dense, 2=Fast
  int _sceneMode = 0;

  // RSSI 过滤下限 / RSSI filter lower limit (dBm, 负值)
  int _rssiLimit = -100;

  // QueryMemoryBank: area 0=EPC,1=TID,2=USER
  int _queryMemArea = 0;
  int _queryMemStart = 0;
  int _queryMemLen = 0;

  // ── 设备信息 / Device info ────────────────────────────────────────────────
  static const _deviceKeyOrder = <String>[
    'fw',
    'deviceId',
    'readerType',
    'deviceType',
    'moduleType',
    'ex10',
    'temperature',
    'systemVer',
    'bleVer',
    'bleMac',
    'mcuVer',
    'rfidVer',
    'sn',
    'baudRate',
    'scanMode',
  ];

  late final Map<String, String> _deviceInfo = {
    for (final k in _deviceKeyOrder) k: '-',
  };

  // ── 电池 / Battery ────────────────────────────────────────────────────────
  int _batteryLevel = -1;
  int _isCharging = -1;
  StreamSubscription? _batterySub;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // 监听电池事件，实时更新 / Listen for battery events for real-time updates
    _batterySub = Rfid.rawEventStream.listen(_onEvent);
    // _loadAll 内使用 AppLocalizations.of(context)，initState 阶段 InheritedWidget 尚未就绪，须首帧后再执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAll();
    });
  }

  @override
  void didUpdateWidget(SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshGeneration != oldWidget.refreshGeneration) {
      _loadAll();
    }
  }

  @override
  void dispose() {
    _batterySub?.cancel();
    super.dispose();
  }

  void _onEvent(Map<Object?, Object?> event) {
    if (event['eventType'] != 'event_battery') return;
    final data = Map<String, dynamic>.from(event['data'] as Map);
    if (!mounted) return;
    setState(() {
      _isCharging   = (data['isCharging'] as int?) ?? _isCharging;
      _batteryLevel = (data['level']      as int?) ?? _batteryLevel;
    });
  }

  String _deviceRowTitle(AppLocalizations l, String key) {
    switch (key) {
      case 'fw':
        return l.diFirmware;
      case 'deviceId':
        return l.diDeviceId;
      case 'readerType':
        return l.diReaderType;
      case 'deviceType':
        return l.diDeviceType;
      case 'moduleType':
        return l.diModuleType;
      case 'ex10':
        return l.diEx10;
      case 'temperature':
        return l.diTemperature;
      case 'systemVer':
        return l.diSystemVer;
      case 'bleVer':
        return l.diBleVer;
      case 'bleMac':
        return l.diBleMac;
      case 'mcuVer':
        return l.diMcuVer;
      case 'rfidVer':
        return l.diRfidVer;
      case 'sn':
        return l.diSn;
      case 'baudRate':
        return l.diBaudRate;
      case 'scanMode':
        return l.diScanMode;
      default:
        return key;
    }
  }

  String _sceneModeLabel(AppLocalizations l, int i) {
    switch (i.clamp(0, 2)) {
      case 0:
        return l.sceneNormal;
      case 1:
        return l.sceneDense;
      case 2:
        return l.sceneFast;
      default:
        return '$i';
    }
  }

  String _queryMemAreaLabel(AppLocalizations l, int area) {
    switch (area.clamp(0, 2)) {
      case 0:
        return l.memEpc;
      case 1:
        return l.memTid;
      case 2:
        return l.memUser;
      default:
        return '$area';
    }
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      // 并发拉取所有配置与信息 / Fetch all config and info concurrently
      final results = await Future.wait([
        widget.rfid.getOutputPower(),              // 0
        widget.rfid.getSupportMaxOutputPower(),    // 1
        widget.rfid.getSupportFrequencyBandList(), // 2
        widget.rfid.getSupportProfileList(),       // 3
        widget.rfid.getProfile(),                  // 4
        widget.rfid.getBaudRate(),                 // 5
        widget.rfid.getBatteryLevel(),             // 6
        widget.rfid.getBatteryIsCharging(),        // 7
        // 版本信息 / Version info
        widget.rfid.getFirmwareVersion(),          // 8
        widget.rfid.getDeviceId(),                 // 9
        widget.rfid.getReaderType(),               // 10
        widget.rfid.getEx10Version(),              // 11
        widget.rfid.getVersionBLE(),               // 12
        widget.rfid.getVersionMcu(),               // 13
        widget.rfid.getVersionRfid(),              // 14
        widget.rfid.getDeviceSN(),                 // 15
        widget.rfid.getScanMode(),                 // 16
        // 盘存参数 / Inventory params
        widget.rfid.getInventoryWithTarget(),      // 17
        widget.rfid.getInventoryWithSession(),     // 18
        widget.rfid.getInventoryWithStartQvalue(), // 19
        widget.rfid.getInventorySceneMode(),       // 20
        widget.rfid.getInventoryRssiLimit(),       // 21
        // 新增版本/设备信息 / Additional device info
        widget.rfid.getReaderDeviceType(),         // 22
        widget.rfid.getModuleType(),               // 23
        widget.rfid.getVersionSystem(),            // 24
        widget.rfid.getReaderTemperature(),        // 25
        widget.rfid.getBLEMac(),                   // 26
      ]);

      if (!mounted) return;

      final freqList    = (results[2] as List).cast<String>();
      final profileList = (results[3] as List).cast<String>();
      final profileIdx  = (results[4] as int).clamp(
          0, profileList.isEmpty ? 0 : profileList.length - 1);
      final baudRate    = results[5] as int;

      setState(() {
        _power        = results[0] as int;
        _maxPower     = results[1] as int;
        _freqList     = freqList;
        _profileList  = profileList;
        _profileIndex = profileIdx;
        _baudRate     = _baudRateOptions.contains(baudRate) ? baudRate : 115200;
        _batteryLevel = results[6] as int;
        _isCharging   = results[7] as int;

        _deviceInfo['fw']          = (results[8]  as String?) ?? '-';
        _deviceInfo['deviceId']    = (results[9]  as String?) ?? '-';
        _deviceInfo['readerType']  = '${results[10] as int}';
        _deviceInfo['ex10']        = _emptyOrValue(l10n, results[11] as String?);
        _deviceInfo['bleVer']      = _emptyOrValue(l10n, results[12] as String?);
        _deviceInfo['mcuVer']      = _emptyOrValue(l10n, results[13] as String?);
        _deviceInfo['rfidVer']     = _emptyOrValue(l10n, results[14] as String?);
        _deviceInfo['sn']          = (results[15] as String?) ?? '-';
        _deviceInfo['baudRate']    = '$baudRate';
        _deviceInfo['scanMode']    = '${results[16] as int}';
        _deviceInfo['deviceType']  = '${results[22] as int}';
        _deviceInfo['moduleType']  = '${results[23] as int}';
        _deviceInfo['systemVer']   = _emptyOrValue(l10n, results[24] as String?);
        _deviceInfo['temperature'] = _emptyOrValue(l10n, results[25] as String?);
        _deviceInfo['bleMac']      = _emptyOrValue(l10n, results[26] as String?);

        // 盘存参数 / Inventory params
        final target    = results[17] as int;
        final session   = results[18] as int;
        final qvalue    = results[19] as int;
        final sceneMode = results[20] as int;
        final rssi      = results[21] as int;
        _target    = target.clamp(0, _targetLabels.length - 1);
        _session   = session.clamp(0, 3);
        _qvalue    = qvalue.clamp(0, 15);
        _sceneMode = sceneMode.clamp(0, 2);
        _rssiLimit = rssi;
      });

      // 获取当前频率索引（依赖 freqList，单独查询）
      // Fetch current frequency region index (depends on freqList)
      final region = await widget.rfid.getFrequencyRegion();
      if (mounted && region != null && freqList.isNotEmpty) {
        setState(() =>
            _freqIndex = region.regionIndex.clamp(0, freqList.length - 1));
      }

      // 获取 QueryMemoryBank
      final memBank = await widget.rfid.getQueryMemoryBank();
      if (mounted && memBank != null) {
        setState(() {
          _queryMemArea  = memBank.area.clamp(0, 2);
          _queryMemStart = memBank.startAddress;
          _queryMemLen   = memBank.length;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 空字符串显示为不支持提示 / Localized unsupported placeholder for empty string
  String _emptyOrValue(AppLocalizations l, String? v) {
    if (v == null || v.isEmpty) return l.unsupported;
    return v;
  }

  // ── 应用操作 / Apply actions ──────────────────────────────────────────────

  Future<void> _applyPower() async {
    final ret = await widget.rfid.setOutputPower(_power);
    _showSnack(context.l10n.setPowerResult(_power, ret));
  }

  Future<void> _applyFreq(int idx) async {
    if (_freqList.isEmpty) return;
    final ret = await widget.rfid.setFrequencyRegion(
      regionIndex: idx,
      minChannelIndex: 0,
      maxChannelIndex: 0,
    );
    if (ret == 0) setState(() => _freqIndex = idx);
    _showSnack(context.l10n.setFreqResult(_freqList[idx], ret));
  }

  Future<void> _applyProfile(int idx) async {
    final ret = await widget.rfid.setProfile(idx);
    if (ret == 0) setState(() => _profileIndex = idx);
    _showSnack(context.l10n.setProfileResult(idx, ret));
  }

  Future<void> _applyBeep(bool enable) async {
    final ret = await widget.rfid.setBeepEnable(enable);
    if (ret == 0) setState(() => _beepEnabled = enable);
    _showSnack(context.l10n.beepResult(enable, ret));
  }

  Future<void> _applyBaudRate(int rate) async {
    final ret = await widget.rfid.setBaudRate(rate);
    if (ret == 0) {
      setState(() {
        _baudRate = rate;
        _deviceInfo['baudRate'] = '$rate';
      });
    }
    _showSnack(context.l10n.baudRateResult(rate, ret));
  }

  Future<void> _applyTarget(int target) async {
    final ret = await widget.rfid.setInventoryWithTarget(target);
    if (ret == 0) setState(() => _target = target);
    _showSnack(context.l10n.targetResult(_targetLabels[target], ret));
  }

  Future<void> _applySession(int session) async {
    final ret = await widget.rfid.setInventoryWithSession(session);
    if (ret == 0) setState(() => _session = session);
    _showSnack(context.l10n.sessionResult(session, ret));
  }

  Future<void> _applyQvalue(int q) async {
    final ret = await widget.rfid.setInventoryWithStartQvalue(q);
    if (ret == 0) setState(() => _qvalue = q);
    _showSnack(context.l10n.qValueResult(q, ret));
  }

  Future<void> _applySceneMode(int mode) async {
    final ret = await widget.rfid.setInventorySceneMode(mode);
    if (ret == 0) setState(() => _sceneMode = mode);
    _showSnack(context.l10n
        .sceneResult(_sceneModeLabel(context.l10n, mode), ret));
  }

  Future<void> _applyRssiLimit() async {
    final ret = await widget.rfid.setInventoryRssiLimit(_rssiLimit);
    _showSnack(context.l10n.rssiLimitResult(_rssiLimit, ret));
  }

  Future<void> _applyQueryMemBank() async {
    final ret = await widget.rfid.setQueryMemoryBank(
      area: _queryMemArea,
      startAddress: _queryMemStart,
      length: _queryMemLen,
    );
    final l = context.l10n;
    _showSnack(l.queryMemBankResult(
      _queryMemAreaLabel(l, _queryMemArea),
      _queryMemStart,
      _queryMemLen,
      ret,
    ));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── 发射功率 / TX Power ──────────────────────────────────────────────
        _SectionTitle(l.txPower),
        Row(children: [
          Expanded(
            child: Slider(
              value: _power.toDouble().clamp(0, _maxPower.toDouble()),
              min: 0,
              max: _maxPower.toDouble(),
              divisions: _maxPower > 0 ? _maxPower : 1,
              label: '$_power dBm',
              onChanged: (v) => setState(() => _power = v.round()),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text('$_power dBm',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
          ),
          TextButton(onPressed: _applyPower, child: Text(l.apply)),
        ]),
        const Divider(),

        // ── 频率区域 / Frequency Region ──────────────────────────────────────
        _SectionTitle(l.freqRegion),
        if (_freqList.isEmpty)
          Text(l.noData)
        else
          DropdownButtonFormField<int>(
            value: _freqIndex,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: List.generate(
              _freqList.length,
              (i) => DropdownMenuItem(value: i, child: Text(_freqList[i])),
            ),
            onChanged: (v) => _applyFreq(v!),
          ),
        const Divider(),

        // ── Profile ──────────────────────────────────────────────────────────
        _SectionTitle(l.profile),
        if (_profileList.isEmpty)
          Text(l.noData)
        else
          DropdownButtonFormField<int>(
            value: _profileIndex,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: List.generate(
              _profileList.length,
              (i) => DropdownMenuItem(value: i, child: Text(_profileList[i])),
            ),
            onChanged: (v) => _applyProfile(v!),
          ),
        const Divider(),

        // ── 蜂鸣器 / Beep ────────────────────────────────────────────────────
        _SectionTitle(l.beep),
        SwitchListTile(
          title: Text(_beepEnabled ? l.beepOn : l.beepOff),
          value: _beepEnabled,
          onChanged: _applyBeep,
        ),
        const Divider(),

        // ── 波特率 / Baud Rate ────────────────────────────────────────────────
        _SectionTitle(l.baudRate),
        DropdownButtonFormField<int>(
          value: _baudRate,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: _baudRateOptions
              .map((r) => DropdownMenuItem(value: r, child: Text('$r')))
              .toList(),
          onChanged: (v) => _applyBaudRate(v!),
        ),
        const Divider(),

        // ── 盘存参数 / Inventory Parameters ──────────────────────────────────
        _SectionTitle(l.inventoryParams),

        // Target
        _ParamRow(
          label: l.paramTarget,
          child: DropdownButton<int>(
            value: _target,
            isDense: true,
            items: List.generate(
              _targetLabels.length,
              (i) => DropdownMenuItem(
                  value: i, child: Text(_targetLabels[i])),
            ),
            onChanged: (v) => _applyTarget(v!),
          ),
        ),

        // Session
        _ParamRow(
          label: l.paramSession,
          child: DropdownButton<int>(
            value: _session,
            isDense: true,
            items: List.generate(
              4,
              (i) => DropdownMenuItem(
                  value: i, child: Text(l.sessionMenuLabel(i))),
            ),
            onChanged: (v) => _applySession(v!),
          ),
        ),

        // Q值
        _ParamRow(
          label: l.paramQValue,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 160,
                child: Slider(
                  value: _qvalue.toDouble(),
                  min: 0,
                  max: 15,
                  divisions: 15,
                  label: '$_qvalue',
                  onChanged: (v) => setState(() => _qvalue = v.round()),
                  onChangeEnd: (v) => _applyQvalue(v.round()),
                ),
              ),
              Text('$_qvalue', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),

        // Scene Mode
        _ParamRow(
          label: l.paramSceneMode,
          child: DropdownButton<int>(
            value: _sceneMode,
            isDense: true,
            items: List.generate(
              3,
              (i) => DropdownMenuItem(
                  value: i, child: Text(_sceneModeLabel(l, i))),
            ),
            onChanged: (v) => _applySceneMode(v!),
          ),
        ),

        // RSSI Limit
        _ParamRow(
          label: l.paramRssiLimit,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                child: Slider(
                  value: _rssiLimit.toDouble().clamp(-120, 0),
                  min: -120,
                  max: 0,
                  divisions: 120,
                  label: '$_rssiLimit',
                  onChanged: (v) => setState(() => _rssiLimit = v.round()),
                  onChangeEnd: (_) => _applyRssiLimit(),
                ),
              ),
              Text('$_rssiLimit', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),

        // QueryMemoryBank
        _SectionTitle(l.queryMemBank),
        Row(
          children: [
            // Area
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _queryMemArea,
                decoration: InputDecoration(
                    labelText: l.queryArea,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4)),
                items: List.generate(
                  3,
                  (i) => DropdownMenuItem(
                      value: i, child: Text(_queryMemAreaLabel(l, i))),
                ),
                onChanged: (v) => setState(() => _queryMemArea = v!),
              ),
            ),
            const SizedBox(width: 8),
            // Start
            SizedBox(
              width: 72,
              child: TextFormField(
                initialValue: '$_queryMemStart',
                decoration: InputDecoration(
                    labelText: l.queryStart,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4)),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    _queryMemStart = int.tryParse(v) ?? _queryMemStart,
              ),
            ),
            const SizedBox(width: 8),
            // Length
            SizedBox(
              width: 72,
              child: TextFormField(
                initialValue: '$_queryMemLen',
                decoration: InputDecoration(
                    labelText: l.queryLen,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4)),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    _queryMemLen = int.tryParse(v) ?? _queryMemLen,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
                onPressed: _applyQueryMemBank,
                child: Text(l.apply)),
          ],
        ),
        const Divider(),

        // ── 电池 / Battery ────────────────────────────────────────────────────
        _SectionTitle(l.battery),
        ListTile(
          leading: Icon(
            _isCharging == 1
                ? Icons.battery_charging_full
                : Icons.battery_std,
            color: _batteryLevel > 20 ? Colors.green : Colors.red,
          ),
          title: Text(
            _batteryLevel >= 0 ? l.batteryLevel(_batteryLevel) : l.batteryUnknown,
          ),
          subtitle: Text(
            _isCharging == 1
                ? l.charging
                : _isCharging == 0
                    ? l.notCharging
                    : '--',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l.refreshTooltip,
            onPressed: _loadAll,
          ),
        ),
        const Divider(),

        // ── 设备信息 / Device Info ────────────────────────────────────────────
        _SectionTitle(l.deviceInfo),
        ..._deviceKeyOrder.map(
          (key) => ListTile(
            dense: true,
            title: Text(
              _deviceRowTitle(l, key),
              style: const TextStyle(fontSize: 13),
            ),
            trailing: SelectableText(
              _deviceInfo[key]!.isEmpty ? '-' : _deviceInfo[key]!,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _loadAll,
          icon: const Icon(Icons.refresh),
          label: Text(l.refreshAll),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// 参数行布局辅助 / Helper widget for parameter row layout
class _ParamRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _ParamRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          child,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
