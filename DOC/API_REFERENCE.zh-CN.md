# Urovo RFID Flutter 插件 — API 速查表

本文列出 `package:rfid` 导出的**数据模型**与 **`Rfid` 实例方法**（与 `lib/rfid.dart`、`lib/rfid_platform_interface.dart` 一致）。  
通信通道与事件含义见 [INTEGRATION_GUIDE.zh-CN.md](INTEGRATION_GUIDE.zh-CN.md)。  
English: [API_REFERENCE.en.md](API_REFERENCE.en.md).

---

## 约定

- 除 **`Rfid.rawEventStream`** 为 **静态** getter 外，其余均为 **实例方法**。
- 未特殊说明时，**`Future<int>`** 通常 **0 = 成功**，非 0 为错误码（以 URFID SDK / 厂商文档为准）。
- **`Future<void>`** 的固件升级方法，进度见事件 **`event_fw_update`**。

---

## 1. 数据模型（`rfid_platform_interface.dart` 导出）

| 类型 | 字段摘要 |
|------|-----------|
| **TagReadResult** | `code`（int），`data`（String，十六进制等） |
| **FrequencyRegionInfo** | `regionIndex`、`regionName`、`minChannelIndex`、`maxChannelIndex`、`channelCount` |
| **QueryMemBankInfo** | `area`、`startAddress`、`length` |
| **FindEpcResult** | `epc`、`rssi` |
| **CustomRegionInfo** | `band`、`freSpace`、`freNum`、`startFre` |
| **OfflineQueryNum** | `rfidCount`、`barcodeCount` |
| **OfflineQueryMem** | `rfidPercent`、`barcodePercent` |
| **MatchDataItem** | `maskData`、`memBank`、`maskStart`、`maskLen`；`toMap()` 用于 `setInventoryMatchData` |
| **AuthResult** | `code`、`random`、`response` |
| **ImpinjScanParam** | `n`、`code`、`cr`、`protection`、`id`、`copyTo` |
| **ReaderProtectedModeResult** | `enable`、`password` |

---

## 2. 生命周期与连接

| 方法 | 说明 |
|------|------|
| `Future<int> initSdk()` | 一体机 / UART |
| `Future<int> initSdkBle(String mac)` | BLE |
| `Future<int> releaseSdk()` | 释放；页面退出务必调用 |
| `Future<bool> isConnected()` | 是否已连接 |
| `static Stream<Map<Object?, Object?>> get rawEventStream` | 事件流 |

---

## 3. 盘存

| 方法 | 说明 |
|------|------|
| `Future<int> startInventory()` | 连续盘存至 `stopInventory` |
| `Future<int> startInventoryWithTimeout(int timeout)` | 超时盘存，`timeout`：**秒** |
| `Future<int> stopInventory()` | 停止连续盘存 |
| `Future<int> inventorySingle()` | 单次盘存 |

---

## 4. 标签读写与锁定

| 方法 | 说明 |
|------|------|
| `Future<TagReadResult> readTag({...})` | `memBank`、`wordAdd`、`wordCnt`；可选 `epc`、`password` |
| `Future<int> writeTag({...})` | |
| `Future<int> writeTagEpc({...})` | |
| `Future<int> writeEpc({...})` | 随机改一张标签 EPC |
| `Future<int> killTag({...})` | |
| `Future<int> lockTag({...})` | |
| `Future<int> lightUpLedTag({...})` | `duration` 默认 ms 级 |

---

## 5. 按 TID 操作

| 方法 |
|------|
| `Future<String?> readDataByTid({...})` |
| `Future<int> writeTagByTid({...})` |
| `Future<int> lockByTID({...})` |
| `Future<int> killTagByTid({...})` |
| `Future<int> writeTagEpcByTid({...})` |

---

## 6. 掩码读写

| 方法 |
|------|
| `Future<TagReadResult> maskReadTag({...})` |
| `Future<int> maskWriteTag({...})` |

---

## 7. 大容量 / 擦除 / 查找

| 方法 | 说明 |
|------|------|
| `Future<TagReadResult> readTagExt({...})` | |
| `Future<int> writeTagExt({...})` | |
| `Future<int> eraseTag({...})` | |
| `Future<FindEpcResult?> findEpc(String epc)` | EPC + RSSI |

---

## 8. LED 盘存

| 方法 |
|------|
| `Future<int> startInventoryLed({required int manufacturers, required List<String> epcs})` |
| `Future<int> stopInventoryLed()` |

---

## 9. 掩码过滤（盘存前）

| 方法 | 说明 |
|------|------|
| `Future<int> addMask({...})` | `startAddress` / `len`：**bit** |
| `Future<int> addMaskWord({...})` | **word** |
| `Future<int> clearMask()` | |

---

## 10. 功率与频率

| 方法 |
|------|
| `Future<int> setOutputPower` / `getOutputPower` / `getSupportMaxOutputPower` |
| `Future<int> setFrequencyRegion({...})` |
| `Future<FrequencyRegionInfo?> getFrequencyRegion()` |
| `Future<List<String>> getSupportFrequencyBandList()` |
| `Future<int> setWorkRegion` / `getWorkRegion` |
| `Future<List<String>> getSupportWorkRegionList()` |
| `Future<int> setCustomRegion({...})` |
| `Future<CustomRegionInfo?> getCustomRegion()` |

---

## 11. Profile

| 方法 |
|------|
| `Future<int> setProfile` / `getProfile` |
| `Future<List<String>> getSupportProfileList()` |

---

## 12. 盘存参数与 Query

| 方法 |
|------|
| `setInventoryWithTarget` / `getInventoryWithTarget` |
| `setInventoryWithSession` / `getInventoryWithSession` |
| `setInventoryWithStartQvalue` / `getInventoryWithStartQvalue` |
| `setInventoryWithPassword` / `getInventoryWithPassword` |
| `setQueryMemoryBank` / `getQueryMemoryBank` |
| `setInventorySceneMode` / `getInventorySceneMode` |
| `setInventoryRssiLimit` / `getInventoryRssiLimit` |
| `isSupportInventoryRssiLimit` |
| `setRssiInDbm` |
| `setInventoryPhaseFlag` / `getInventoryPhaseFlag` |

---

## 13. 设备信息 / 串口 / 蜂鸣器

| 方法 | 说明 |
|------|------|
| `getFirmwareVersion`、`getDeviceId`、`getReaderType`、`getEx10Version`、`getReaderTemperature` | |
| `getReaderDeviceType` | 一体机 / 串口 / 蓝牙等 |
| `getModuleType` | U1~U5 |
| `setTagFocus` / `getTagFocus` | |
| `setBaudRate` / `getBaudRate` | |
| `setBeepEnable` | |

---

## 14. GripDevice

| 方法 | 说明 |
|------|------|
| `getBatteryLevel`、`getBatteryIsCharging` | |
| `getVersionSystem`、`getVersionBLE`、`getVersionMcu`、`getVersionRfid` | |
| `getDeviceSN`、`getBLEMac`、`getScanMode` | |
| `startScanBarcode` | |
| `setBeepRange` / `getBeepRange` | |
| `setSleepTime` / `getSleepTime` | |
| `setPowerOffTime` / `getPowerOffTime` | |
| `setOfflineModeOpen` / `getOfflineModeOpen` | |
| `setOfflineTransferClearData` / `getOfflineTransferClearData` | |
| `setOfflineTransferDelay` | |
| `getOfflineQueryNum`、`getOfflineQueryMem` | |
| `offlineManaulClearScanData`、`offlineManaulClearRFIDData` | |
| `offlineStartTransferRFID` | 经 `event_inventory_tag` |
| `offlineStartTransferScan` | 经 `event_barcode` |
| `modeResetFactory` | |

---

## 15. 固件升级（`Future<void>`）

| 方法 | 说明 |
|------|------|
| `updateReaderFirmwareByFile` / `updateReaderFirmwareByByte` | 一体机 RFID 模块 |
| `updateEx10ChipFirmwareByFile` / `updateEx10ChipFirmwareByByte` | Ex10 |
| `updateBLEReaderFirmwareByFile` / `updateBLEReaderFirmwareByByte` | 蓝牙模块 |
| `updateBLEEx10ChipFirmwareByFile` / `updateBLEEx10ChipFirmwareByByte` | 蓝牙 Ex10 |

---

## 16. Gen2x / Ex10 扩展

`setExtProfile`、`getExtProfile`、`setShortRangeFlag`、`getShortRangeFlag`、`marginRead`、`authenticate`、`setPowerBoost`、`getPowerBoost`、`setFocus`、`getFocus`、`setImpinjScanParam`、`getImpinjScanParam`、`setInventoryMatchData`、`setTagQueting`、`getTagQueting`、`protectedMode`、`setReaderProtectedMode`、`getReaderProtectedMode` — 参数见源码 `rfid_platform_interface.dart`。

---

## 文档维护

以 **`lib/rfid_platform_interface.dart`** 为单一事实来源；增删方法时请同步更新本表与英文版。
