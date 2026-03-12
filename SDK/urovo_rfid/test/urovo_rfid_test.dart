import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:urovo_rfid/urovo_rfid_method_channel.dart';
import 'package:urovo_rfid/urovo_rfid_platform_interface.dart';

class MockUrovoRfidPlatform
    with MockPlatformInterfaceMixin
    implements UrovoRfidPlatform {


  @override
  Future<void> init() {
    // TODO: implement init
    throw UnimplementedError();
  }

  @override
  Future<void> release() {
    // TODO: implement release
    throw UnimplementedError();
  }

  @override
  Future<int?> startInventory(int session) {
    // TODO: implement startInventory
    throw UnimplementedError();
  }

  @override
  Future<int?> stopInventory() {
    // TODO: implement stopInventory
    throw UnimplementedError();
  }

  @override
  Future<int?> WriteEPC(int epcLen, String epc, String password) {
    // TODO: implement WriteEPC
    throw UnimplementedError();
  }

  @override
  Future<void> addMask(int mem, int startAddress, int len, String data) {
    // TODO: implement addMask
    throw UnimplementedError();
  }

  @override
  Future<void> clearMask() {
    // TODO: implement clearMask
    throw UnimplementedError();
  }

  @override
  Future<void> disConnect() {
    // TODO: implement disConnect
    throw UnimplementedError();
  }

  @override
  Future<String?> getCustomRegion() {
    // TODO: implement getCustomRegion
    throw UnimplementedError();
  }

  @override
  Future<String?> getDeviceId() {
    // TODO: implement getDeviceId
    throw UnimplementedError();
  }

  @override
  Future<String?> getFirmwareVersion() {
    // TODO: implement getFirmwareVersion
    throw UnimplementedError();
  }

  @override
  Future<String?> getFrequencyRegion() {
    // TODO: implement getFrequencyRegion
    throw UnimplementedError();
  }

  @override
  Future<String?> getModuleFirmware() {
    // TODO: implement getModuleFirmware
    throw UnimplementedError();
  }

  @override
  Future<int?> getOutputPower() {
    // TODO: implement getOutputPower
    throw UnimplementedError();
  }

  @override
  Future<int?> getQueryMode() {
    // TODO: implement getQueryMode
    throw UnimplementedError();
  }

  @override
  Future<int?> getRange() {
    // TODO: implement getRange
    throw UnimplementedError();
  }

  @override
  Future<String?> getReaderTemperature() {
    // TODO: implement getReaderTemperature
    throw UnimplementedError();
  }

  @override
  Future<int?> getReaderType() {
    // TODO: implement getReaderType
    throw UnimplementedError();
  }

  @override
  Future<int?> getScanInterval() {
    // TODO: implement getScanInterval
    throw UnimplementedError();
  }

  @override
  Future<bool?> isConnected() {
    // TODO: implement isConnected
    throw UnimplementedError();
  }

  @override
  Future<int?> iso180006BInventory() {
    // TODO: implement iso180006BInventory
    throw UnimplementedError();
  }

  @override
  Future<int?> iso180006BLockTag(String btAryUID, int btWordAdd) {
    // TODO: implement iso180006BLockTag
    throw UnimplementedError();
  }

  @override
  Future<int?> iso180006BQueryLockTag(String btAryUID, int btWordAdd) {
    // TODO: implement iso180006BQueryLockTag
    throw UnimplementedError();
  }

  @override
  Future<int?> iso180006BReadTag(String btAryUID, int btWordAdd, int btWordCnt) {
    // TODO: implement iso180006BReadTag
    throw UnimplementedError();
  }

  @override
  Future<int?> iso180006BWriteTag(String btAryUID, int btWordAdd, int btWordCnt, String btAryBuffer) {
    // TODO: implement iso180006BWriteTag
    throw UnimplementedError();
  }

  @override
  Future<int?> killTag(String epc, String btAryPassWord) {
    // TODO: implement killTag
    throw UnimplementedError();
  }

  @override
  Future<int?> lockTag(String epc, String btAryPassWord, int btMemBank, int btLockType) {
    // TODO: implement lockTag
    throw UnimplementedError();
  }

  @override
  Future<int?> lockbyTID(int tidlen, String tid, int btMemBank, int btLockType, String btAryPassWord) {
    // TODO: implement lockbyTID
    throw UnimplementedError();
  }

  @override
  Future<String?> readDataByTid(String tidStr, int mem, int wordPtr, int num, String password) {
    // TODO: implement readDataByTid
    throw UnimplementedError();
  }

  @override
  Future<String?> readTag(String epc, int memBank, int wordAdd, int wordCnt, String pwArr) {
    // TODO: implement readTag
    throw UnimplementedError();
  }

  @override
  Future<int?> inventorySingle() {
    // TODO: implement inventorySingle
    throw UnimplementedError();
  }

  @override
  Future<void> scanRfid() {
    // TODO: implement scanRfid
    throw UnimplementedError();
  }

  @override
  Future<int?> setCustomRegion(int flags, int freSpace, int freNum, int startFre) {
    // TODO: implement setCustomRegion
    throw UnimplementedError();
  }

  @override
  Future<int?> setFrequencyRegion(int btRegion, int btStartRegion, int btEndRegion) {
    // TODO: implement setFrequencyRegion
    throw UnimplementedError();
  }

  @override
  Future<void> setInventoryParameter(String params) {
    // TODO: implement setInventoryParameter
    throw UnimplementedError();
  }

  @override
  Future<int?> setOutputPower(int power) {
    // TODO: implement setOutputPower
    throw UnimplementedError();
  }

  @override
  Future<int?> setProfile(int param) {
    // TODO: implement setProfile
    throw UnimplementedError();
  }

  @override
  Future<void> setQueryMode(int mode) {
    // TODO: implement setQueryMode
    throw UnimplementedError();
  }

  @override
  Future<int?> setRange(int range) {
    // TODO: implement setRange
    throw UnimplementedError();
  }

  @override
  Future<int?> setScanInterval(int interval) {
    // TODO: implement setScanInterval
    throw UnimplementedError();
  }

  @override
  Future<void> startRead() {
    // TODO: implement startRead
    throw UnimplementedError();
  }

  @override
  Future<int?> writeTag(String epc, String btAryPassWord, int btMemBank, int btWordAdd, int btWordCnt, String btAryData) {
    // TODO: implement writeTag
    throw UnimplementedError();
  }

  @override
  Future<int?> writeTagByTid(String tidStr, int mem, int wordPtr, String password, String data) {
    // TODO: implement writeTagByTid
    throw UnimplementedError();
  }

  @override
  Future<int?> killbyTID(int tidlen, String tid, String btAryPassWord) {
    // TODO: implement killbyTID
    throw UnimplementedError();
  }
}

void main() {
  final UrovoRfidPlatform initialPlatform = UrovoRfidPlatform.instance;

  test('$MethodChannelUrovoRfid is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelUrovoRfid>());
  });

  // test('getPlatformVersion', () async {
  //   UrovoRfid urovoRfidPlugin = UrovoRfid();
  //   MockUrovoRfidPlatform fakePlatform = MockUrovoRfidPlatform();
  //   UrovoRfidPlatform.instance = fakePlatform;
  //
  //   expect(await urovoRfidPlugin.getPlatformVersion(), '42');
  // });
}
