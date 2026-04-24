import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'rfid_method_channel.dart';

// ── 数据类 ────────────────────────────────────────────────────────────────────

/// RFID 标签读取结果
class TagReadResult {
  final int code;
  final String data;
  const TagReadResult({required this.code, required this.data});
}

/// 频率区域信息
class FrequencyRegionInfo {
  final int regionIndex;
  final String regionName;
  final int minChannelIndex;
  final int maxChannelIndex;
  final int channelCount;
  const FrequencyRegionInfo({
    required this.regionIndex,
    required this.regionName,
    required this.minChannelIndex,
    required this.maxChannelIndex,
    required this.channelCount,
  });
}

/// QueryMemoryBank 信息
class QueryMemBankInfo {
  final int area;
  final int startAddress;
  final int length;
  const QueryMemBankInfo({
    required this.area,
    required this.startAddress,
    required this.length,
  });
}

/// findEpc 查找标签结果
class FindEpcResult {
  final String epc;
  final int rssi;
  const FindEpcResult({required this.epc, required this.rssi});
}

/// 自定义频段信息
class CustomRegionInfo {
  final int band;
  final int freSpace;
  final int freNum;
  final int startFre;
  const CustomRegionInfo({
    required this.band,
    required this.freSpace,
    required this.freNum,
    required this.startFre,
  });
}

/// 离线缓存数量
class OfflineQueryNum {
  final int rfidCount;
  final int barcodeCount;
  const OfflineQueryNum({required this.rfidCount, required this.barcodeCount});
}

/// 离线数据内存占用百分比
class OfflineQueryMem {
  final double rfidPercent;
  final double barcodePercent;
  const OfflineQueryMem({required this.rfidPercent, required this.barcodePercent});
}

/// setInventoryMatchData 的单条掩码项
class MatchDataItem {
  /// 掩码数据（十六进制字符串）
  final String maskData;
  /// 存储区：0=Reserved, 1=EPC, 2=TID, 3=User
  final int memBank;
  /// 掩码起始位（bit 偏移）
  final int maskStart;
  /// 掩码长度（bit 数）
  final int maskLen;
  const MatchDataItem({
    required this.maskData,
    this.memBank = 1,
    this.maskStart = 0,
    required this.maskLen,
  });

  Map<String, dynamic> toMap() => {
    'maskData':  maskData,
    'memBank':   memBank,
    'maskStart': maskStart,
    'maskLen':   maskLen,
  };
}

/// Gen2x authenticate 认证结果
class AuthResult {
  final int code;
  final String? random;
  final String? response;
  const AuthResult({required this.code, this.random, this.response});
}

/// Impinj Scan 命令参数
class ImpinjScanParam {
  final int n;
  final int code;
  final int cr;
  final int protection;
  final int id;
  final int copyTo;
  const ImpinjScanParam({
    required this.n,
    required this.code,
    required this.cr,
    required this.protection,
    required this.id,
    required this.copyTo,
  });
}

/// 读写器隐私模式状态
class ReaderProtectedModeResult {
  final int enable;
  final String password;
  const ReaderProtectedModeResult({required this.enable, required this.password});
}

// ── 平台接口 ──────────────────────────────────────────────────────────────────

abstract class RfidPlatform extends PlatformInterface {
  RfidPlatform() : super(token: _token);

  static final Object _token = Object();
  static RfidPlatform _instance = MethodChannelRfid();

  static RfidPlatform get instance => _instance;

  static set instance(RfidPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // ── SDK 生命周期 ──────────────────────────────────────────────────────────

  /// 一体机/UART 设备初始化（无参）
  Future<int> initSdk() => throw UnimplementedError('initSdk()');

  /// 蓝牙设备初始化，传入 MAC 地址
  Future<int> initSdkBle(String mac) => throw UnimplementedError('initSdkBle()');

  Future<int> releaseSdk() => throw UnimplementedError('releaseSdk()');

  Future<bool> isConnected() => throw UnimplementedError('isConnected()');

  // ── 盘存 ──────────────────────────────────────────────────────────────────

  /// 持续盘存，直到调用 [stopInventory]
  Future<int> startInventory() => throw UnimplementedError('startInventory()');

  /// 带超时盘存，[timeout] 单位秒，到时自动停止
  Future<int> startInventoryWithTimeout(int timeout) =>
      throw UnimplementedError('startInventoryWithTimeout()');

  Future<int> stopInventory() => throw UnimplementedError('stopInventory()');

  Future<int> inventorySingle() => throw UnimplementedError('inventorySingle()');

  // ── 标签操作 ──────────────────────────────────────────────────────────────

  Future<TagReadResult> readTag({
    String? epc,
    required int memBank,
    required int wordAdd,
    required int wordCnt,
    String? password,
  }) => throw UnimplementedError('readTag()');

  Future<int> writeTag({
    String? epc,
    String? password,
    required int memBank,
    required int wordAdd,
    required String data,
  }) => throw UnimplementedError('writeTag()');

  Future<int> writeTagEpc({
    String? epc,
    String? password,
    required String newEpc,
  }) => throw UnimplementedError('writeTagEpc()');

  /// 随机改写一张标签的 EPC
  Future<int> writeEpc({String? epc, String? password}) =>
      throw UnimplementedError('writeEpc()');

  Future<int> killTag({String? epc, String? password}) =>
      throw UnimplementedError('killTag()');

  Future<int> lockTag({
    String? epc,
    String? password,
    required int memBank,
    required int lockType,
  }) => throw UnimplementedError('lockTag()');

  Future<int> lightUpLedTag({
    String? epc,
    String? password,
    int duration = 5000,
  }) => throw UnimplementedError('lightUpLedTag()');

  // ── 通过 TID 操作标签 ─────────────────────────────────────────────────────

  Future<String?> readDataByTid({
    required String tid,
    required int memBank,
    required int startAdd,
    required int wordCnt,
    String? password,
  }) => throw UnimplementedError('readDataByTid()');

  Future<int> writeTagByTid({
    required String tid,
    required int memBank,
    required int startAdd,
    String? password,
    required String data,
  }) => throw UnimplementedError('writeTagByTid()');

  Future<int> lockByTID({
    required String tid,
    required int lockBank,
    required int lockType,
    String? password,
  }) => throw UnimplementedError('lockByTID()');

  Future<int> killTagByTid({required String tid, String? password}) =>
      throw UnimplementedError('killTagByTid()');

  Future<int> writeTagEpcByTid({
    required String tid,
    String? password,
    required String newEpc,
  }) => throw UnimplementedError('writeTagEpcByTid()');

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
  }) => throw UnimplementedError('maskReadTag()');

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
  }) => throw UnimplementedError('maskWriteTag()');

  // ── 大容量标签 ────────────────────────────────────────────────────────────

  Future<TagReadResult> readTagExt({
    String? epc,
    required int memBank,
    required int startAdd,
    required int wordCnt,
    String? password,
  }) => throw UnimplementedError('readTagExt()');

  Future<int> writeTagExt({
    String? epc,
    String? password,
    required int memBank,
    required int startAdd,
    required String data,
  }) => throw UnimplementedError('writeTagExt()');

  Future<int> eraseTag({
    String? epc,
    String? password,
    required int memBank,
    required int startAdd,
    required int wordCnt,
  }) => throw UnimplementedError('eraseTag()');

  /// 查找标签，返回 EPC 和 RSSI
  Future<FindEpcResult?> findEpc(String epc) =>
      throw UnimplementedError('findEpc()');

  // ── LED 标签 ──────────────────────────────────────────────────────────────

  Future<int> startInventoryLed({
    required int manufacturers,
    required List<String> epcs,
  }) => throw UnimplementedError('startInventoryLed()');

  Future<int> stopInventoryLed() => throw UnimplementedError('stopInventoryLed()');

  // ── 掩码 ──────────────────────────────────────────────────────────────────

  /// 添加掩码，startAddress/len 单位为 bit（对应 SDK addMaskByBits）
  Future<int> addMask({
    required int mem,
    required int startAddress,
    required int len,
    required String data,
  }) => throw UnimplementedError('addMask()');

  /// 添加掩码，startAddress/len 单位为 word（对应 SDK addMask）
  Future<int> addMaskWord({
    required int mem,
    required int startAddress,
    required int len,
    required String data,
  }) => throw UnimplementedError('addMaskWord()');

  Future<int> clearMask() => throw UnimplementedError('clearMask()');

  // ── 功率与频率 ────────────────────────────────────────────────────────────

  Future<int> setOutputPower(int power) =>
      throw UnimplementedError('setOutputPower()');

  Future<int> getOutputPower() => throw UnimplementedError('getOutputPower()');

  Future<int> getSupportMaxOutputPower() =>
      throw UnimplementedError('getSupportMaxOutputPower()');

  Future<int> setFrequencyRegion({
    required int regionIndex,
    required int minChannelIndex,
    required int maxChannelIndex,
  }) => throw UnimplementedError('setFrequencyRegion()');

  Future<FrequencyRegionInfo?> getFrequencyRegion() =>
      throw UnimplementedError('getFrequencyRegion()');

  Future<List<String>> getSupportFrequencyBandList() =>
      throw UnimplementedError('getSupportFrequencyBandList()');

  /// 按国家/区域设置频段
  Future<int> setWorkRegion(int countryCodeIndex) =>
      throw UnimplementedError('setWorkRegion()');

  Future<int> getWorkRegion() => throw UnimplementedError('getWorkRegion()');

  Future<List<String>> getSupportWorkRegionList() =>
      throw UnimplementedError('getSupportWorkRegionList()');

  /// 设置自定义频段
  Future<int> setCustomRegion({
    required int band,
    required int freSpace,
    required int freNum,
    required int startFre,
  }) => throw UnimplementedError('setCustomRegion()');

  Future<CustomRegionInfo?> getCustomRegion() =>
      throw UnimplementedError('getCustomRegion()');

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<int> setProfile(int profileIndex) =>
      throw UnimplementedError('setProfile()');

  Future<int> getProfile() => throw UnimplementedError('getProfile()');

  Future<List<String>> getSupportProfileList() =>
      throw UnimplementedError('getSupportProfileList()');

  // ── 盘存参数 ──────────────────────────────────────────────────────────────

  Future<int> setInventoryWithTarget(int target) =>
      throw UnimplementedError('setInventoryWithTarget()');

  Future<int> getInventoryWithTarget() =>
      throw UnimplementedError('getInventoryWithTarget()');

  Future<int> setInventoryWithSession(int session) =>
      throw UnimplementedError('setInventoryWithSession()');

  Future<int> getInventoryWithSession() =>
      throw UnimplementedError('getInventoryWithSession()');

  Future<int> setInventoryWithStartQvalue(int qvalue) =>
      throw UnimplementedError('setInventoryWithStartQvalue()');

  Future<int> getInventoryWithStartQvalue() =>
      throw UnimplementedError('getInventoryWithStartQvalue()');

  Future<int> setInventoryWithPassword(String password) =>
      throw UnimplementedError('setInventoryWithPassword()');

  Future<String?> getInventoryWithPassword() =>
      throw UnimplementedError('getInventoryWithPassword()');

  Future<int> setQueryMemoryBank({
    required int area,
    required int startAddress,
    required int length,
  }) => throw UnimplementedError('setQueryMemoryBank()');

  Future<QueryMemBankInfo?> getQueryMemoryBank() =>
      throw UnimplementedError('getQueryMemoryBank()');

  Future<int> setInventorySceneMode(int mode) =>
      throw UnimplementedError('setInventorySceneMode()');

  Future<int> getInventorySceneMode() =>
      throw UnimplementedError('getInventorySceneMode()');

  Future<int> setInventoryRssiLimit(int limit) =>
      throw UnimplementedError('setInventoryRssiLimit()');

  Future<int> getInventoryRssiLimit() =>
      throw UnimplementedError('getInventoryRssiLimit()');

  Future<bool> isSupportInventoryRssiLimit() =>
      throw UnimplementedError('isSupportInventoryRssiLimit()');

  Future<int> setRssiInDbm(bool enable) =>
      throw UnimplementedError('setRssiInDbm()');

  Future<int> setInventoryPhaseFlag(bool enable) =>
      throw UnimplementedError('setInventoryPhaseFlag()');

  Future<bool> getInventoryPhaseFlag() =>
      throw UnimplementedError('getInventoryPhaseFlag()');

  // ── 设备信息 ──────────────────────────────────────────────────────────────

  Future<String?> getFirmwareVersion() =>
      throw UnimplementedError('getFirmwareVersion()');

  Future<String?> getDeviceId() => throw UnimplementedError('getDeviceId()');

  Future<int> getReaderType() => throw UnimplementedError('getReaderType()');

  Future<String?> getEx10Version() => throw UnimplementedError('getEx10Version()');

  Future<String?> getReaderTemperature() =>
      throw UnimplementedError('getReaderTemperature()');

  /// 获取当前连接的设备类型（一体机/串口/蓝牙）
  Future<int> getReaderDeviceType() =>
      throw UnimplementedError('getReaderDeviceType()');

  /// 获取当前 RFID 模块型号（U1~U5）
  Future<int> getModuleType() => throw UnimplementedError('getModuleType()');

  Future<int> setTagFocus(int enable) =>
      throw UnimplementedError('setTagFocus()');

  Future<int> getTagFocus() => throw UnimplementedError('getTagFocus()');

  Future<int> setBaudRate(int baudRate) =>
      throw UnimplementedError('setBaudRate()');

  Future<int> getBaudRate() => throw UnimplementedError('getBaudRate()');

  Future<int> setBeepEnable(bool enable) =>
      throw UnimplementedError('setBeepEnable()');

  // ── GripDevice ────────────────────────────────────────────────────────────

  Future<int> getBatteryLevel() => throw UnimplementedError('getBatteryLevel()');

  Future<int> getBatteryIsCharging() =>
      throw UnimplementedError('getBatteryIsCharging()');

  Future<String?> getVersionSystem() =>
      throw UnimplementedError('getVersionSystem()');

  Future<String?> getVersionBLE() => throw UnimplementedError('getVersionBLE()');

  Future<String?> getVersionMcu() => throw UnimplementedError('getVersionMcu()');

  Future<String?> getVersionRfid() => throw UnimplementedError('getVersionRfid()');

  Future<String?> getDeviceSN() => throw UnimplementedError('getDeviceSN()');

  Future<String?> getBLEMac() => throw UnimplementedError('getBLEMac()');

  Future<int> getScanMode() => throw UnimplementedError('getScanMode()');

  Future<int> startScanBarcode(bool start) =>
      throw UnimplementedError('startScanBarcode()');

  Future<int> setBeepRange(int volume) =>
      throw UnimplementedError('setBeepRange()');

  Future<int> getBeepRange() => throw UnimplementedError('getBeepRange()');

  Future<int> setSleepTime(int seconds) =>
      throw UnimplementedError('setSleepTime()');

  Future<int> getSleepTime() => throw UnimplementedError('getSleepTime()');

  Future<int> setPowerOffTime(int seconds) =>
      throw UnimplementedError('setPowerOffTime()');

  Future<int> getPowerOffTime() => throw UnimplementedError('getPowerOffTime()');

  Future<int> setOfflineModeOpen(int enable) =>
      throw UnimplementedError('setOfflineModeOpen()');

  Future<int> getOfflineModeOpen() =>
      throw UnimplementedError('getOfflineModeOpen()');

  Future<int> setOfflineTransferClearData(int enable) =>
      throw UnimplementedError('setOfflineTransferClearData()');

  Future<int> getOfflineTransferClearData() =>
      throw UnimplementedError('getOfflineTransferClearData()');

  Future<int> setOfflineTransferDelay(int ms) =>
      throw UnimplementedError('setOfflineTransferDelay()');

  Future<OfflineQueryNum?> getOfflineQueryNum() =>
      throw UnimplementedError('getOfflineQueryNum()');

  Future<OfflineQueryMem?> getOfflineQueryMem() =>
      throw UnimplementedError('getOfflineQueryMem()');

  Future<int> offlineManaulClearScanData() =>
      throw UnimplementedError('offlineManaulClearScanData()');

  Future<int> offlineManaulClearRFIDData() =>
      throw UnimplementedError('offlineManaulClearRFIDData()');

  Future<int> offlineStartTransferRFID() =>
      throw UnimplementedError('offlineStartTransferRFID()');

  Future<int> offlineStartTransferScan() =>
      throw UnimplementedError('offlineStartTransferScan()');

  Future<int> modeResetFactory() => throw UnimplementedError('modeResetFactory()');

  // ── 固件升级 ──────────────────────────────────────────────────────────────

  /// 一体机 RFID 模块升级（文件路径）
  Future<void> updateReaderFirmwareByFile({
    required String binName,
    required String binPath,
  }) => throw UnimplementedError('updateReaderFirmwareByFile()');

  /// 一体机 RFID 模块升级（字节流）
  Future<void> updateReaderFirmwareByByte({
    required String binName,
    required Uint8List data,
  }) => throw UnimplementedError('updateReaderFirmwareByByte()');

  /// 一体机 RFID 芯片升级（文件路径）
  Future<void> updateEx10ChipFirmwareByFile({required String binPath}) =>
      throw UnimplementedError('updateEx10ChipFirmwareByFile()');

  /// 一体机 RFID 芯片升级（字节流）
  Future<void> updateEx10ChipFirmwareByByte({required Uint8List data}) =>
      throw UnimplementedError('updateEx10ChipFirmwareByByte()');

  /// 蓝牙设备 RFID 模块升级（文件路径）
  Future<void> updateBLEReaderFirmwareByFile({
    required String mac,
    required String binName,
    required String binPath,
  }) => throw UnimplementedError('updateBLEReaderFirmwareByFile()');

  /// 蓝牙设备 RFID 模块升级（字节流）
  Future<void> updateBLEReaderFirmwareByByte({
    required String mac,
    required String binName,
    required Uint8List data,
  }) => throw UnimplementedError('updateBLEReaderFirmwareByByte()');

  /// 蓝牙设备 RFID 芯片升级（文件路径）
  Future<void> updateBLEEx10ChipFirmwareByFile({
    required String mac,
    required String binName,
    required String binPath,
  }) => throw UnimplementedError('updateBLEEx10ChipFirmwareByFile()');

  /// 蓝牙设备 RFID 芯片升级（字节流）— SDK 无 binName 参数
  Future<void> updateBLEEx10ChipFirmwareByByte({
    required String mac,
    required Uint8List data,
  }) => throw UnimplementedError('updateBLEEx10ChipFirmwareByByte()');

  // ── Gen2x ────────────────────────────────────────────────────────────────

  /// 设置 Gen2x Profile（需先设置才能使用 Gen2x 特性）
  Future<int> setExtProfile(int profile) =>
      throw UnimplementedError('setExtProfile()');

  Future<int> getExtProfile() => throw UnimplementedError('getExtProfile()');

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
  }) => throw UnimplementedError('setShortRangeFlag()');

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
  }) => throw UnimplementedError('getShortRangeFlag()');

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
  }) => throw UnimplementedError('marginRead()');

  /// 认证 Impinj 标签，返回 {code, random, response}
  Future<AuthResult?> authenticate({
    required String epc,
    required String password,
  }) => throw UnimplementedError('authenticate()');

  /// 设置 PowerBoost（仅 Ex10，0=关/1=开）
  Future<int> setPowerBoost(int enable) =>
      throw UnimplementedError('setPowerBoost()');

  /// 读取 PowerBoost 状态（仅 Ex10）
  Future<int> getPowerBoost() => throw UnimplementedError('getPowerBoost()');

  /// 设置 TagFocus（仅 Ex10，0=关/1=开）
  Future<int> setFocus(int mode) => throw UnimplementedError('setFocus()');

  /// 读取 TagFocus 状态（仅 Ex10）
  Future<int> getFocus() => throw UnimplementedError('getFocus()');

  /// 设置 Impinj Scan 命令参数（仅 Ex10）
  Future<int> setImpinjScanParam({
    required int opt,
    required int n,
    required int code,
    required int cr,
    required int protection,
    required int id,
    required int copyTo,
  }) => throw UnimplementedError('setImpinjScanParam()');

  /// 读取 Impinj Scan 命令参数（仅 Ex10）
  Future<ImpinjScanParam?> getImpinjScanParam() =>
      throw UnimplementedError('getImpinjScanParam()');

  /// 设置多功能掩码（仅 Ex10，items 为空=清空，最多5组）
  Future<int> setInventoryMatchData({
    required int matchType,
    required List<MatchDataItem> items,
  }) => throw UnimplementedError('setInventoryMatchData()');

  /// 启用/关闭 TagQuieting（仅 Ex10）
  Future<int> setTagQueting({
    required int opt,
    required int enable,
  }) => throw UnimplementedError('setTagQueting()');

  /// 读取 TagQuieting 状态（仅 Ex10）
  Future<int> getTagQueting() => throw UnimplementedError('getTagQueting()');

  /// 对标签设置隐私模式
  Future<int> protectedMode({
    required String epc,
    required int enable,
    required String password,
  }) => throw UnimplementedError('protectedMode()');

  /// 设置读写器隐私模式（仅 Ex10）
  Future<int> setReaderProtectedMode({
    required int opt,
    required int enable,
    required String password,
  }) => throw UnimplementedError('setReaderProtectedMode()');

  /// 读取读写器隐私模式状态（仅 Ex10）
  Future<ReaderProtectedModeResult?> getReaderProtectedMode() =>
      throw UnimplementedError('getReaderProtectedMode()');
}
