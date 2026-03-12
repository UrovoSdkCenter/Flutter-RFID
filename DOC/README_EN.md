# UROVO RFID Flutter Plugin

Flutter plugin for UROVO UHF RFID, providing ultra-high frequency RFID tag read/write functionality.

## Platform Support

- Android

## Features

- **Tag Inventory**: Batch inventory, single inventory, session configuration
- **Tag Read/Write**: Data read/write operations based on EPC/TID
- **Tag Operations**: Kill tags, lock tags (support for multiple memory banks)
- **Power Management**: Output power setting and query
- **Frequency Management**: Frequency region setting, custom frequency configuration
- **Mask Filtering**: Add/clear tag filtering masks
- **Mode Switching**: Query mode setting, scan head enable/disable
- **Device Information**: Firmware version, device ID, temperature query
- **ISO 18000-6B**: Full support for ISO 18000-6B protocol tag operations

## Installation

Add dependency in `pubspec.yaml`:

```yaml
dependencies:
  urovo_rfid:
    path: path/to/urovo_rfid
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Import Plugin

```dart
import 'package:urovo_rfid/urovo_rfid.dart';
import 'package:flutter/services.dart';
```

### 2. Initialize

```dart
final rfid = UrovoRfid();

// Listen to events
void _initEvent() {
  var eventChannel = const EventChannel("plugin_rfid_event");
  eventChannel.receiveBroadcastStream().listen(
    (event) {
      print('RFID Event: $event');
      
      // Parse event
      if (event['event_init'] != null) {
        int result = event['event_init'];
        print('Init result: $result'); // 0=success, -1=failure
      }
      
      if (event['event_inventory_tag'] != null) {
        String data = event['event_inventory_tag'];
        // data is JSON string: {"EPC":"...", "TID":"...", "RSSI":"..."}
        print('Tag found: $data');
      }
      
      if (event['event_inventory_tag_end'] != null) {
        print('Inventory complete');
      }
    },
    onError: (err) {
      print('Event error: $err');
    }
  );
}

// Initialize RFID
await rfid.init();
```

### 3. Start Inventory

```dart
// Start batch inventory
int? result = await rfid.startInventory(0); // session: 0-3
if (result == 0) {
  print('Inventory started successfully');
}

// Stop inventory
int? stopResult = await rfid.stopInventory();
```

### 4. Read/Write Tags

```dart
// Read tag data
String? data = await rfid.readTag(
  "E280689400005020DABBC14C", // EPC
  1,                            // memBank: 1=EPC area
  2,                            // wordAdd: start word address
  6,                            // wordCnt: word count
  "00000000"                    // access password (HEX string)
);

// Write tag data
int? writeResult = await rfid.writeTag(
  "E280689400005020DABBC14C", // EPC
  "00000000",                  // access password
  1,                           // memBank: 1=EPC area
  2,                           // wordAdd: start word address
  6,                           // wordCnt: word count
  "313233343536373839414243"  // data (HEX string)
);
```

### 5. Release Resources

```dart
await rfid.release();
```

## API Documentation

### Initialization and Release

#### init()
Initialize RFID module

```dart
await rfid.init();
```

**Returns:** None (result returned via EventChannel's `event_init` event)

**Event Callback:**
```dart
// event['event_init'] = 0  // Init success
// event['event_init'] = -1 // Init failure
```

#### release()
Release RFID resources

```dart
await rfid.release();
```

**Returns:** None

**Note:** Must be called before application exit

#### disConnect()
Disconnect RFID

```dart
await rfid.disConnect();
```

**Returns:** None

#### isConnected()
Check if RFID is connected

```dart
bool? connected = await rfid.isConnected();
```

**Returns:** `true`=connected, `false`=disconnected

### Tag Inventory

#### startInventory(int session)
Start batch inventory

```dart
int? result = await rfid.startInventory(0);
```

**Parameters:**
- `session`: Session value, range 0-3

**Returns:**
- `0`: Success
- Non-zero: Failure (error code)

**Event Callbacks:** 
- `event_inventory_tag`: Triggered when tag found
  ```dart
  // event['event_inventory_tag'] = '{"EPC":"...", "TID":"...", "RSSI":"..."}'
  ```
- `event_inventory_tag_end`: Triggered when inventory complete

**Note:** Automatically registers `IRfidCallback` after calling

#### stopInventory()
Stop inventory

```dart
int? result = await rfid.stopInventory();
```

**Returns:**
- `0`: Success
- Non-zero: Failure

**Note:** Automatically unregisters `IRfidCallback`

#### inventorySingle()
Single inventory

```dart
int? result = await rfid.inventorySingle();
```

**Returns:**
- `0`: Success
- Non-zero: Failure

**Description:** Executes one inventory operation, does not continuously inventory

### Tag Read/Write

#### readTag(String epc, int memBank, int wordAdd, int wordCnt, String pwArr)
Read tag data by EPC

```dart
String? data = await rfid.readTag(
  "E280689400005020DABBC14C",
  1,           // memBank: 0=Reserved, 1=EPC, 2=TID, 3=USER
  2,           // wordAdd: start word address
  6,           // wordCnt: word count (1 word=2 bytes)
  "00000000"   // pwArr: access password (8-digit HEX)
);
```

**Parameters:**
- `epc`: Tag EPC number (HEX string)
- `memBank`: Memory bank
  - `0`: Reserved area
  - `1`: EPC area
  - `2`: TID area
  - `3`: USER area
- `wordAdd`: Start word address (Word)
- `wordCnt`: Word count
- `pwArr`: Access password (HEX string, 8 digits)

**Returns:** Read data (HEX string), returns `"-19"` on failure

#### readDataByTid(String tidStr, int mem, int wordPtr, int num, String password)
Read tag data by TID

```dart
String? data = await rfid.readDataByTid(
  "E2806894000050200000001F",
  1,           // mem: memory bank
  2,           // wordPtr: start word address
  6,           // num: word count
  "00000000"   // password: access password
);
```

**Parameters:**
- `tidStr`: Tag TID number (HEX string)
- `mem`: Memory bank (0=Reserved, 1=EPC, 2=TID, 3=USER)
- `wordPtr`: Start word address
- `num`: Word count
- `password`: Access password (HEX string, 8 digits)

**Returns:** Read data (HEX string), returns `"-19"` on failure

#### writeTag(String epc, String btAryPassWord, int btMemBank, int btWordAdd, int btWordCnt, String btAryData)
Write tag data by EPC

```dart
int? result = await rfid.writeTag(
  "E280689400005020DABBC14C",
  "00000000",                  // access password
  1,                           // btMemBank: memory bank
  2,                           // btWordAdd: start word address
  6,                           // btWordCnt: word count
  "313233343536373839414243"  // btAryData: write data (HEX)
);
```

**Parameters:**
- `epc`: Tag EPC number
- `btAryPassWord`: Access password (HEX string, 8 digits)
- `btMemBank`: Memory bank (0=Reserved, 1=EPC, 2=TID, 3=USER)
- `btWordAdd`: Start word address
- `btWordCnt`: Word count
- `btAryData`: Write data (HEX string)

**Returns:**
- `0`: Success
- `-19`: Parameter error
- Other: Write failure error code

**Note:** Write data length must be `btWordCnt * 4` HEX characters

#### writeTagByTid(String tidStr, int mem, int wordPtr, String password, String wdata)
Write tag data by TID

```dart
int? result = await rfid.writeTagByTid(
  "E2806894000050200000001F",
  1,                           // mem: memory bank
  2,                           // wordPtr: start word address
  "00000000",                  // password: access password
  "313233343536373839414243"  // wdata: write data
);
```

**Parameters:**
- `tidStr`: Tag TID number
- `mem`: Memory bank
- `wordPtr`: Start word address
- `password`: Access password
- `wdata`: Write data (HEX string)

**Returns:** Same as `writeTag()`

#### WriteEPC(int epclen, String epc, String password)
Write EPC directly

```dart
int? result = await rfid.WriteEPC(
  12,                          // epclen: EPC length (words)
  "E280689400005020DABBC14C", // epc: new EPC number
  "00000000"                   // password: access password
);
```

**Parameters:**
- `epclen`: EPC length (words), common values are 6 or 12
- `epc`: New EPC number (HEX string)
- `password`: Access password (HEX string, 8 digits)

**Returns:**
- `0`: Success
- Non-zero: Failure

### Tag Operations

#### killTag(String epc, String btAryPassWord)
Kill tag by EPC

```dart
int? result = await rfid.killTag(
  "E280689400005020DABBC14C",
  "12345678"  // Kill password (HEX, 8 digits)
);
```

**Parameters:**
- `epc`: Tag EPC number
- `btAryPassWord`: Kill password (HEX string, 8 digits)

**Returns:**
- `0`: Success
- Non-zero: Failure

**WARNING:** This operation is irreversible! Tag cannot be recovered after being killed!

#### killbyTID(int tidlen, String tid, String btAryPassWord)
Kill tag by TID

```dart
int? result = await rfid.killbyTID(
  12,                          // tidlen: TID length (words)
  "E2806894000050200000001F", // tid: tag TID number
  "12345678"                   // Kill password
);
```

**Parameters:**
- `tidlen`: TID length (words)
- `tid`: Tag TID number
- `btAryPassWord`: Kill password

**Returns:** Same as `killTag()`

#### lockTag(String epc, String btAryPassWord, int btMemBank, int btLockType)
Lock tag by EPC

```dart
int? result = await rfid.lockTag(
  "E280689400005020DABBC14C",
  "00000000",  // access password
  1,           // btMemBank: lock area
  1            // btLockType: lock type
);
```

**Parameters:**
- `epc`: Tag EPC number
- `btAryPassWord`: Access password (HEX string, 8 digits)
- `btMemBank`: Lock memory bank
  - `0`: Reserved area
  - `1`: EPC area
  - `2`: TID area
  - `3`: USER area
- `btLockType`: Lock type
  - `0`: Unlock
  - `1`: Lock (can unlock with password)
  - `2`: Permanent lock (cannot unlock)
  - `3`: Permanent unlock

**Returns:**
- `0`: Success
- Non-zero: Failure

#### lockbyTID(int tidlen, String tid, int btMemBank, int btLockType, String btAryPassWord)
Lock tag by TID

```dart
int? result = await rfid.lockbyTID(
  12,                          // tidlen: TID length
  "E2806894000050200000001F", // tid: tag TID
  1,                           // btMemBank: lock area
  1,                           // btLockType: lock type
  "00000000"                   // access password
);
```

**Parameters:** Same as `lockTag()`, with added `tidlen` and `tid` parameters

**Returns:** Same as `lockTag()`

### Power Management

#### setOutputPower(int power)
Set output power

```dart
int? result = await rfid.setOutputPower(26);
```

**Parameters:**
- `power`: Power value, typically range 5-33 dBm (device-dependent)

**Returns:**
- `0`: Success
- `-19`: Parameter error
- Other: Failure

#### getOutputPower()
Get current output power

```dart
int? power = await rfid.getOutputPower();
print('Current power: $power dBm');
```

**Returns:** Current power value (dBm)

### Frequency Management

#### setFrequencyRegion(int btRegion, int btStartRegion, int btEndRegion)
Set frequency region

```dart
int? result = await rfid.setFrequencyRegion(
  1,   // btRegion: region code
  0,   // btStartRegion: start frequency point
  49   // btEndRegion: end frequency point
);
```

**Parameters:**
- `btRegion`: Region code
  - `1`: China2 (920-925MHz)
  - `2`: USA (902-928MHz)
  - `4`: Europe (865-868MHz)
  - `8`: China1 (840-845MHz)
  - Other values refer to RFID standards
- `btStartRegion`: Start frequency point index
- `btEndRegion`: End frequency point index

**Returns:**
- `0`: Success
- Non-zero: Failure

#### getFrequencyRegion()
Get current frequency region

```dart
String? region = await rfid.getFrequencyRegion();
```

**Returns:** Frequency region information string

#### setCustomRegion(int flags, int freSpace, int freNum, int startFre)
Set custom frequency region

```dart
int? result = await rfid.setCustomRegion(
  1,      // flags: configuration flags
  250,    // freSpace: frequency point interval (kHz)
  50,     // freNum: frequency point count
  920625  // startFre: start frequency (kHz)
);
```

**Parameters:**
- `flags`: Configuration flags
- `freSpace`: Frequency point interval (kHz)
- `freNum`: Frequency point count
- `startFre`: Start frequency (kHz)

**Returns:**
- `0`: Success
- Non-zero: Failure

#### getCustomRegion()
Get custom frequency region configuration

```dart
String? customRegion = await rfid.getCustomRegion();
// Returns JSON: {"flags":1,"freSpace":250,"freNum":50,"startFre":920625}
```

**Returns:** CustomRegionBean JSON string

### Mask Filtering

#### addMask(int mem, int startAddress, int len, String data)
Add tag filter mask

```dart
await rfid.addMask(
  1,           // mem: memory bank (1=EPC)
  32,          // startAddress: start bit address
  96,          // len: mask length (bits)
  "E2806894"   // data: mask data (HEX)
);
```

**Parameters:**
- `mem`: Memory bank (0=Reserved, 1=EPC, 2=TID, 3=USER)
- `startAddress`: Start bit address (bit)
- `len`: Mask length (bit)
- `data`: Mask data (HEX string)

**Returns:** None

**Description:** Only tags matching the mask will be inventoried

#### clearMask()
Clear all masks

```dart
await rfid.clearMask();
```

**Returns:** None

### Query Mode

#### setQueryMode(int mode)
Set query mode

```dart
await rfid.setQueryMode(0);
```

**Parameters:**
- `mode`: Query mode
  - `0`: EPC mode (EPC only)
  - `1`: EPC+TID mode
  - `2`: EPC+USER mode

**Returns:** None

#### getQueryMode()
Get current query mode

```dart
int? mode = await rfid.getQueryMode();
```

**Returns:** Current query mode (0/1/2)

### Scan Control

#### enableScanHead(bool isOpen)
Enable/disable scan head

```dart
await rfid.enableScanHead(true);  // Enable
await rfid.enableScanHead(false); // Disable
```

**Parameters:**
- `isOpen`: `true`=enable, `false`=disable

**Returns:** None

**Description:** Controls barcode scan head enable status

#### setScanInterval(int interval)
Set scan interval

```dart
int? result = await rfid.setScanInterval(100);
```

**Parameters:**
- `interval`: Scan interval (milliseconds), default 10ms

**Returns:**
- `0`: Success
- Non-zero: Failure

#### getScanInterval()
Get scan interval

```dart
int? interval = await rfid.getScanInterval();
```

**Returns:** Current scan interval (milliseconds)

#### startRead()
Start read operation

```dart
await rfid.startRead();
```

**Returns:** None

#### scanRfid()
Execute RFID scan

```dart
await rfid.scanRfid();
```

**Returns:** None

### Advanced Configuration

#### setInventoryParameter(String params)
Set inventory parameters

```dart
await rfid.setInventoryParameter(
  '{"session":0,"target":0,"Q":4}'
);
```

**Parameters:**
- `params`: RfidParameter JSON string

**Returns:** None

**Description:** Parameters will be parsed into `RfidParameter` object

#### setProfile(int param)
Set profile

```dart
int? result = await rfid.setProfile(0);
```

**Parameters:**
- `param`: Profile parameter

**Returns:**
- `0`: Success
- `-19`: Parameter error
- Other: Failure

#### setRange(int range)
Set read range

```dart
int? result = await rfid.setRange(1);
```

**Parameters:**
- `range`: Range level

**Returns:**
- `0`: Success
- Non-zero: Failure

#### getRange()
Get current read range

```dart
int? range = await rfid.getRange();
```

**Returns:** Current range level

### Device Information

#### getFirmwareVersion()
Get firmware version

```dart
String? version = await rfid.getFirmwareVersion();
print('Firmware version: $version');
```

**Returns:** Firmware version string

#### getModuleFirmware()
Get module firmware information

```dart
String? moduleFirmware = await rfid.getModuleFirmware();
```

**Returns:** Module firmware information string

#### getDeviceId()
Get device ID

```dart
String? deviceId = await rfid.getDeviceId();
```

**Returns:** Device ID string

#### getReaderType()
Get reader type

```dart
int? type = await rfid.getReaderType();
```

**Returns:** Reader type code

#### getReaderTemperature()
Get reader temperature

```dart
String? temperature = await rfid.getReaderTemperature();
print('Reader temperature: $temperature°C');
```

**Returns:** Temperature value string

### ISO 18000-6B Operations

#### iso180006BInventory()
Inventory 6B tags

```dart
int? result = await rfid.iso180006BInventory();
// Returns ArrayList<Tag6B> JSON string
```

**Returns:** Tag6B list JSON string

#### iso180006BReadTag(String btAryUID, int btWordAdd, int btWordCnt)
Read 6B tag

```dart
int? result = await rfid.iso180006BReadTag(
  "E2806894000050200000001F", // btAryUID: tag UID
  0,                           // btWordAdd: start word address
  4                            // btWordCnt: word count
);
```

**Parameters:**
- `btAryUID`: Tag UID (HEX string)
- `btWordAdd`: Start word address, default 0
- `btWordCnt`: Word count, default 0

**Returns:** Read result (converted to int)

#### iso180006BWriteTag(String btAryUID, int btWordAdd, int btWordCnt, String btAryBuffer)
Write 6B tag

```dart
int? result = await rfid.iso180006BWriteTag(
  "E2806894000050200000001F", // btAryUID: tag UID
  0,                           // btWordAdd: start word address
  4,                           // btWordCnt: word count
  "31323334353637383941424344" // btAryBuffer: write data (HEX)
);
```

**Parameters:**
- `btAryUID`: Tag UID
- `btWordAdd`: Start word address, default 0
- `btWordCnt`: Word count, default 0
- `btAryBuffer`: Write data (HEX string)

**Returns:**
- `0`: Success
- Non-zero: Failure

#### iso180006BLockTag(String btAryUID, int btWordAdd)
Lock 6B tag

```dart
int? result = await rfid.iso180006BLockTag(
  "E2806894000050200000001F", // btAryUID: tag UID
  0                            // btWordAdd: lock word address
);
```

**Parameters:**
- `btAryUID`: Tag UID
- `btWordAdd`: Lock word address, default 0

**Returns:**
- `0`: Success
- Non-zero: Failure

#### iso180006BQueryLockTag(String btAryUID, int btWordAdd)
Query 6B tag lock status

```dart
int? result = await rfid.iso180006BQueryLockTag(
  "E2806894000050200000001F", // btAryUID: tag UID
  0                            // btWordAdd: query word address
);
```

**Parameters:**
- `btAryUID`: Tag UID
- `btWordAdd`: Query word address, default 0

**Returns:** Lock status

## Event Description

### EventChannel: "plugin_rfid_event"

Plugin sends following events via EventChannel:

#### event_init
Initialization event

```dart
// event['event_init'] = 0  // Init success
// event['event_init'] = -1 // Init failure
```

#### event_inventory_tag
Tag inventory event

```dart
// event['event_inventory_tag'] = '{"EPC":"E280689400005020DABBC14C","TID":"E2806894000050200000001F","RSSI":"-45"}'
```

**Data Format (JSON string):**
```json
{
  "EPC": "E280689400005020DABBC14C",  // Tag EPC number
  "TID": "E2806894000050200000001F",  // Tag TID number
  "RSSI": "-45"                       // Signal strength (dBm)
}
```

#### event_inventory_tag_end
Inventory end event

```dart
// event['event_inventory_tag_end'] = ""
```

## Complete Example

See Chinese README for complete Dart example code.

## Important Notes

1. **Initialization Order**:
   ```dart
   // Correct order:
   _initEvent();  // Register event listener first
   await rfid.init();  // Then initialize RFID
   ```

2. **Resource Release**:
   - Must call `release()` in `dispose()`
   - Stop inventory before releasing resources
   - Must re-initialize after release

3. **EventChannel**:
   - Event name must be `"plugin_rfid_event"`
   - Init result returned via `event_init` event
   - Inventory data returned via `event_inventory_tag` event
   - All events are HashMap format

4. **Data Format**:
   - All HEX data must be even-length strings
   - Access password fixed at 8-digit HEX (4 bytes)
   - 1 Word = 2 Bytes = 4 HEX characters
   - `event_inventory_tag` value is JSON string, needs parsing

5. **Error Codes**:
   - `0`: Success
   - `-19`: Parameter error (plugin internal ERR_CODE)
   - `-99`: RFID not initialized
   - Other negative: Native SDK error codes

6. **Mask Filtering**:
   - Mask affects all inventory operations after setting
   - Use `clearMask()` to clear before inventorying all tags
   - Mask address unit is bit, data is HEX string

7. **Inventory Callbacks**:
   - `startInventory()` auto-registers `IRfidCallback`
   - `stopInventory()` auto-unregisters callback
   - Repeated `startInventory()` calls override previous callback

8. **Memory Bank Description**:
   - Reserved area (0): Stores Kill/Access passwords
   - EPC area (1): Stores EPC number
   - TID area (2): Tag unique ID (read-only)
   - USER area (3): Custom user data

9. **Session Parameter**:
   - Range 0-3, used for tag inventory anti-collision
   - Session 0: Tags quickly re-enter inventory
   - Sessions 1-3: Tags maintain state longer

10. **Power Settings**:
    - Too high power may cause overheating
    - Too low power affects read distance
    - Test optimal value for actual environment

## Troubleshooting

### Initialization Fails
- Confirm device supports RFID functionality
- Check if other app is occupying RFID module
- Review logcat logs for detailed errors

### No Tags Found
- Check output power setting (`getOutputPower()`)
- Confirm frequency region is correct
- Check if mask filtering is active
- Verify tags are within range

### Read/Write Fails
- Confirm access password is correct
- Check memory bank and address are valid
- Verify tag is not locked
- Ensure data length matches word count

### EventChannel No Events
- Confirm listener registered before `init()`
- Check eventChannel name is `"plugin_rfid_event"`
- Verify `eventSink` is not null (check logcat)

## Requirements

- **Flutter**: 2.0+
- **Dart**: 2.12+
- **Android SDK**: API 19+
- **Dependencies**: 
  - com.ubx.usdk:USDKManager
  - com.ubx.usdk.rfid:RfidManager
  - com.google.gson:Gson

## Technical Support

For technical support, please contact UROVO technical support team.

## License

Copyright © UROVO Technology Co., Ltd.
