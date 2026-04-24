import 'package:flutter/widgets.dart';

/// 轻量级双语支持（中文 / English）
/// 用法：context.l10n.connectTitle
class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  bool get _isChinese => locale.languageCode == 'zh';

  // ── 连接页 ────────────────────────────────────────────────────────────────
  String get connectTitle     => _isChinese ? 'RFID — 连接设备' : 'RFID — Connect';
  String get modeIntegrated   => _isChinese ? '一体机' : 'Integrated';
  String get modeBleScan      => _isChinese ? 'BLE 扫描' : 'BLE Scan';
  String get modeManual       => _isChinese ? '手动 MAC' : 'Manual MAC';
  String get integratedDesc   => _isChinese ? '一体机' : 'Integrated';
  String get connect          => _isChinese ? '连接' : 'Connect';
  String get connecting       => _isChinese ? '正在连接...' : 'Connecting...';
  String get scanning         => _isChinese ? '扫描中...' : 'Scanning...';
  String get scan             => _isChinese ? '扫描' : 'Scan';
  String get macHint          => _isChinese ? 'MAC 地址' : 'MAC Address';
  String get enableBluetooth  => _isChinese ? '请先开启蓝牙' : 'Please enable Bluetooth';
  String get connectFailed    => _isChinese ? '连接失败' : 'Connect failed';
  String get initFailed       => _isChinese ? '初始化失败' : 'Init failed';
  String get connectTimeout   => _isChinese
      ? '连接超时：请确认设备未被他应用占用，靠近后重试'
      : 'Connection timed out. Disconnect other apps using the device and retry.';
  String get disconnect       => _isChinese ? '断开连接' : 'Disconnect';
  String get linkLost         => _isChinese ? '设备连接已断开' : 'Device disconnected';
  String get enterMac         => _isChinese ? '请输入 MAC 地址' : 'Please enter MAC address';
  String devicesFound(int n)  => _isChinese ? '发现 $n 台设备' : '$n device(s) found';
  String get unknown          => _isChinese ? '未知设备' : 'Unknown';

  // ── 主页 Tab ──────────────────────────────────────────────────────────────
  String get tabInventory     => _isChinese ? '盘存' : 'Inventory';
  String get tabReadWrite     => _isChinese ? '读写' : 'Read/Write';
  String get tabSettings      => _isChinese ? '设置' : 'Settings';

  // ── 盘存页 ────────────────────────────────────────────────────────────────
  String get startInventory   => _isChinese ? '连续盘存' : 'Continuous';
  String get stopInventory    => _isChinese ? '停止盘存' : 'Stop';
  String get singleScan       => _isChinese ? '单次' : 'Single';
  String get clear            => _isChinese ? '清空' : 'Clear';
  String totalTags(int n)     => _isChinese ? '共 $n 条' : '$n tag(s)';

  // ── 读写页 ────────────────────────────────────────────────────────────────
  String get commonParams     => _isChinese ? '公共参数' : 'Common Params';
  String get epcFilter        => _isChinese ? 'EPC（留空=不过滤）' : 'EPC (empty = no filter)';
  String get password8hex     => _isChinese ? '密码（8位十六进制）' : 'Password (8 hex chars)';
  String get readTag          => _isChinese ? '读标签' : 'Read Tag';
  String get writeTag         => _isChinese ? '写标签' : 'Write Tag';
  String get writeEpc         => _isChinese ? '写 EPC' : 'Write EPC';
  String get lightLed         => _isChinese ? '点亮 LED' : 'Light LED';
  String get newEpc           => _isChinese ? '新 EPC' : 'New EPC';
  String get writeData        => _isChinese ? '写入数据（十六进制）' : 'Write data (hex)';
  String get read             => _isChinese ? '读取' : 'Read';
  String get write            => _isChinese ? '写入' : 'Write';
  String get lightLedBtn      => _isChinese ? '点亮标签 LED（5s）' : 'Light Tag LED (5s)';
  String get enterWriteData   => _isChinese ? '请输入写入数据' : 'Please enter write data';
  String get enterNewEpc      => _isChinese ? '请输入新 EPC' : 'Please enter new EPC';

  // ── 设置页 ────────────────────────────────────────────────────────────────
  String get txPower          => _isChinese ? '发射功率' : 'TX Power';
  String get apply            => _isChinese ? '应用' : 'Apply';
  String get freqRegion       => _isChinese ? '频率区域' : 'Frequency Region';
  String get profile          => _isChinese ? '协议配置' : 'Profile';
  String get beep             => _isChinese ? '蜂鸣器' : 'Beep';
  String get beepOn           => _isChinese ? '已开启' : 'Enabled';
  String get beepOff          => _isChinese ? '已关闭' : 'Disabled';
  String get baudRate         => _isChinese ? '波特率' : 'Baud Rate';
  String get inventoryParams  => _isChinese ? '盘存参数' : 'Inventory Parameters';
  String get queryMemBank     => _isChinese ? '查询内存区' : 'Query Memory Bank';
  String get battery          => _isChinese ? '电池' : 'Battery';
  String get charging         => _isChinese ? '充电中' : 'Charging';
  String get notCharging      => _isChinese ? '未充电' : 'Not charging';
  String batteryLevel(int v)  => _isChinese ? '电量: $v%' : 'Level: $v%';
  String get batteryUnknown   => _isChinese ? '电量: --' : 'Level: --';
  String get deviceInfo       => _isChinese ? '设备信息' : 'Device Info';
  String get refreshAll       => _isChinese ? '刷新全部' : 'Refresh All';
  String get noData           => _isChinese ? '暂无数据' : 'No data';
  String get unsupported      => _isChinese ? '- (不支持)' : '- (unsupported)';
  String setPowerResult(int p, int r) =>
      _isChinese ? '设置功率: $p dBm → $r' : 'Set power: $p dBm → $r';
  String setFreqResult(String f, int r) =>
      _isChinese ? '设置频率: $f → $r' : 'Set frequency: $f → $r';
  String setProfileResult(int i, int r) =>
      _isChinese ? '设置Profile: $i → $r' : 'Set profile: $i → $r';
  String beepResult(bool on, int r) =>
      _isChinese ? '蜂鸣器: ${on ? "ON" : "OFF"} → $r' : 'Beep: ${on ? "ON" : "OFF"} → $r';
  String baudRateResult(int rate, int r) =>
      _isChinese ? '设置波特率: $rate → $r' : 'Set baud rate: $rate → $r';

  // ── 主页 AppBar ────────────────────────────────────────────────────────────
  String homeAppBarTitle(String mac) => 'RFID  $mac';

  // ── 盘存列表行（技术缩写保留）─────────────────────────────────────────────
  String tagSubtitle(String tid, String rssi, String bid) =>
      _isChinese
          ? 'TID: $tid  信号强度: $rssi dBm  BID: $bid'
          : 'TID: $tid  RSSI: $rssi  BID: $bid';

  // ── 读写页字段标签 ────────────────────────────────────────────────────────
  String get memBankLabel     => _isChinese ? '内存区' : 'MemBank';
  String get wordAddLabel     => _isChinese ? '字地址' : 'WordAdd';
  String get wordCntLabel     => _isChinese ? '字数' : 'WordCnt';
  String memBankItemLabel(int index, String bankName) => '$index $bankName';
  String get memReserved      => _isChinese ? '保留区' : 'Reserved';
  String get memEpc           => 'EPC';
  String get memTid           => 'TID';
  String get memUser          => _isChinese ? '用户区' : 'User';
  String readTagResult(int code, String data) =>
      _isChinese ? '读取 code=$code\ndata=$data' : 'Read code=$code\ndata=$data';

  // ── 设置页：盘存与查询 ────────────────────────────────────────────────────
  String get paramTarget      => _isChinese ? 'Target' : 'Target';
  String get paramSession     => _isChinese ? 'Session' : 'Session';
  String get paramQValue      => _isChinese ? 'Q 值' : 'Q Value';
  String get paramSceneMode   => _isChinese ? '场景模式' : 'Scene Mode';
  String get paramRssiLimit   => _isChinese ? 'RSSI 下限 (dBm)' : 'RSSI Limit (dBm)';
  String get queryArea        => _isChinese ? '区域' : 'Area';
  String get queryStart       => _isChinese ? '起始' : 'Start';
  String get queryLen         => _isChinese ? '长度' : 'Len';
  String get refreshTooltip   => _isChinese ? '刷新' : 'Refresh';
  String sessionMenuLabel(int i) => 'S$i';
  String get sceneNormal      => _isChinese ? '普通' : 'Normal';
  String get sceneDense       => _isChinese ? '密集' : 'Dense';
  String get sceneFast        => _isChinese ? '快速' : 'Fast';
  String targetResult(String label, int r) =>
      _isChinese ? 'Target: $label → $r' : 'Target: $label → $r';
  String sessionResult(int session, int r) =>
      _isChinese ? 'Session: $session → $r' : 'Session: $session → $r';
  String qValueResult(int q, int r) =>
      _isChinese ? 'Q: $q → $r' : 'Q: $q → $r';
  String sceneResult(String scene, int r) =>
      _isChinese ? '场景: $scene → $r' : 'Scene: $scene → $r';
  String rssiLimitResult(int rssi, int r) =>
      _isChinese ? 'RSSI: $rssi dBm → $r' : 'RSSI: $rssi dBm → $r';
  String queryMemBankResult(String area, int start, int len, int r) =>
      _isChinese
          ? '查询内存区: $area 起始=$start 长度=$len → $r'
          : 'QueryMemBank: $area start=$start len=$len → $r';

  // ── 设备信息字段标题 ──────────────────────────────────────────────────────
  String get diFirmware       => _isChinese ? '固件版本' : 'Firmware Version';
  String get diDeviceId       => _isChinese ? '设备 ID' : 'Device ID';
  String get diReaderType     => _isChinese ? '读写器类型' : 'Reader Type';
  String get diDeviceType     => _isChinese ? '设备类型' : 'Device Type';
  String get diModuleType     => _isChinese ? '模块类型' : 'Module Type';
  String get diEx10           => _isChinese ? 'EX10 版本' : 'EX10 Version';
  String get diTemperature    => _isChinese ? '温度' : 'Temperature';
  String get diSystemVer      => _isChinese ? '系统版本' : 'System Version';
  String get diBleVer         => _isChinese ? 'BLE 版本' : 'BLE Version';
  String get diBleMac         => _isChinese ? 'BLE MAC' : 'BLE MAC';
  String get diMcuVer         => _isChinese ? 'MCU 版本' : 'MCU Version';
  String get diRfidVer        => _isChinese ? 'RFID 版本' : 'RFID Version';
  String get diSn             => _isChinese ? '设备序列号' : 'Device SN';
  String get diBaudRate       => _isChinese ? '波特率' : 'Baud Rate';
  String get diScanMode       => _isChinese ? '扫描模式' : 'Scan Mode';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['zh', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension L10nExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
