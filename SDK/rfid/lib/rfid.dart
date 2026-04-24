import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'rfid_platform_interface.dart';

export 'rfid_platform_interface.dart'
    show
        TagReadResult,
        FrequencyRegionInfo,
        QueryMemBankInfo,
        FindEpcResult,
        CustomRegionInfo,
        OfflineQueryNum,
        OfflineQueryMem,
        AuthResult,
        ImpinjScanParam,
        ReaderProtectedModeResult,
        MatchDataItem;

/// RFID 插件公共 API 入口。
///
/// 连接方式：
/// - 一体机/UART：调用 [initSdk]（无参）
/// - 蓝牙分体设备：调用 [initSdkBle]（传入 MAC 地址）
///
/// 事件流通过 [rawEventStream] 统一接收，eventType 包括：
/// - event_inventory_tag      盘存到标签
/// - event_inventory_tag_end  盘存结束
/// - event_battery            电池状态变化
/// - event_barcode            条码扫描结果
/// - event_key                按键事件
/// - event_module_switch      模块开关状态
/// - event_fw_update          固件升级进度
/// - event_connection         读写器链路：`data` 为 Map，`connected` 为 bool；每次原生
///   [InitListener.onStatus] 都会推送（含断开、重连）。与单次 `initSdk` / `initSdkBle` 的
///   MethodChannel 返回值无关，后者仅表示「本次初始化调用」的结果。
class Rfid {
  static const _eventChannel = EventChannel('plugin_rfid_event');

  /// 原生 EventChannel 仅保留一个 [EventSink]；若多处对 [rawEventStream] 调用
  /// `listen()`（例如盘存页 + 设置页同时监听），后注册的会覆盖前者，导致盘存无回调。
  /// 此处只向引擎订阅一次，再用 broadcast 分发给所有 Dart 监听方。
  static StreamController<Map<Object?, Object?>>? _rawEventHub;
  static StreamSubscription<dynamic>? _rawEventEngineSub;

  /// 原始事件流，每条事件为 Map{'eventType': String, 'data': dynamic}
  static Stream<Map<Object?, Object?>> get rawEventStream {
    if (_rawEventHub == null) {
      _rawEventHub = StreamController<Map<Object?, Object?>>.broadcast(sync: true);
      _rawEventEngineSub = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          final map = Map<Object?, Object?>.from(event as Map);
          if (!(_rawEventHub?.isClosed ?? true)) {
            _rawEventHub!.add(map);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!(_rawEventHub?.isClosed ?? true)) {
            _rawEventHub!.addError(error, stackTrace);
          }
        },
      );
    }
    return _rawEventHub!.stream;
  }

  // ── SDK 生命周期 ──────────────────────────────────────────────────────────

  /// 一体机/UART 设备初始化（无参）
  Future<int> initSdk() => RfidPlatform.instance.initSdk();

  /// 蓝牙设备初始化，传入 MAC 地址
  /// BLE 扫描由宿主 App 完成（如 flutter_blue_plus），连接由 SDK 自行管理。
  Future<int> initSdkBle(String mac) => RfidPlatform.instance.initSdkBle(mac);

  Future<int> releaseSdk() => RfidPlatform.instance.releaseSdk();

  Future<bool> isConnected() => RfidPlatform.instance.isConnected();

  // ── 盘存 ──────────────────────────────────────────────────────────────────

  /// 持续盘存，直到调用 [stopInventory]
  Future<int> startInventory() => RfidPlatform.instance.startInventory();

  /// 带超时盘存，[timeout] 单位秒，到时自动停止
  Future<int> startInventoryWithTimeout(int timeout) =>
      RfidPlatform.instance.startInventoryWithTimeout(timeout);

  Future<int> stopInventory() => RfidPlatform.instance.stopInventory();

  Future<int> inventorySingle() => RfidPlatform.instance.inventorySingle();

  // ── 标签操作 ──────────────────────────────────────────────────────────────

  Future<TagReadResult> readTag({
    String? epc,
    required int memBank,
    required int wordAdd,
    required int wordCnt,
    String? password,
  }) =>
      RfidPlatform.instance.readTag(
        epc: epc,
        memBank: memBank,
        wordAdd: wordAdd,
        wordCnt: wordCnt,
        password: password,
      );

  Future<int> writeTag({
    String? epc,
    String? password,
    required int memBank,
    required int wordAdd,
    required String data,
  }) =>
      RfidPlatform.instance.writeTag(
        epc: epc,
        password: password,
        memBank: memBank,
        wordAdd: wordAdd,
        data: data,
      );

  Future<int> writeTagEpc({
    String? epc,
    String? password,
    required String newEpc,
  }) =>
      RfidPlatform.instance.writeTagEpc(epc: epc, password: password, newEpc: newEpc);

  /// 随机改写一张标签的 EPC
  Future<int> writeEpc({String? epc, String? password}) =>
      RfidPlatform.instance.writeEpc(epc: epc, password: password);

  Future<int> killTag({String? epc, String? password}) =>
      RfidPlatform.instance.killTag(epc: epc, password: password);

  Future<int> lockTag({
    String? epc,
    String? password,
    required int memBank,
    required int lockType,
  }) =>
      RfidPlatform.instance.lockTag(
          epc: epc, password: password, memBank: memBank, lockType: lockType);

  Future<int> lightUpLedTag({
    String? epc,
    String? password,
    int duration = 5000,
  }) =>
      RfidPlatform.instance.lightUpLedTag(epc: epc, password: password, duration: duration);

  // ── 通过 TID 操作标签 ─────────────────────────────────────────────────────

  Future<String?> readDataByTid({
    required String tid,
    required int memBank,
    required int startAdd,
    required int wordCnt,
    String? password,
  }) =>
      RfidPlatform.instance.readDataByTid(
        tid: tid,
        memBank: memBank,
        startAdd: startAdd,
        wordCnt: wordCnt,
        password: password,
      );

  Future<int> writeTagByTid({
    required String tid,
    required int memBank,
    required int startAdd,
    String? password,
    required String data,
  }) =>
      RfidPlatform.instance.writeTagByTid(
        tid: tid,
        memBank: memBank,
        startAdd: startAdd,
        password: password,
        data: data,
      );

  Future<int> lockByTID({
    required String tid,
    required int lockBank,
    required int lockType,
    String? password,
  }) =>
      RfidPlatform.instance.lockByTID(
          tid: tid, lockBank: lockBank, lockType: lockType, password: password);

  Future<int> killTagByTid({required String tid, String? password}) =>
      RfidPlatform.instance.killTagByTid(tid: tid, password: password);

  Future<int> writeTagEpcByTid({
    required String tid,
    String? password,
    required String newEpc,
  }) =>
      RfidPlatform.instance.writeTagEpcByTid(tid: tid, password: password, newEpc: newEpc);

  // ── 带掩码操作 ────────────────────────────────────────────────────────────

  Future<TagReadResult> maskReadTag({
    required int memBank,
    required int startAdd,
    required int wordCnt,
    String? password,
    required int memMask,
    required int startMask,
    required int lenMask,
    required String dataMask,
  }) =>
      RfidPlatform.instance.maskReadTag(
        memBank: memBank,
        startAdd: startAdd,
        wordCnt: wordCnt,
        password: password,
        memMask: memMask,
        startMask: startMask,
        lenMask: lenMask,
        dataMask: dataMask,
      );

  Future<int> maskWriteTag({
    required String data,
    required int memBank,
    required int startAdd,
    required int wordCnt,
    String? password,
    required int memMask,
    required int startMask,
    required int lenMask,
    required String dataMask,
  }) =>
      RfidPlatform.instance.maskWriteTag(
        data: data,
        memBank: memBank,
        startAdd: startAdd,
        wordCnt: wordCnt,
        password: password,
        memMask: memMask,
        startMask: startMask,
        lenMask: lenMask,
        dataMask: dataMask,
      );

  // ── 大容量标签 ────────────────────────────────────────────────────────────

  Future<TagReadResult> readTagExt({
    String? epc,
    required int memBank,
    required int startAdd,
    required int wordCnt,
    String? password,
  }) =>
      RfidPlatform.instance.readTagExt(
        epc: epc,
        memBank: memBank,
        startAdd: startAdd,
        wordCnt: wordCnt,
        password: password,
      );

  Future<int> writeTagExt({
    String? epc,
    String? password,
    required int memBank,
    required int startAdd,
    required String data,
  }) =>
      RfidPlatform.instance.writeTagExt(
        epc: epc,
        password: password,
        memBank: memBank,
        startAdd: startAdd,
        data: data,
      );

  Future<int> eraseTag({
    String? epc,
    String? password,
    required int memBank,
    required int startAdd,
    required int wordCnt,
  }) =>
      RfidPlatform.instance.eraseTag(
        epc: epc,
        password: password,
        memBank: memBank,
        startAdd: startAdd,
        wordCnt: wordCnt,
      );

  /// 查找标签，返回 EPC 和 RSSI（可通过 rssi 判断距离）
  Future<FindEpcResult?> findEpc(String epc) => RfidPlatform.instance.findEpc(epc);

  // ── LED 标签 ──────────────────────────────────────────────────────────────

  /// [manufacturers] 0=凯路威，1=宜联
  Future<int> startInventoryLed({
    required int manufacturers,
    required List<String> epcs,
  }) =>
      RfidPlatform.instance.startInventoryLed(manufacturers: manufacturers, epcs: epcs);

  Future<int> stopInventoryLed() => RfidPlatform.instance.stopInventoryLed();

  // ── 掩码 ──────────────────────────────────────────────────────────────────

  /// startAddress/len 单位为 bit（对应 SDK addMaskByBits）
  Future<int> addMask({
    required int mem,
    required int startAddress,
    required int len,
    required String data,
  }) =>
      RfidPlatform.instance.addMask(mem: mem, startAddress: startAddress, len: len, data: data);

  /// startAddress/len 单位为 word（对应 SDK addMask）
  Future<int> addMaskWord({
    required int mem,
    required int startAddress,
    required int len,
    required String data,
  }) =>
      RfidPlatform.instance.addMaskWord(mem: mem, startAddress: startAddress, len: len, data: data);

  Future<int> clearMask() => RfidPlatform.instance.clearMask();

  // ── 功率与频率 ────────────────────────────────────────────────────────────

  Future<int> setOutputPower(int power) => RfidPlatform.instance.setOutputPower(power);

  Future<int> getOutputPower() => RfidPlatform.instance.getOutputPower();

  Future<int> getSupportMaxOutputPower() => RfidPlatform.instance.getSupportMaxOutputPower();

  Future<int> setFrequencyRegion({
    required int regionIndex,
    required int minChannelIndex,
    required int maxChannelIndex,
  }) =>
      RfidPlatform.instance.setFrequencyRegion(
        regionIndex: regionIndex,
        minChannelIndex: minChannelIndex,
        maxChannelIndex: maxChannelIndex,
      );

  Future<FrequencyRegionInfo?> getFrequencyRegion() => RfidPlatform.instance.getFrequencyRegion();

  Future<List<String>> getSupportFrequencyBandList() =>
      RfidPlatform.instance.getSupportFrequencyBandList();

  /// 按国家/区域索引设置频段（索引来自 getSupportWorkRegionList）
  Future<int> setWorkRegion(int countryCodeIndex) =>
      RfidPlatform.instance.setWorkRegion(countryCodeIndex);

  Future<int> getWorkRegion() => RfidPlatform.instance.getWorkRegion();

  Future<List<String>> getSupportWorkRegionList() =>
      RfidPlatform.instance.getSupportWorkRegionList();

  Future<int> setCustomRegion({
    required int band,
    required int freSpace,
    required int freNum,
    required int startFre,
  }) =>
      RfidPlatform.instance.setCustomRegion(
        band: band,
        freSpace: freSpace,
        freNum: freNum,
        startFre: startFre,
      );

  Future<CustomRegionInfo?> getCustomRegion() => RfidPlatform.instance.getCustomRegion();

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<int> setProfile(int profileIndex) => RfidPlatform.instance.setProfile(profileIndex);

  Future<int> getProfile() => RfidPlatform.instance.getProfile();

  Future<List<String>> getSupportProfileList() => RfidPlatform.instance.getSupportProfileList();

  // ── 盘存参数 ──────────────────────────────────────────────────────────────

  Future<int> setInventoryWithTarget(int target) =>
      RfidPlatform.instance.setInventoryWithTarget(target);

  Future<int> getInventoryWithTarget() => RfidPlatform.instance.getInventoryWithTarget();

  Future<int> setInventoryWithSession(int session) =>
      RfidPlatform.instance.setInventoryWithSession(session);

  Future<int> getInventoryWithSession() => RfidPlatform.instance.getInventoryWithSession();

  Future<int> setInventoryWithStartQvalue(int qvalue) =>
      RfidPlatform.instance.setInventoryWithStartQvalue(qvalue);

  Future<int> getInventoryWithStartQvalue() =>
      RfidPlatform.instance.getInventoryWithStartQvalue();

  Future<int> setInventoryWithPassword(String password) =>
      RfidPlatform.instance.setInventoryWithPassword(password);

  Future<String?> getInventoryWithPassword() =>
      RfidPlatform.instance.getInventoryWithPassword();

  Future<int> setQueryMemoryBank({
    required int area,
    required int startAddress,
    required int length,
  }) =>
      RfidPlatform.instance.setQueryMemoryBank(
          area: area, startAddress: startAddress, length: length);

  Future<QueryMemBankInfo?> getQueryMemoryBank() => RfidPlatform.instance.getQueryMemoryBank();

  Future<int> setInventorySceneMode(int mode) =>
      RfidPlatform.instance.setInventorySceneMode(mode);

  Future<int> getInventorySceneMode() => RfidPlatform.instance.getInventorySceneMode();

  Future<int> setInventoryRssiLimit(int limit) =>
      RfidPlatform.instance.setInventoryRssiLimit(limit);

  Future<int> getInventoryRssiLimit() => RfidPlatform.instance.getInventoryRssiLimit();

  Future<bool> isSupportInventoryRssiLimit() =>
      RfidPlatform.instance.isSupportInventoryRssiLimit();

  Future<int> setRssiInDbm(bool enable) => RfidPlatform.instance.setRssiInDbm(enable);

  Future<int> setInventoryPhaseFlag(bool enable) =>
      RfidPlatform.instance.setInventoryPhaseFlag(enable);

  Future<bool> getInventoryPhaseFlag() => RfidPlatform.instance.getInventoryPhaseFlag();

  // ── 设备信息 ──────────────────────────────────────────────────────────────

  Future<String?> getFirmwareVersion() => RfidPlatform.instance.getFirmwareVersion();

  Future<String?> getDeviceId() => RfidPlatform.instance.getDeviceId();

  Future<int> getReaderType() => RfidPlatform.instance.getReaderType();

  Future<String?> getEx10Version() => RfidPlatform.instance.getEx10Version();

  Future<String?> getReaderTemperature() => RfidPlatform.instance.getReaderTemperature();

  /// 获取当前连接的设备类型（一体机/串口/蓝牙）
  Future<int> getReaderDeviceType() => RfidPlatform.instance.getReaderDeviceType();

  /// 获取当前 RFID 模块型号（U1~U5）
  Future<int> getModuleType() => RfidPlatform.instance.getModuleType();

  /// 设置 TagFocus（仅 Ex10 系列，0=关，1=开）
  Future<int> setTagFocus(int enable) => RfidPlatform.instance.setTagFocus(enable);

  Future<int> getTagFocus() => RfidPlatform.instance.getTagFocus();

  Future<int> setBaudRate(int baudRate) => RfidPlatform.instance.setBaudRate(baudRate);

  Future<int> getBaudRate() => RfidPlatform.instance.getBaudRate();

  Future<int> setBeepEnable(bool enable) => RfidPlatform.instance.setBeepEnable(enable);

  // ── GripDevice ────────────────────────────────────────────────────────────

  Future<int> getBatteryLevel() => RfidPlatform.instance.getBatteryLevel();

  Future<int> getBatteryIsCharging() => RfidPlatform.instance.getBatteryIsCharging();

  Future<String?> getVersionSystem() => RfidPlatform.instance.getVersionSystem();

  Future<String?> getVersionBLE() => RfidPlatform.instance.getVersionBLE();

  Future<String?> getVersionMcu() => RfidPlatform.instance.getVersionMcu();

  Future<String?> getVersionRfid() => RfidPlatform.instance.getVersionRfid();

  Future<String?> getDeviceSN() => RfidPlatform.instance.getDeviceSN();

  Future<String?> getBLEMac() => RfidPlatform.instance.getBLEMac();

  Future<int> getScanMode() => RfidPlatform.instance.getScanMode();

  /// [start] true=触发扫码，false=停止扫码
  Future<int> startScanBarcode(bool start) => RfidPlatform.instance.startScanBarcode(start);

  /// 设置蜂鸣器音量（0~10，0=关闭）
  Future<int> setBeepRange(int volume) => RfidPlatform.instance.setBeepRange(volume);

  Future<int> getBeepRange() => RfidPlatform.instance.getBeepRange();

  /// 设置休眠时间（0~3600 秒，0=永不休眠）
  Future<int> setSleepTime(int seconds) => RfidPlatform.instance.setSleepTime(seconds);

  Future<int> getSleepTime() => RfidPlatform.instance.getSleepTime();

  /// 设置超时关机时间（0~3600 秒，0=永不关机）
  Future<int> setPowerOffTime(int seconds) => RfidPlatform.instance.setPowerOffTime(seconds);

  Future<int> getPowerOffTime() => RfidPlatform.instance.getPowerOffTime();

  /// 设置离线模式（0=关，1=开）
  Future<int> setOfflineModeOpen(int enable) => RfidPlatform.instance.setOfflineModeOpen(enable);

  Future<int> getOfflineModeOpen() => RfidPlatform.instance.getOfflineModeOpen();

  Future<int> setOfflineTransferClearData(int enable) =>
      RfidPlatform.instance.setOfflineTransferClearData(enable);

  Future<int> getOfflineTransferClearData() =>
      RfidPlatform.instance.getOfflineTransferClearData();

  /// 设置离线数据传输间隔（0~10000ms）
  Future<int> setOfflineTransferDelay(int ms) =>
      RfidPlatform.instance.setOfflineTransferDelay(ms);

  Future<OfflineQueryNum?> getOfflineQueryNum() => RfidPlatform.instance.getOfflineQueryNum();

  Future<OfflineQueryMem?> getOfflineQueryMem() => RfidPlatform.instance.getOfflineQueryMem();

  Future<int> offlineManaulClearScanData() => RfidPlatform.instance.offlineManaulClearScanData();

  Future<int> offlineManaulClearRFIDData() => RfidPlatform.instance.offlineManaulClearRFIDData();

  /// 开始传输离线 RFID 数据（通过 event_inventory_tag 回调）
  Future<int> offlineStartTransferRFID() => RfidPlatform.instance.offlineStartTransferRFID();

  /// 开始传输离线条码数据（通过 event_barcode 回调）
  Future<int> offlineStartTransferScan() => RfidPlatform.instance.offlineStartTransferScan();

  Future<int> modeResetFactory() => RfidPlatform.instance.modeResetFactory();

  // ── 固件升级 ──────────────────────────────────────────────────────────────
  // 升级进度通过 rawEventStream 中 eventType=event_fw_update 回调
  // data: {'code': int, 'progress': int}
  // code: 0=成功, 11=失败, 12=升级中, 13=进入升级模式失败, 14=进入升级模式成功, 20=读取文件出错

  Future<void> updateReaderFirmwareByFile({
    required String binName,
    required String binPath,
  }) =>
      RfidPlatform.instance.updateReaderFirmwareByFile(binName: binName, binPath: binPath);

  Future<void> updateReaderFirmwareByByte({
    required String binName,
    required Uint8List data,
  }) =>
      RfidPlatform.instance.updateReaderFirmwareByByte(binName: binName, data: data);

  Future<void> updateEx10ChipFirmwareByFile({required String binPath}) =>
      RfidPlatform.instance.updateEx10ChipFirmwareByFile(binPath: binPath);

  Future<void> updateEx10ChipFirmwareByByte({required Uint8List data}) =>
      RfidPlatform.instance.updateEx10ChipFirmwareByByte(data: data);

  Future<void> updateBLEReaderFirmwareByFile({
    required String mac,
    required String binName,
    required String binPath,
  }) =>
      RfidPlatform.instance.updateBLEReaderFirmwareByFile(
          mac: mac, binName: binName, binPath: binPath);

  Future<void> updateBLEReaderFirmwareByByte({
    required String mac,
    required String binName,
    required Uint8List data,
  }) =>
      RfidPlatform.instance.updateBLEReaderFirmwareByByte(mac: mac, binName: binName, data: data);

  Future<void> updateBLEEx10ChipFirmwareByFile({
    required String mac,
    required String binName,
    required String binPath,
  }) =>
      RfidPlatform.instance.updateBLEEx10ChipFirmwareByFile(
          mac: mac, binName: binName, binPath: binPath);

  Future<void> updateBLEEx10ChipFirmwareByByte({
    required String mac,
    required Uint8List data,
  }) =>
      RfidPlatform.instance.updateBLEEx10ChipFirmwareByByte(
          mac: mac, data: data);

  // ── Gen2x ──────────────────────────────────────────────────────────────

  /// 设置 Gen2x Profile（需先设置才能使用 Gen2x 特性）
  Future<int> setExtProfile(int profile) =>
      RfidPlatform.instance.setExtProfile(profile);

  Future<int> getExtProfile() => RfidPlatform.instance.getExtProfile();

  /// 设置标签短距模式
  Future<int> setShortRangeFlag({
    required int epcNum,
    String? strEPC,
    String? password,
    required int maskMem,
    required int btWordAdd,
    required int maskLength,
    String? maskData,
    required int srBit,
    required int srValue,
  }) =>
      RfidPlatform.instance.setShortRangeFlag(
        epcNum: epcNum, strEPC: strEPC, password: password,
        maskMem: maskMem, btWordAdd: btWordAdd, maskLength: maskLength,
        maskData: maskData, srBit: srBit, srValue: srValue,
      );

  /// 读取标签短距模式状态（0=关/1=开）
  Future<int> getShortRangeFlag({
    required int epcNum,
    String? strEPC,
    String? password,
    required int maskMem,
    required int btWordAdd,
    required int maskLength,
    String? maskData,
    required int srBit,
  }) =>
      RfidPlatform.instance.getShortRangeFlag(
        epcNum: epcNum, strEPC: strEPC, password: password,
        maskMem: maskMem, btWordAdd: btWordAdd, maskLength: maskLength,
        maskData: maskData, srBit: srBit,
      );

  /// 验证数据写入可靠性
  Future<int> marginRead({
    required int epcNum,
    String? strEPC,
    required int memInt,
    required int address,
    required int matchLength,
    String? matchData,
    String? password,
    required int maskMem,
    required int btWordAdd,
    required int maskLength,
    String? maskData,
  }) =>
      RfidPlatform.instance.marginRead(
        epcNum: epcNum, strEPC: strEPC, memInt: memInt,
        address: address, matchLength: matchLength, matchData: matchData,
        password: password, maskMem: maskMem, btWordAdd: btWordAdd,
        maskLength: maskLength, maskData: maskData,
      );

  /// 认证 Impinj 标签，返回 AuthResult（code/random/response）
  Future<AuthResult?> authenticate({
    required String epc,
    required String password,
  }) =>
      RfidPlatform.instance.authenticate(epc: epc, password: password);

  /// 设置 PowerBoost（仅 Ex10，0=关/1=开）
  Future<int> setPowerBoost(int enable) =>
      RfidPlatform.instance.setPowerBoost(enable);

  /// 读取 PowerBoost 状态（仅 Ex10）
  Future<int> getPowerBoost() => RfidPlatform.instance.getPowerBoost();

  /// 设置 TagFocus（仅 Ex10，0=关/1=开）
  Future<int> setFocus(int mode) => RfidPlatform.instance.setFocus(mode);

  /// 读取 TagFocus 状态（仅 Ex10）
  Future<int> getFocus() => RfidPlatform.instance.getFocus();

  /// 设置 Impinj Scan 命令参数（仅 Ex10）
  Future<int> setImpinjScanParam({
    required int opt,
    required int n,
    required int code,
    required int cr,
    required int protection,
    required int id,
    required int copyTo,
  }) =>
      RfidPlatform.instance.setImpinjScanParam(
        opt: opt, n: n, code: code, cr: cr,
        protection: protection, id: id, copyTo: copyTo,
      );

  /// 读取 Impinj Scan 命令参数（仅 Ex10）
  Future<ImpinjScanParam?> getImpinjScanParam() =>
      RfidPlatform.instance.getImpinjScanParam();

  /// 设置多功能掩码（仅 Ex10，items 为空=清空，最多5组；matchType: 0=匹配/1=不匹配）
  Future<int> setInventoryMatchData({
    required int matchType,
    required List<MatchDataItem> items,
  }) =>
      RfidPlatform.instance.setInventoryMatchData(
          matchType: matchType, items: items);

  /// 启用/关闭 TagQuieting（仅 Ex10，opt: 0=掉电保存/1=不保存）
  Future<int> setTagQueting({required int opt, required int enable}) =>
      RfidPlatform.instance.setTagQueting(opt: opt, enable: enable);

  /// 读取 TagQuieting 状态（仅 Ex10）
  Future<int> getTagQueting() => RfidPlatform.instance.getTagQueting();

  /// 对标签设置隐私模式（enable: 0=禁用/1=启用）
  Future<int> protectedMode({
    required String epc,
    required int enable,
    required String password,
  }) =>
      RfidPlatform.instance.protectedMode(
          epc: epc, enable: enable, password: password);

  /// 设置读写器隐私模式（仅 Ex10，opt: 0=掉电保存/1=不保存）
  Future<int> setReaderProtectedMode({
    required int opt,
    required int enable,
    required String password,
  }) =>
      RfidPlatform.instance.setReaderProtectedMode(
          opt: opt, enable: enable, password: password);

  /// 读取读写器隐私模式状态（仅 Ex10）
  Future<ReaderProtectedModeResult?> getReaderProtectedMode() =>
      RfidPlatform.instance.getReaderProtectedMode();
}

