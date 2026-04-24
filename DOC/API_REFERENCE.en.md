# Urovo RFID Flutter Plugin — API Quick Reference

**Data types** and **`Rfid` instance methods** exported by `package:rfid` (aligned with `lib/rfid.dart` and `lib/rfid_platform_interface.dart`).  
Channels and events: [INTEGRATION_GUIDE.en.md](INTEGRATION_GUIDE.en.md).  
中文: [API_REFERENCE.zh-CN.md](API_REFERENCE.zh-CN.md).

---

## Conventions

- Except **`Rfid.rawEventStream`** (**static** getter), all APIs are **instance** methods on `Rfid`.
- Unless noted, **`Future<int>`** uses **0 = success**; non-zero = error code (URFID SDK / vendor docs).
- **Firmware `Future<void>`** methods report progress via **`event_fw_update`**.

---

## 1. Data types (`rfid_platform_interface.dart`)

| Type | Fields (summary) |
|------|------------------|
| **TagReadResult** | `code` (int), `data` (String, hex, etc.) |
| **FrequencyRegionInfo** | `regionIndex`, `regionName`, `minChannelIndex`, `maxChannelIndex`, `channelCount` |
| **QueryMemBankInfo** | `area`, `startAddress`, `length` |
| **FindEpcResult** | `epc`, `rssi` |
| **CustomRegionInfo** | `band`, `freSpace`, `freNum`, `startFre` |
| **OfflineQueryNum** | `rfidCount`, `barcodeCount` |
| **OfflineQueryMem** | `rfidPercent`, `barcodePercent` |
| **MatchDataItem** | `maskData`, `memBank`, `maskStart`, `maskLen`; `toMap()` for `setInventoryMatchData` |
| **AuthResult** | `code`, `random`, `response` |
| **ImpinjScanParam** | `n`, `code`, `cr`, `protection`, `id`, `copyTo` |
| **ReaderProtectedModeResult** | `enable`, `password` |

---

## 2. Lifecycle & connection

| Method | Notes |
|--------|--------|
| `Future<int> initSdk()` | Integrated / UART |
| `Future<int> initSdkBle(String mac)` | BLE |
| `Future<int> releaseSdk()` | Release; call when leaving the module / page |
| `Future<bool> isConnected()` | Link up? |
| `static Stream<Map<Object?, Object?>> get rawEventStream` | Events |

---

## 3. Inventory

| Method | Notes |
|--------|--------|
| `Future<int> startInventory()` | Continuous until `stopInventory` |
| `Future<int> startInventoryWithTimeout(int timeout)` | `timeout` in **seconds** |
| `Future<int> stopInventory()` | Stop continuous |
| `Future<int> inventorySingle()` | Single shot |

---

## 4. Tag read / write / lock

| Method | Notes |
|--------|--------|
| `Future<TagReadResult> readTag({...})` | `memBank`, `wordAdd`, `wordCnt`; optional `epc`, `password` |
| `Future<int> writeTag({...})` | |
| `Future<int> writeTagEpc({...})` | |
| `Future<int> writeEpc({...})` | Random single-tag EPC write |
| `Future<int> killTag({...})` | |
| `Future<int> lockTag({...})` | |
| `Future<int> lightUpLedTag({...})` | `duration` default in ms (see native) |

---

## 5. TID-based operations

| Method |
|--------|
| `Future<String?> readDataByTid({...})` |
| `Future<int> writeTagByTid({...})` |
| `Future<int> lockByTID({...})` |
| `Future<int> killTagByTid({...})` |
| `Future<int> writeTagEpcByTid({...})` |

---

## 6. Masked read / write

| Method |
|--------|
| `Future<TagReadResult> maskReadTag({...})` |
| `Future<int> maskWriteTag({...})` |

---

## 7. Extended bank / erase / find

| Method | Notes |
|--------|--------|
| `Future<TagReadResult> readTagExt({...})` | |
| `Future<int> writeTagExt({...})` | |
| `Future<int> eraseTag({...})` | |
| `Future<FindEpcResult?> findEpc(String epc)` | EPC + RSSI |

---

## 8. LED inventory

| Method |
|--------|
| `Future<int> startInventoryLed({required int manufacturers, required List<String> epcs})` |
| `Future<int> stopInventoryLed()` |

---

## 9. Inventory mask (pre-filter)

| Method | Notes |
|--------|--------|
| `Future<int> addMask({...})` | `startAddress` / `len` in **bits** |
| `Future<int> addMaskWord({...})` | **words** |
| `Future<int> clearMask()` | |

---

## 10. Power & frequency

| Method |
|--------|
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

| Method |
|--------|
| `Future<int> setProfile` / `getProfile` |
| `Future<List<String>> getSupportProfileList()` |

---

## 12. Inventory parameters & query bank

| Method |
|--------|
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

## 13. Device info / UART / beeper

| Method | Notes |
|--------|--------|
| `getFirmwareVersion`, `getDeviceId`, `getReaderType`, `getEx10Version`, `getReaderTemperature` | |
| `getReaderDeviceType` | Integrated / serial / BLE, etc. |
| `getModuleType` | U1–U5 |
| `setTagFocus` / `getTagFocus` | |
| `setBaudRate` / `getBaudRate` | |
| `setBeepEnable` | |

---

## 14. GripDevice

| Method | Notes |
|--------|--------|
| `getBatteryLevel`, `getBatteryIsCharging` | |
| `getVersionSystem`, `getVersionBLE`, `getVersionMcu`, `getVersionRfid` | |
| `getDeviceSN`, `getBLEMac`, `getScanMode` | |
| `startScanBarcode` | |
| `setBeepRange` / `getBeepRange` | |
| `setSleepTime` / `getSleepTime` | |
| `setPowerOffTime` / `getPowerOffTime` | |
| `setOfflineModeOpen` / `getOfflineModeOpen` | |
| `setOfflineTransferClearData` / `getOfflineTransferClearData` | |
| `setOfflineTransferDelay` | |
| `getOfflineQueryNum`, `getOfflineQueryMem` | |
| `offlineManaulClearScanData`, `offlineManaulClearRFIDData` | |
| `offlineStartTransferRFID` | via `event_inventory_tag` |
| `offlineStartTransferScan` | via `event_barcode` |
| `modeResetFactory` | |

---

## 15. Firmware update (`Future<void>`)

| Method | Target |
|--------|--------|
| `updateReaderFirmwareByFile` / `updateReaderFirmwareByByte` | Integrated RFID module |
| `updateEx10ChipFirmwareByFile` / `updateEx10ChipFirmwareByByte` | Ex10 chip |
| `updateBLEReaderFirmwareByFile` / `updateBLEReaderFirmwareByByte` | BLE module |
| `updateBLEEx10ChipFirmwareByFile` / `updateBLEEx10ChipFirmwareByByte` | BLE Ex10 |

---

## 16. Gen2x / Ex10 extensions

`setExtProfile`, `getExtProfile`, `setShortRangeFlag`, `getShortRangeFlag`, `marginRead`, `authenticate`, `setPowerBoost`, `getPowerBoost`, `setFocus`, `getFocus`, `setImpinjScanParam`, `getImpinjScanParam`, `setInventoryMatchData`, `setTagQueting`, `getTagQueting`, `protectedMode`, `setReaderProtectedMode`, `getReaderProtectedMode` — see **`rfid_platform_interface.dart`** for full parameter lists.

---

## Maintaining this doc

Treat **`lib/rfid_platform_interface.dart`** as the source of truth; update this file and the Chinese version when the API surface changes.
