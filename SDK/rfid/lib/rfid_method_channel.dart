import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'rfid_platform_interface.dart';

/// MethodChannel 实现，与 Android RfidPlugin 通信
class MethodChannelRfid extends RfidPlatform {
  static const _mc = MethodChannel('rfid');

  // ── SDK 生命周期 ──────────────────────────────────────────────────────────

  @override
  Future<int> initSdk() async =>
      await _mc.invokeMethod<int>('initSdk') ?? -1;

  @override
  Future<int> initSdkBle(String mac) async =>
      await _mc.invokeMethod<int>('initSdkBle', {'mac': mac}) ?? -1;

  @override
  Future<int> releaseSdk() async =>
      await _mc.invokeMethod<int>('releaseSdk') ?? -1;

  @override
  Future<bool> isConnected() async =>
      await _mc.invokeMethod<bool>('isConnected') ?? false;

  // ── 盘存 ──────────────────────────────────────────────────────────────────

  @override
  Future<int> startInventory() async =>
      await _mc.invokeMethod<int>('startInventory') ?? -1;

  @override
  Future<int> startInventoryWithTimeout(int timeout) async =>
      await _mc.invokeMethod<int>('startInventory', {'timeout': timeout}) ?? -1;

  @override
  Future<int> stopInventory() async =>
      await _mc.invokeMethod<int>('stopInventory') ?? -1;

  @override
  Future<int> inventorySingle() async =>
      await _mc.invokeMethod<int>('inventorySingle') ?? -1;

  // ── 标签操作 ──────────────────────────────────────────────────────────────

  @override
  Future<TagReadResult> readTag({
    String? epc,
    required int memBank,
    required int wordAdd,
    required int wordCnt,
    String? password,
  }) async {
    final raw = await _mc.invokeMapMethod<String, dynamic>('readTag', {
      'epc': epc,
      'memBank': memBank,
      'wordAdd': wordAdd,
      'wordCnt': wordCnt,
      'password': password,
    });
    return TagReadResult(
      code: (raw?['code'] as int?) ?? -1,
      data: (raw?['data'] as String?) ?? '',
    );
  }

  @override
  Future<int> writeTag({
    String? epc,
    String? password,
    required int memBank,
    required int wordAdd,
    required String data,
  }) async =>
      await _mc.invokeMethod<int>('writeTag', {
        'epc': epc,
        'password': password,
        'memBank': memBank,
        'wordAdd': wordAdd,
        'data': data,
      }) ?? -1;

  @override
  Future<int> writeTagEpc({
    String? epc,
    String? password,
    required String newEpc,
  }) async =>
      await _mc.invokeMethod<int>('writeTagEpc', {
        'epc': epc,
        'password': password,
        'newEpc': newEpc,
      }) ?? -1;

  @override
  Future<int> writeEpc({String? epc, String? password}) async =>
      await _mc.invokeMethod<int>('writeEpc', {
        'epc': epc,
        'password': password,
      }) ?? -1;

  @override
  Future<int> killTag({String? epc, String? password}) async =>
      await _mc.invokeMethod<int>('killTag', {
        'epc': epc,
        'password': password,
      }) ?? -1;

  @override
  Future<int> lockTag({
    String? epc,
    String? password,
    required int memBank,
    required int lockType,
  }) async =>
      await _mc.invokeMethod<int>('lockTag', {
        'epc': epc,
        'password': password,
        'memBank': memBank,
        'lockType': lockType,
      }) ?? -1;

  @override
  Future<int> lightUpLedTag({
    String? epc,
    String? password,
    int duration = 5000,
  }) async =>
      await _mc.invokeMethod<int>('lightUpLedTag', {
        'epc': epc,
        'password': password,
        'duration': duration,
      }) ?? -1;

  // ── 通过 TID 操作标签 ─────────────────────────────────────────────────────

  @override
  Future<String?> readDataByTid({
    required String tid,
    required int memBank,
    required int startAdd,
    required int wordCnt,
    String? password,
  }) async =>
      await _mc.invokeMethod<String>('readDataByTid', {
        'tid': tid,
        'memBank': memBank,
        'startAdd': startAdd,
        'wordCnt': wordCnt,
        'password': password,
      });

  @override
  Future<int> writeTagByTid({
    required String tid,
    required int memBank,
    required int startAdd,
    String? password,
    required String data,
  }) async =>
      await _mc.invokeMethod<int>('writeTagByTid', {
        'tid': tid,
        'memBank': memBank,
        'startAdd': startAdd,
        'password': password,
        'data': data,
      }) ?? -1;

  @override
  Future<int> lockByTID({
    required String tid,
    required int lockBank,
    required int lockType,
    String? password,
  }) async =>
      await _mc.invokeMethod<int>('lockByTID', {
        'tid': tid,
        'lockBank': lockBank,
        'lockType': lockType,
        'password': password,
      }) ?? -1;

  @override
  Future<int> killTagByTid({required String tid, String? password}) async =>
      await _mc.invokeMethod<int>('killTagByTid', {
        'tid': tid,
        'password': password,
      }) ?? -1;

  @override
  Future<int> writeTagEpcByTid({
    required String tid,
    String? password,
    required String newEpc,
  }) async =>
      await _mc.invokeMethod<int>('writeTagEpcByTid', {
        'tid': tid,
        'password': password,
        'newEpc': newEpc,
      }) ?? -1;

  // ── 带掩码操作 ────────────────────────────────────────────────────────────

  @override
  Future<TagReadResult> maskReadTag({
    required int memBank,
    required int startAdd,
    required int wordCnt,
    String? password,
    required int memMask,
    required int startMask,
    required int lenMask,
    required String dataMask,
  }) async {
    final raw = await _mc.invokeMapMethod<String, dynamic>('maskReadTag', {
      'memBank': memBank,
      'startAdd': startAdd,
      'wordCnt': wordCnt,
      'password': password,
      'memMask': memMask,
      'startMask': startMask,
      'lenMask': lenMask,
      'dataMask': dataMask,
    });
    return TagReadResult(
      code: (raw?['code'] as int?) ?? -1,
      data: (raw?['data'] as String?) ?? '',
    );
  }

  @override
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
  }) async =>
      await _mc.invokeMethod<int>('maskWriteTag', {
        'data': data,
        'memBank': memBank,
        'startAdd': startAdd,
        'wordCnt': wordCnt,
        'password': password,
        'memMask': memMask,
        'startMask': startMask,
        'lenMask': lenMask,
        'dataMask': dataMask,
      }) ?? -1;

  // ── 大容量标签 ────────────────────────────────────────────────────────────

  @override
  Future<TagReadResult> readTagExt({
    String? epc,
    required int memBank,
    required int startAdd,
    required int wordCnt,
    String? password,
  }) async {
    final raw = await _mc.invokeMapMethod<String, dynamic>('readTagExt', {
      'epc': epc,
      'memBank': memBank,
      'startAdd': startAdd,
      'wordCnt': wordCnt,
      'password': password,
    });
    return TagReadResult(
      code: (raw?['code'] as int?) ?? -1,
      data: (raw?['data'] as String?) ?? '',
    );
  }

  @override
  Future<int> writeTagExt({
    String? epc,
    String? password,
    required int memBank,
    required int startAdd,
    required String data,
  }) async =>
      await _mc.invokeMethod<int>('writeTagExt', {
        'epc': epc,
        'password': password,
        'memBank': memBank,
        'startAdd': startAdd,
        'data': data,
      }) ?? -1;

  @override
  Future<int> eraseTag({
    String? epc,
    String? password,
    required int memBank,
    required int startAdd,
    required int wordCnt,
  }) async =>
      await _mc.invokeMethod<int>('eraseTag', {
        'epc': epc,
        'password': password,
        'memBank': memBank,
        'startAdd': startAdd,
        'wordCnt': wordCnt,
      }) ?? -1;

  @override
  Future<FindEpcResult?> findEpc(String epc) async {
    final raw = await _mc.invokeMapMethod<String, dynamic>('findEpc', {'epc': epc});
    if (raw == null) return null;
    return FindEpcResult(
      epc: (raw['epc'] as String?) ?? '',
      rssi: (raw['rssi'] as int?) ?? 0,
    );
  }

  // ── LED 标签 ──────────────────────────────────────────────────────────────

  @override
  Future<int> startInventoryLed({
    required int manufacturers,
    required List<String> epcs,
  }) async =>
      await _mc.invokeMethod<int>('startInventoryLed', {
        'manufacturers': manufacturers,
        'epcs': epcs,
      }) ?? -1;

  @override
  Future<int> stopInventoryLed() async =>
      await _mc.invokeMethod<int>('stopInventoryLed') ?? -1;

  // ── 掩码 ──────────────────────────────────────────────────────────────────

  @override
  Future<int> addMask({
    required int mem,
    required int startAddress,
    required int len,
    required String data,
  }) async =>
      await _mc.invokeMethod<int>('addMask', {
        'mem': mem,
        'startAddress': startAddress,
        'len': len,
        'data': data,
      }) ?? -1;

  @override
  Future<int> addMaskWord({
    required int mem,
    required int startAddress,
    required int len,
    required String data,
  }) async =>
      await _mc.invokeMethod<int>('addMaskWord', {
        'mem': mem,
        'startAddress': startAddress,
        'len': len,
        'data': data,
      }) ?? -1;

  @override
  Future<int> clearMask() async =>
      await _mc.invokeMethod<int>('clearMask') ?? -1;

  // ── 功率与频率 ────────────────────────────────────────────────────────────

  @override
  Future<int> setOutputPower(int power) async =>
      await _mc.invokeMethod<int>('setOutputPower', {'power': power}) ?? -1;

  @override
  Future<int> getOutputPower() async =>
      await _mc.invokeMethod<int>('getOutputPower') ?? -1;

  @override
  Future<int> getSupportMaxOutputPower() async =>
      await _mc.invokeMethod<int>('getSupportMaxOutputPower') ?? -1;

  @override
  Future<int> setFrequencyRegion({
    required int regionIndex,
    required int minChannelIndex,
    required int maxChannelIndex,
  }) async =>
      await _mc.invokeMethod<int>('setFrequencyRegion', {
        'regionIndex': regionIndex,
        'minChannelIndex': minChannelIndex,
        'maxChannelIndex': maxChannelIndex,
      }) ?? -1;

  @override
  Future<FrequencyRegionInfo?> getFrequencyRegion() async {
    final raw = await _mc.invokeMapMethod<String, dynamic>('getFrequencyRegion');
    if (raw == null) return null;
    return FrequencyRegionInfo(
      regionIndex: (raw['regionIndex'] as int?) ?? -1,
      regionName: (raw['regionName'] as String?) ?? '',
      minChannelIndex: (raw['minChannelIndex'] as int?) ?? 0,
      maxChannelIndex: (raw['maxChannelIndex'] as int?) ?? 0,
      channelCount: (raw['channelCount'] as int?) ?? 0,
    );
  }

  @override
  Future<List<String>> getSupportFrequencyBandList() async {
    final raw = await _mc.invokeListMethod<String>('getSupportFrequencyBandList');
    return raw ?? [];
  }

  @override
  Future<int> setWorkRegion(int countryCodeIndex) async =>
      await _mc.invokeMethod<int>('setWorkRegion', {'countryCodeIndex': countryCodeIndex}) ?? -1;

  @override
  Future<int> getWorkRegion() async =>
      await _mc.invokeMethod<int>('getWorkRegion') ?? -1;

  @override
  Future<List<String>> getSupportWorkRegionList() async {
    final raw = await _mc.invokeListMethod<String>('getSupportWorkRegionList');
    return raw ?? [];
  }

  @override
  Future<int> setCustomRegion({
    required int band,
    required int freSpace,
    required int freNum,
    required int startFre,
  }) async =>
      await _mc.invokeMethod<int>('setCustomRegion', {
        'band': band,
        'freSpace': freSpace,
        'freNum': freNum,
        'startFre': startFre,
      }) ?? -1;

  @override
  Future<CustomRegionInfo?> getCustomRegion() async {
    final raw = await _mc.invokeMapMethod<String, dynamic>('getCustomRegion');
    if (raw == null) return null;
    return CustomRegionInfo(
      band: (raw['band'] as int?) ?? 0,
      freSpace: (raw['freSpace'] as int?) ?? 0,
      freNum: (raw['freNum'] as int?) ?? 0,
      startFre: (raw['startFre'] as int?) ?? 0,
    );
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  @override
  Future<int> setProfile(int profileIndex) async =>
      await _mc.invokeMethod<int>('setProfile', {'profileIndex': profileIndex}) ?? -1;

  @override
  Future<int> getProfile() async =>
      await _mc.invokeMethod<int>('getProfile') ?? -1;

  @override
  Future<List<String>> getSupportProfileList() async {
    final raw = await _mc.invokeListMethod<String>('getSupportProfileList');
    return raw ?? [];
  }

  // ── 盘存参数 ──────────────────────────────────────────────────────────────

  @override
  Future<int> setInventoryWithTarget(int target) async =>
      await _mc.invokeMethod<int>('setInventoryWithTarget', {'target': target}) ?? -1;

  @override
  Future<int> getInventoryWithTarget() async =>
      await _mc.invokeMethod<int>('getInventoryWithTarget') ?? -1;

  @override
  Future<int> setInventoryWithSession(int session) async =>
      await _mc.invokeMethod<int>('setInventoryWithSession', {'session': session}) ?? -1;

  @override
  Future<int> getInventoryWithSession() async =>
      await _mc.invokeMethod<int>('getInventoryWithSession') ?? -1;

  @override
  Future<int> setInventoryWithStartQvalue(int qvalue) async =>
      await _mc.invokeMethod<int>('setInventoryWithStartQvalue', {'qvalue': qvalue}) ?? -1;

  @override
  Future<int> getInventoryWithStartQvalue() async =>
      await _mc.invokeMethod<int>('getInventoryWithStartQvalue') ?? -1;

  @override
  Future<int> setInventoryWithPassword(String password) async =>
      await _mc.invokeMethod<int>('setInventoryWithPassword', {'password': password}) ?? -1;

  @override
  Future<String?> getInventoryWithPassword() async =>
      await _mc.invokeMethod<String>('getInventoryWithPassword');

  @override
  Future<int> setQueryMemoryBank({
    required int area,
    required int startAddress,
    required int length,
  }) async =>
      await _mc.invokeMethod<int>('setQueryMemoryBank', {
        'area': area,
        'startAddress': startAddress,
        'length': length,
      }) ?? -1;

  @override
  Future<QueryMemBankInfo?> getQueryMemoryBank() async {
    final raw = await _mc.invokeMapMethod<String, dynamic>('getQueryMemoryBank');
    if (raw == null) return null;
    return QueryMemBankInfo(
      area: (raw['area'] as int?) ?? 0,
      startAddress: (raw['startAddress'] as int?) ?? 0,
      length: (raw['length'] as int?) ?? 0,
    );
  }

  @override
  Future<int> setInventorySceneMode(int mode) async =>
      await _mc.invokeMethod<int>('setInventorySceneMode', {'mode': mode}) ?? -1;

  @override
  Future<int> getInventorySceneMode() async =>
      await _mc.invokeMethod<int>('getInventorySceneMode') ?? -1;

  @override
  Future<int> setInventoryRssiLimit(int limit) async =>
      await _mc.invokeMethod<int>('setInventoryRssiLimit', {'limit': limit}) ?? -1;

  @override
  Future<int> getInventoryRssiLimit() async =>
      await _mc.invokeMethod<int>('getInventoryRssiLimit') ?? -1;

  @override
  Future<bool> isSupportInventoryRssiLimit() async =>
      await _mc.invokeMethod<bool>('isSupportInventoryRssiLimit') ?? false;

  @override
  Future<int> setRssiInDbm(bool enable) async =>
      await _mc.invokeMethod<int>('setRssiInDbm', {'enable': enable}) ?? -1;

  @override
  Future<int> setInventoryPhaseFlag(bool enable) async =>
      await _mc.invokeMethod<int>('setInventoryPhaseFlag', {'enable': enable}) ?? -1;

  @override
  Future<bool> getInventoryPhaseFlag() async =>
      await _mc.invokeMethod<bool>('getInventoryPhaseFlag') ?? false;

  // ── 设备信息 ──────────────────────────────────────────────────────────────

  @override
  Future<String?> getFirmwareVersion() async =>
      await _mc.invokeMethod<String>('getFirmwareVersion');

  @override
  Future<String?> getDeviceId() async =>
      await _mc.invokeMethod<String>('getDeviceId');

  @override
  Future<int> getReaderType() async =>
      await _mc.invokeMethod<int>('getReaderType') ?? -1;

  @override
  Future<String?> getEx10Version() async =>
      await _mc.invokeMethod<String>('getEx10Version');

  @override
  Future<String?> getReaderTemperature() async =>
      await _mc.invokeMethod<String>('getReaderTemperature');

  @override
  Future<int> getReaderDeviceType() async =>
      await _mc.invokeMethod<int>('getReaderDeviceType') ?? -1;

  @override
  Future<int> getModuleType() async =>
      await _mc.invokeMethod<int>('getModuleType') ?? -1;

  @override
  Future<int> setTagFocus(int enable) async =>
      await _mc.invokeMethod<int>('setTagFocus', {'enable': enable}) ?? -1;

  @override
  Future<int> getTagFocus() async =>
      await _mc.invokeMethod<int>('getTagFocus') ?? -1;

  @override
  Future<int> setBaudRate(int baudRate) async =>
      await _mc.invokeMethod<int>('setBaudRate', {'baudRate': baudRate}) ?? -1;

  @override
  Future<int> getBaudRate() async =>
      await _mc.invokeMethod<int>('getBaudRate') ?? -1;

  @override
  Future<int> setBeepEnable(bool enable) async =>
      await _mc.invokeMethod<int>('setBeepEnable', {'enable': enable}) ?? -1;

  // ── GripDevice ────────────────────────────────────────────────────────────

  @override
  Future<int> getBatteryLevel() async =>
      await _mc.invokeMethod<int>('getBatteryLevel') ?? -1;

  @override
  Future<int> getBatteryIsCharging() async =>
      await _mc.invokeMethod<int>('getBatteryIsCharging') ?? -1;

  @override
  Future<String?> getVersionSystem() async =>
      await _mc.invokeMethod<String>('getVersionSystem');

  @override
  Future<String?> getVersionBLE() async =>
      await _mc.invokeMethod<String>('getVersionBLE');

  @override
  Future<String?> getVersionMcu() async =>
      await _mc.invokeMethod<String>('getVersionMcu');

  @override
  Future<String?> getVersionRfid() async =>
      await _mc.invokeMethod<String>('getVersionRfid');

  @override
  Future<String?> getDeviceSN() async =>
      await _mc.invokeMethod<String>('getDeviceSN');

  @override
  Future<String?> getBLEMac() async =>
      await _mc.invokeMethod<String>('getBLEMac');

  @override
  Future<int> getScanMode() async =>
      await _mc.invokeMethod<int>('getScanMode') ?? -1;

  @override
  Future<int> startScanBarcode(bool start) async =>
      await _mc.invokeMethod<int>('startScanBarcode', {'start': start}) ?? -1;

  @override
  Future<int> setBeepRange(int volume) async =>
      await _mc.invokeMethod<int>('setBeepRange', {'volume': volume}) ?? -1;

  @override
  Future<int> getBeepRange() async =>
      await _mc.invokeMethod<int>('getBeepRange') ?? -1;

  @override
  Future<int> setSleepTime(int seconds) async =>
      await _mc.invokeMethod<int>('setSleepTime', {'seconds': seconds}) ?? -1;

  @override
  Future<int> getSleepTime() async =>
      await _mc.invokeMethod<int>('getSleepTime') ?? -1;

  @override
  Future<int> setPowerOffTime(int seconds) async =>
      await _mc.invokeMethod<int>('setPowerOffTime', {'seconds': seconds}) ?? -1;

  @override
  Future<int> getPowerOffTime() async =>
      await _mc.invokeMethod<int>('getPowerOffTime') ?? -1;

  @override
  Future<int> setOfflineModeOpen(int enable) async =>
      await _mc.invokeMethod<int>('setOfflineModeOpen', {'enable': enable}) ?? -1;

  @override
  Future<int> getOfflineModeOpen() async =>
      await _mc.invokeMethod<int>('getOfflineModeOpen') ?? -1;

  @override
  Future<int> setOfflineTransferClearData(int enable) async =>
      await _mc.invokeMethod<int>('setOfflineTransferClearData', {'enable': enable}) ?? -1;

  @override
  Future<int> getOfflineTransferClearData() async =>
      await _mc.invokeMethod<int>('getOfflineTransferClearData') ?? -1;

  @override
  Future<int> setOfflineTransferDelay(int ms) async =>
      await _mc.invokeMethod<int>('setOfflineTransferDelay', {'ms': ms}) ?? -1;

  @override
  Future<OfflineQueryNum?> getOfflineQueryNum() async {
    final raw = await _mc.invokeMapMethod<String, dynamic>('getOfflineQueryNum');
    if (raw == null) return null;
    return OfflineQueryNum(
      rfidCount: (raw['rfidCount'] as int?) ?? 0,
      barcodeCount: (raw['barcodeCount'] as int?) ?? 0,
    );
  }

  @override
  Future<OfflineQueryMem?> getOfflineQueryMem() async {
    final raw = await _mc.invokeMapMethod<String, dynamic>('getOfflineQueryMem');
    if (raw == null) return null;
    return OfflineQueryMem(
      rfidPercent: (raw['rfidPercent'] as num?)?.toDouble() ?? 0.0,
      barcodePercent: (raw['barcodePercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Future<int> offlineManaulClearScanData() async =>
      await _mc.invokeMethod<int>('offlineManaulClearScanData') ?? -1;

  @override
  Future<int> offlineManaulClearRFIDData() async =>
      await _mc.invokeMethod<int>('offlineManaulClearRFIDData') ?? -1;

  @override
  Future<int> offlineStartTransferRFID() async =>
      await _mc.invokeMethod<int>('offlineStartTransferRFID') ?? -1;

  @override
  Future<int> offlineStartTransferScan() async =>
      await _mc.invokeMethod<int>('offlineStartTransferScan') ?? -1;

  @override
  Future<int> modeResetFactory() async =>
      await _mc.invokeMethod<int>('modeResetFactory') ?? -1;

  // ── 固件升级（进度通过 EventChannel event_fw_update 回调） ─────────────────

  @override
  Future<void> updateReaderFirmwareByFile({
    required String binName,
    required String binPath,
  }) =>
      _mc.invokeMethod('updateReaderFirmwareByFile', {
        'binName': binName,
        'binPath': binPath,
      });

  @override
  Future<void> updateReaderFirmwareByByte({
    required String binName,
    required Uint8List data,
  }) =>
      _mc.invokeMethod('updateReaderFirmwareByByte', {
        'binName': binName,
        'data': data,
      });

  @override
  Future<void> updateEx10ChipFirmwareByFile({required String binPath}) =>
      _mc.invokeMethod('updateEx10ChipFirmwareByFile', {'binPath': binPath});

  @override
  Future<void> updateEx10ChipFirmwareByByte({required Uint8List data}) =>
      _mc.invokeMethod('updateEx10ChipFirmwareByByte', {'data': data});

  @override
  Future<void> updateBLEReaderFirmwareByFile({
    required String mac,
    required String binName,
    required String binPath,
  }) =>
      _mc.invokeMethod('updateBLEReaderFirmwareByFile', {
        'mac': mac,
        'binName': binName,
        'binPath': binPath,
      });

  @override
  Future<void> updateBLEReaderFirmwareByByte({
    required String mac,
    required String binName,
    required Uint8List data,
  }) =>
      _mc.invokeMethod('updateBLEReaderFirmwareByByte', {
        'mac': mac,
        'binName': binName,
        'data': data,
      });

  @override
  Future<void> updateBLEEx10ChipFirmwareByFile({
    required String mac,
    required String binName,
    required String binPath,
  }) =>
      _mc.invokeMethod('updateBLEEx10ChipFirmwareByFile', {
        'mac': mac,
        'binName': binName,
        'binPath': binPath,
      });

  @override
  Future<void> updateBLEEx10ChipFirmwareByByte({
    required String mac,
    required Uint8List data,
  }) =>
      _mc.invokeMethod('updateBLEEx10ChipFirmwareByByte', {
        'mac': mac,
        'data': data,
      });

  // ── Gen2x ────────────────────────────────────────────────────────────────

  @override
  Future<int> setExtProfile(int profile) async =>
      await _mc.invokeMethod<int>('setExtProfile', {'profile': profile}) ?? -1;

  @override
  Future<int> getExtProfile() async =>
      await _mc.invokeMethod<int>('getExtProfile') ?? -1;

  @override
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
  }) async =>
      await _mc.invokeMethod<int>('setShortRangeFlag', {
        'epcNum': epcNum, 'strEPC': strEPC, 'password': password,
        'maskMem': maskMem, 'btWordAdd': btWordAdd, 'maskLength': maskLength,
        'maskData': maskData, 'srBit': srBit, 'srValue': srValue,
      }) ?? -1;

  @override
  Future<int> getShortRangeFlag({
    required int epcNum,
    String? strEPC,
    String? password,
    required int maskMem,
    required int btWordAdd,
    required int maskLength,
    String? maskData,
    required int srBit,
  }) async =>
      await _mc.invokeMethod<int>('getShortRangeFlag', {
        'epcNum': epcNum, 'strEPC': strEPC, 'password': password,
        'maskMem': maskMem, 'btWordAdd': btWordAdd, 'maskLength': maskLength,
        'maskData': maskData, 'srBit': srBit,
      }) ?? -1;

  @override
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
  }) async =>
      await _mc.invokeMethod<int>('marginRead', {
        'epcNum': epcNum, 'strEPC': strEPC, 'memInt': memInt,
        'address': address, 'matchLength': matchLength, 'matchData': matchData,
        'password': password, 'maskMem': maskMem, 'btWordAdd': btWordAdd,
        'maskLength': maskLength, 'maskData': maskData,
      }) ?? -1;

  @override
  Future<AuthResult?> authenticate({
    required String epc,
    required String password,
  }) async {
    final raw = await _mc.invokeMapMethod<String, dynamic>(
        'authenticate', {'epc': epc, 'password': password});
    if (raw == null) return null;
    return AuthResult(
      code:     (raw['code'] as int?) ?? -1,
      random:   raw['random'] as String?,
      response: raw['response'] as String?,
    );
  }

  @override
  Future<int> setPowerBoost(int enable) async =>
      await _mc.invokeMethod<int>('setPowerBoost', {'enable': enable}) ?? -1;

  @override
  Future<int> getPowerBoost() async =>
      await _mc.invokeMethod<int>('getPowerBoost') ?? -1;

  @override
  Future<int> setFocus(int mode) async =>
      await _mc.invokeMethod<int>('setFocus', {'mode': mode}) ?? -1;

  @override
  Future<int> getFocus() async =>
      await _mc.invokeMethod<int>('getFocus') ?? -1;

  @override
  Future<int> setImpinjScanParam({
    required int opt,
    required int n,
    required int code,
    required int cr,
    required int protection,
    required int id,
    required int copyTo,
  }) async =>
      await _mc.invokeMethod<int>('setImpinjScanParam', {
        'opt': opt, 'n': n, 'code': code, 'cr': cr,
        'protection': protection, 'id': id, 'copyTo': copyTo,
      }) ?? -1;

  @override
  Future<ImpinjScanParam?> getImpinjScanParam() async {
    final raw = await _mc.invokeMapMethod<String, dynamic>('getImpinjScanParam');
    if (raw == null) return null;
    return ImpinjScanParam(
      n:          (raw['n'] as int?) ?? 0,
      code:       (raw['code'] as int?) ?? 0,
      cr:         (raw['cr'] as int?) ?? 0,
      protection: (raw['protection'] as int?) ?? 0,
      id:         (raw['id'] as int?) ?? 0,
      copyTo:     (raw['copyTo'] as int?) ?? 0,
    );
  }

  @override
  Future<int> setInventoryMatchData({
    required int matchType,
    required List<MatchDataItem> items,
  }) async =>
      await _mc.invokeMethod<int>('setInventoryMatchData', {
        'matchType': matchType,
        'items': items.map((e) => e.toMap()).toList(),
      }) ?? -1;

  @override
  Future<int> setTagQueting({
    required int opt,
    required int enable,
  }) async =>
      await _mc.invokeMethod<int>('setTagQueting', {
        'opt': opt,
        'enable': enable,
      }) ?? -1;

  @override
  Future<int> getTagQueting() async =>
      await _mc.invokeMethod<int>('getTagQueting') ?? -1;

  @override
  Future<int> protectedMode({
    required String epc,
    required int enable,
    required String password,
  }) async =>
      await _mc.invokeMethod<int>('protectedMode', {
        'epc': epc, 'enable': enable, 'password': password,
      }) ?? -1;

  @override
  Future<int> setReaderProtectedMode({
    required int opt,
    required int enable,
    required String password,
  }) async =>
      await _mc.invokeMethod<int>('setReaderProtectedMode', {
        'opt': opt, 'enable': enable, 'password': password,
      }) ?? -1;

  @override
  Future<ReaderProtectedModeResult?> getReaderProtectedMode() async {
    final raw = await _mc.invokeMapMethod<String, dynamic>('getReaderProtectedMode');
    if (raw == null) return null;
    return ReaderProtectedModeResult(
      enable:   int.tryParse(raw['enable']?.toString() ?? '') ?? 0,
      password: (raw['password'] as String?) ?? '',
    );
  }
}
