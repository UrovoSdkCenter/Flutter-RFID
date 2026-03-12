# UROVO RFID Flutter Plugin

Flutter plugin for UROVO UHF RFID reader, 提供超高频RFID读写器功能支持。

## 平台支持

- Android

## 功能特性

- **标签盘点**: 批量盘点、单次盘点、Session配置
- **标签读写**: 基于EPC/TID的数据读写操作
- **标签操作**: Kill标签、Lock标签（支持多种存储区）
- **功率管理**: 输出功率设置与查询
- **频率管理**: 频率区域设置、自定义频率配置
- **掩码过滤**: 添加/清除标签过滤掩码
- **模式切换**: 查询模式设置、扫描头启用/禁用
- **设备信息**: 固件版本、设备ID、温度查询
- **ISO 18000-6B**: 完整支持6B协议标签操作

## 安装

在 `pubspec.yaml` 中添加依赖:

```yaml
dependencies:
  urovo_rfid:
    path: path/to/urovo_rfid
```

然后执行:

```bash
flutter pub get
```

## 快速开始

### 1. 导入插件

```dart
import 'package:urovo_rfid/urovo_rfid.dart';
import 'package:flutter/services.dart';
```

### 2. 初始化

```dart
final rfid = UrovoRfid();

// 监听事件
void _initEvent() {
  var eventChannel = const EventChannel("plugin_rfid_event");
  eventChannel.receiveBroadcastStream().listen(
    (event) {
      print('RFID Event: $event');
      
      // 解析事件
      if (event['event_init'] != null) {
        int result = event['event_init'];
        print('初始化结果: $result'); // 0=成功, -1=失败
      }
      
      if (event['event_inventory_tag'] != null) {
        String data = event['event_inventory_tag'];
        // data是JSON字符串: {"EPC":"...", "TID":"...", "RSSI":"..."}
        print('盘点到标签: $data');
      }
      
      if (event['event_inventory_tag_end'] != null) {
        print('盘点结束');
      }
    },
    onError: (err) {
      print('事件错误: $err');
    }
  );
}

// 初始化RFID
await rfid.init();
```

### 3. 启动盘点

```dart
// 启动批量盘点
int? result = await rfid.startInventory(0); // session: 0-3
if (result == 0) {
  print('盘点启动成功');
}

// 停止盘点
int? stopResult = await rfid.stopInventory();
```

### 4. 读写标签

```dart
// 读取标签数据
String? data = await rfid.readTag(
  "E280689400005020DABBC14C", // EPC
  1,                            // memBank: 1=EPC区
  2,                            // wordAdd: 起始字地址
  6,                            // wordCnt: 读取字数
  "00000000"                    // 访问密码(HEX字符串)
);

// 写入标签数据
int? writeResult = await rfid.writeTag(
  "E280689400005020DABBC14C", // EPC
  "00000000",                  // 访问密码
  1,                           // memBank: 1=EPC区
  2,                           // wordAdd: 起始字地址
  6,                           // wordCnt: 写入字数
  "313233343536373839414243"  // 数据(HEX字符串)
);
```

### 5. 释放资源

```dart
await rfid.release();
```

## API文档

### 初始化与释放

#### init()
初始化RFID模块

```dart
await rfid.init();
```

**返回值:** 无（通过EventChannel的`event_init`事件返回结果）

**事件回调:**
```dart
// event['event_init'] = 0  // 初始化成功
// event['event_init'] = -1 // 初始化失败
```

#### release()
释放RFID资源

```dart
await rfid.release();
```

**返回值:** 无

**注意:** 应用退出前必须调用此方法释放资源

#### disConnect()
断开RFID连接

```dart
await rfid.disConnect();
```

**返回值:** 无

#### isConnected()
检查RFID是否已连接

```dart
bool? connected = await rfid.isConnected();
```

**返回值:** `true`=已连接, `false`=未连接

### 标签盘点

#### startInventory(int session)
启动批量盘点

```dart
int? result = await rfid.startInventory(0);
```

**参数:**
- `session`: Session值，范围0-3

**返回值:**
- `0`: 成功
- `非0`: 失败（错误码）

**事件回调:** 
- `event_inventory_tag`: 盘点到标签时触发
  ```dart
  // event['event_inventory_tag'] = '{"EPC":"...", "TID":"...", "RSSI":"..."}'
  ```
- `event_inventory_tag_end`: 盘点结束时触发

**注意:** 调用后会自动注册`IRfidCallback`回调

#### stopInventory()
停止盘点

```dart
int? result = await rfid.stopInventory();
```

**返回值:**
- `0`: 成功
- `非0`: 失败

**注意:** 此方法会自动注销`IRfidCallback`回调

#### inventorySingle()
单次盘点

```dart
int? result = await rfid.inventorySingle();
```

**返回值:**
- `0`: 成功
- `非0`: 失败

**说明:** 执行一次盘点操作，不会持续盘点

### 标签读写

#### readTag(String epc, int memBank, int wordAdd, int wordCnt, String pwArr)
根据EPC读取标签数据

```dart
String? data = await rfid.readTag(
  "E280689400005020DABBC14C",
  1,           // memBank: 0=Reserved, 1=EPC, 2=TID, 3=USER
  2,           // wordAdd: 起始字地址
  6,           // wordCnt: 读取字数(1字=2字节)
  "00000000"   // pwArr: 访问密码(8位HEX)
);
```

**参数:**
- `epc`: 标签EPC号(HEX字符串)
- `memBank`: 存储区
  - `0`: Reserved区
  - `1`: EPC区
  - `2`: TID区
  - `3`: USER区
- `wordAdd`: 起始字地址(Word)
- `wordCnt`: 读取字数
- `pwArr`: 访问密码(HEX字符串，8位)

**返回值:** 读取的数据(HEX字符串)，失败返回`"-19"`

#### readDataByTid(String tidStr, int mem, int wordPtr, int num, String password)
根据TID读取标签数据

```dart
String? data = await rfid.readDataByTid(
  "E2806894000050200000001F",
  1,           // mem: 存储区
  2,           // wordPtr: 起始字地址
  6,           // num: 读取字数
  "00000000"   // password: 访问密码
);
```

**参数:**
- `tidStr`: 标签TID号(HEX字符串)
- `mem`: 存储区(0=Reserved, 1=EPC, 2=TID, 3=USER)
- `wordPtr`: 起始字地址
- `num`: 读取字数
- `password`: 访问密码(HEX字符串，8位)

**返回值:** 读取的数据(HEX字符串)，失败返回`"-19"`

#### writeTag(String epc, String btAryPassWord, int btMemBank, int btWordAdd, int btWordCnt, String btAryData)
根据EPC写入标签数据

```dart
int? result = await rfid.writeTag(
  "E280689400005020DABBC14C",
  "00000000",                  // 访问密码
  1,                           // btMemBank: 存储区
  2,                           // btWordAdd: 起始字地址
  6,                           // btWordCnt: 写入字数
  "313233343536373839414243"  // btAryData: 写入数据(HEX)
);
```

**参数:**
- `epc`: 标签EPC号
- `btAryPassWord`: 访问密码(HEX字符串，8位)
- `btMemBank`: 存储区(0=Reserved, 1=EPC, 2=TID, 3=USER)
- `btWordAdd`: 起始字地址
- `btWordCnt`: 写入字数
- `btAryData`: 写入数据(HEX字符串)

**返回值:**
- `0`: 成功
- `-19`: 参数错误
- `其他`: 写入失败错误码

**注意:** 写入数据长度必须为`btWordCnt * 4`位HEX字符

#### writeTagByTid(String tidStr, int mem, int wordPtr, String password, String wdata)
根据TID写入标签数据

```dart
int? result = await rfid.writeTagByTid(
  "E2806894000050200000001F",
  1,                           // mem: 存储区
  2,                           // wordPtr: 起始字地址
  "00000000",                  // password: 访问密码
  "313233343536373839414243"  // wdata: 写入数据
);
```

**参数:**
- `tidStr`: 标签TID号
- `mem`: 存储区
- `wordPtr`: 起始字地址
- `password`: 访问密码
- `wdata`: 写入数据(HEX字符串)

**返回值:** 同`writeTag()`

#### WriteEPC(int epclen, String epc, String password)
直接写入EPC号

```dart
int? result = await rfid.WriteEPC(
  12,                          // epclen: EPC长度(字)
  "E280689400005020DABBC14C", // epc: 新的EPC号
  "00000000"                   // password: 访问密码
);
```

**参数:**
- `epclen`: EPC长度(字)，常见值为6或12
- `epc`: 新的EPC号(HEX字符串)
- `password`: 访问密码(HEX字符串，8位)

**返回值:**
- `0`: 成功
- `非0`: 失败

### 标签操作

#### killTag(String epc, String btAryPassWord)
根据EPC销毁标签

```dart
int? result = await rfid.killTag(
  "E280689400005020DABBC14C",
  "12345678"  // Kill密码(HEX，8位)
);
```

**参数:**
- `epc`: 标签EPC号
- `btAryPassWord`: Kill密码(HEX字符串，8位)

**返回值:**
- `0`: 成功
- `非0`: 失败

**警告:** 此操作不可逆，标签被销毁后无法恢复！

#### killbyTID(int tidlen, String tid, String btAryPassWord)
根据TID销毁标签

```dart
int? result = await rfid.killbyTID(
  12,                          // tidlen: TID长度(字)
  "E2806894000050200000001F", // tid: 标签TID号
  "12345678"                   // Kill密码
);
```

**参数:**
- `tidlen`: TID长度(字)
- `tid`: 标签TID号
- `btAryPassWord`: Kill密码

**返回值:** 同`killTag()`

#### lockTag(String epc, String btAryPassWord, int btMemBank, int btLockType)
根据EPC锁定标签

```dart
int? result = await rfid.lockTag(
  "E280689400005020DABBC14C",
  "00000000",  // 访问密码
  1,           // btMemBank: 锁定区域
  1            // btLockType: 锁定类型
);
```

**参数:**
- `epc`: 标签EPC号
- `btAryPassWord`: 访问密码(HEX字符串，8位)
- `btMemBank`: 锁定存储区
  - `0`: Reserved区
  - `1`: EPC区
  - `2`: TID区
  - `3`: USER区
- `btLockType`: 锁定类型
  - `0`: 解锁
  - `1`: 锁定(可用密码解锁)
  - `2`: 永久锁定(不可解锁)
  - `3`: 永久解锁

**返回值:**
- `0`: 成功
- `非0`: 失败

#### lockbyTID(int tidlen, String tid, int btMemBank, int btLockType, String btAryPassWord)
根据TID锁定标签

```dart
int? result = await rfid.lockbyTID(
  12,                          // tidlen: TID长度
  "E2806894000050200000001F", // tid: 标签TID
  1,                           // btMemBank: 锁定区域
  1,                           // btLockType: 锁定类型
  "00000000"                   // 访问密码
);
```

**参数:** 同`lockTag()`，增加`tidlen`和`tid`参数

**返回值:** 同`lockTag()`

### 功率管理

#### setOutputPower(int power)
设置输出功率

```dart
int? result = await rfid.setOutputPower(26);
```

**参数:**
- `power`: 功率值，范围通常为5-33 dBm（具体范围依设备而定）

**返回值:**
- `0`: 成功
- `-19`: 参数错误
- `其他`: 失败

#### getOutputPower()
获取当前输出功率

```dart
int? power = await rfid.getOutputPower();
print('当前功率: $power dBm');
```

**返回值:** 当前功率值(dBm)

### 频率管理

#### setFrequencyRegion(int btRegion, int btStartRegion, int btEndRegion)
设置频率区域

```dart
int? result = await rfid.setFrequencyRegion(
  1,   // btRegion: 区域代码
  0,   // btStartRegion: 起始频点
  49   // btEndRegion: 结束频点
);
```

**参数:**
- `btRegion`: 区域代码
  - `1`: 中国2(920-925MHz)
  - `2`: 美国(902-928MHz)
  - `4`: 欧洲(865-868MHz)
  - `8`: 中国1(840-845MHz)
  - 其他值参考RFID标准
- `btStartRegion`: 起始频点索引
- `btEndRegion`: 结束频点索引

**返回值:**
- `0`: 成功
- `非0`: 失败

#### getFrequencyRegion()
获取当前频率区域

```dart
String? region = await rfid.getFrequencyRegion();
```

**返回值:** 频率区域信息字符串

#### setCustomRegion(int flags, int freSpace, int freNum, int startFre)
设置自定义频率区域

```dart
int? result = await rfid.setCustomRegion(
  1,      // flags: 标志位
  250,    // freSpace: 频点间隔(kHz)
  50,     // freNum: 频点数量
  920625  // startFre: 起始频率(kHz)
);
```

**参数:**
- `flags`: 配置标志
- `freSpace`: 频点间隔(kHz)
- `freNum`: 频点数量
- `startFre`: 起始频率(kHz)

**返回值:**
- `0`: 成功
- `非0`: 失败

#### getCustomRegion()
获取自定义频率区域配置

```dart
String? customRegion = await rfid.getCustomRegion();
// 返回JSON: {"flags":1,"freSpace":250,"freNum":50,"startFre":920625}
```

**返回值:** CustomRegionBean的JSON字符串

### 掩码过滤

#### addMask(int mem, int startAddress, int len, String data)
添加标签过滤掩码

```dart
await rfid.addMask(
  1,           // mem: 存储区(1=EPC)
  32,          // startAddress: 起始位地址
  96,          // len: 掩码长度(位)
  "E2806894"   // data: 掩码数据(HEX)
);
```

**参数:**
- `mem`: 存储区(0=Reserved, 1=EPC, 2=TID, 3=USER)
- `startAddress`: 起始位地址(bit)
- `len`: 掩码长度(bit)
- `data`: 掩码数据(HEX字符串)

**返回值:** 无

**说明:** 设置后只会盘点符合掩码条件的标签

#### clearMask()
清除所有掩码

```dart
await rfid.clearMask();
```

**返回值:** 无

### 查询模式

#### setQueryMode(int mode)
设置查询模式

```dart
await rfid.setQueryMode(0);
```

**参数:**
- `mode`: 查询模式
  - `0`: EPC模式(仅返回EPC)
  - `1`: EPC+TID模式
  - `2`: EPC+USER模式

**返回值:** 无

#### getQueryMode()
获取当前查询模式

```dart
int? mode = await rfid.getQueryMode();
```

**返回值:** 当前查询模式(0/1/2)

### 扫描控制

#### enableScanHead(bool isOpen)
启用/禁用扫描头

```dart
await rfid.enableScanHead(true);  // 启用
await rfid.enableScanHead(false); // 禁用
```

**参数:**
- `isOpen`: `true`=启用, `false`=禁用

**返回值:** 无

**说明:** 控制条码扫描头的启用状态

#### setScanInterval(int interval)
设置扫描间隔

```dart
int? result = await rfid.setScanInterval(100);
```

**参数:**
- `interval`: 扫描间隔(毫秒)，默认10ms

**返回值:**
- `0`: 成功
- `非0`: 失败

#### getScanInterval()
获取扫描间隔

```dart
int? interval = await rfid.getScanInterval();
```

**返回值:** 当前扫描间隔(毫秒)

#### startRead()
启动读取操作

```dart
await rfid.startRead();
```

**返回值:** 无

#### scanRfid()
执行RFID扫描

```dart
await rfid.scanRfid();
```

**返回值:** 无

### 高级配置

#### setInventoryParameter(String params)
设置盘点参数

```dart
await rfid.setInventoryParameter(
  '{"session":0,"target":0,"Q":4}'
);
```

**参数:**
- `params`: RfidParameter的JSON字符串

**返回值:** 无

**说明:** 参数会被解析为`RfidParameter`对象

#### setProfile(int param)
设置配置文件

```dart
int? result = await rfid.setProfile(0);
```

**参数:**
- `param`: 配置文件参数

**返回值:**
- `0`: 成功
- `-19`: 参数错误
- `其他`: 失败

#### setRange(int range)
设置读取范围

```dart
int? result = await rfid.setRange(1);
```

**参数:**
- `range`: 范围级别

**返回值:**
- `0`: 成功
- `非0`: 失败

#### getRange()
获取当前读取范围

```dart
int? range = await rfid.getRange();
```

**返回值:** 当前范围级别

### 设备信息

#### getFirmwareVersion()
获取固件版本

```dart
String? version = await rfid.getFirmwareVersion();
print('固件版本: $version');
```

**返回值:** 固件版本字符串

#### getModuleFirmware()
获取模块固件信息

```dart
String? moduleFirmware = await rfid.getModuleFirmware();
```

**返回值:** 模块固件信息字符串

#### getDeviceId()
获取设备ID

```dart
String? deviceId = await rfid.getDeviceId();
```

**返回值:** 设备ID字符串

#### getReaderType()
获取读写器类型

```dart
int? type = await rfid.getReaderType();
```

**返回值:** 读写器类型代码

#### getReaderTemperature()
获取读写器温度

```dart
String? temperature = await rfid.getReaderTemperature();
print('读写器温度: $temperature°C');
```

**返回值:** 温度值字符串

### ISO 18000-6B 操作

#### iso180006BInventory()
盘点6B标签

```dart
int? result = await rfid.iso180006BInventory();
// 返回值是ArrayList<Tag6B>的JSON字符串
```

**返回值:** Tag6B列表的JSON字符串

#### iso180006BReadTag(String btAryUID, int btWordAdd, int btWordCnt)
读取6B标签

```dart
int? result = await rfid.iso180006BReadTag(
  "E2806894000050200000001F", // btAryUID: 标签UID
  0,                           // btWordAdd: 起始字地址
  4                            // btWordCnt: 读取字数
);
```

**参数:**
- `btAryUID`: 标签UID(HEX字符串)
- `btWordAdd`: 起始字地址，默认0
- `btWordCnt`: 读取字数，默认0

**返回值:** 读取结果(转为int)

#### iso180006BWriteTag(String btAryUID, int btWordAdd, int btWordCnt, String btAryBuffer)
写入6B标签

```dart
int? result = await rfid.iso180006BWriteTag(
  "E2806894000050200000001F", // btAryUID: 标签UID
  0,                           // btWordAdd: 起始字地址
  4,                           // btWordCnt: 写入字数
  "31323334353637383941424344" // btAryBuffer: 写入数据(HEX)
);
```

**参数:**
- `btAryUID`: 标签UID
- `btWordAdd`: 起始字地址，默认0
- `btWordCnt`: 写入字数，默认0
- `btAryBuffer`: 写入数据(HEX字符串)

**返回值:**
- `0`: 成功
- `非0`: 失败

#### iso180006BLockTag(String btAryUID, int btWordAdd)
锁定6B标签

```dart
int? result = await rfid.iso180006BLockTag(
  "E2806894000050200000001F", // btAryUID: 标签UID
  0                            // btWordAdd: 锁定字地址
);
```

**参数:**
- `btAryUID`: 标签UID
- `btWordAdd`: 锁定字地址，默认0

**返回值:**
- `0`: 成功
- `非0`: 失败

#### iso180006BQueryLockTag(String btAryUID, int btWordAdd)
查询6B标签锁定状态

```dart
int? result = await rfid.iso180006BQueryLockTag(
  "E2806894000050200000001F", // btAryUID: 标签UID
  0                            // btWordAdd: 查询字地址
);
```

**参数:**
- `btAryUID`: 标签UID
- `btWordAdd`: 查询字地址，默认0

**返回值:** 锁定状态

## 事件说明

### EventChannel: "plugin_rfid_event"

插件通过EventChannel发送以下事件：

#### event_init
初始化事件

```dart
// event['event_init'] = 0  // 初始化成功
// event['event_init'] = -1 // 初始化失败
```

#### event_inventory_tag
盘点到标签事件

```dart
// event['event_inventory_tag'] = '{"EPC":"E280689400005020DABBC14C","TID":"E2806894000050200000001F","RSSI":"-45"}'
```

**数据格式(JSON字符串):**
```json
{
  "EPC": "E280689400005020DABBC14C",  // 标签EPC号
  "TID": "E2806894000050200000001F",  // 标签TID号
  "RSSI": "-45"                       // 信号强度(dBm)
}
```

#### event_inventory_tag_end
盘点结束事件

```dart
// event['event_inventory_tag_end'] = ""
```

## 完整示例

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:urovo_rfid/urovo_rfid.dart';
import 'dart:convert';

class RfidDemo extends StatefulWidget {
  @override
  _RfidDemoState createState() => _RfidDemoState();
}

class _RfidDemoState extends State<RfidDemo> {
  final rfid = UrovoRfid();
  String _statusText = '未初始化';
  List<Map<String, String>> _tagList = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initEvent();
    _initRfid();
  }

  void _initEvent() {
    var eventChannel = const EventChannel("plugin_rfid_event");
    eventChannel.receiveBroadcastStream().listen(
      (event) {
        print('RFID事件: $event');
        
        // 初始化事件
        if (event['event_init'] != null) {
          int result = event['event_init'];
          setState(() {
            _statusText = result == 0 ? 'RFID已就绪' : 'RFID初始化失败';
          });
        }
        
        // 盘点标签事件
        if (event['event_inventory_tag'] != null) {
          String jsonData = event['event_inventory_tag'];
          try {
            Map<String, dynamic> tagData = json.decode(jsonData);
            setState(() {
              // 检查是否已存在(根据EPC去重)
              bool exists = _tagList.any((tag) => tag['EPC'] == tagData['EPC']);
              if (!exists) {
                _tagList.add({
                  'EPC': tagData['EPC'] ?? '',
                  'TID': tagData['TID'] ?? '',
                  'RSSI': tagData['RSSI'] ?? '',
                });
              }
            });
          } catch (e) {
            print('解析标签数据失败: $e');
          }
        }
        
        // 盘点结束事件
        if (event['event_inventory_tag_end'] != null) {
          setState(() {
            _statusText = '盘点结束，共发现 ${_tagList.length} 个标签';
          });
        }
      },
      onError: (err) {
        print('事件错误: $err');
      }
    );
  }

  Future<void> _initRfid() async {
    setState(() => _statusText = '正在初始化...');
    await rfid.init();
  }

  Future<void> _startInventory() async {
    if (_isScanning) {
      await _stopInventory();
      return;
    }

    setState(() {
      _tagList.clear();
      _statusText = '正在盘点...';
      _isScanning = true;
    });

    // 设置输出功率为26dBm
    await rfid.setOutputPower(26);
    
    // 设置查询模式为EPC+TID
    await rfid.setQueryMode(1);
    
    // 启动盘点(Session 0)
    int? result = await rfid.startInventory(0);
    
    if (result != 0) {
      setState(() {
        _statusText = '启动盘点失败: $result';
        _isScanning = false;
      });
    }
  }

  Future<void> _stopInventory() async {
    int? result = await rfid.stopInventory();
    setState(() {
      _isScanning = false;
      _statusText = '盘点已停止';
    });
  }

  Future<void> _readTag(String epc) async {
    setState(() => _statusText = '正在读取标签...');

    // 读取EPC区数据
    String? data = await rfid.readTag(
      epc,
      1,           // EPC区
      2,           // 从第2个字开始
      6,           // 读取6个字
      "00000000"   // 访问密码
    );

    setState(() {
      if (data != null && data != "-19") {
        _statusText = '读取成功: $data';
      } else {
        _statusText = '读取失败';
      }
    });
  }

  Future<void> _writeTag(String epc) async {
    setState(() => _statusText = '正在写入标签...');

    // 写入测试数据 "TEST1234"
    // T=54, E=45, S=53, T=54, 1=31, 2=32, 3=33, 4=34
    String writeData = "544553543132333400000000"; // 12字节

    int? result = await rfid.writeTag(
      epc,
      "00000000",  // 访问密码
      3,           // USER区
      0,           // 从第0个字开始
      6,           // 写入6个字(12字节)
      writeData
    );

    setState(() {
      _statusText = result == 0 ? '写入成功' : '写入失败: $result';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UROVO RFID Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: _showDeviceInfo,
          )
        ],
      ),
      body: Column(
        children: [
          // 状态栏
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Text(
              _statusText,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          
          // 操作按钮
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _startInventory,
                  icon: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
                  label: Text(_isScanning ? '停止盘点' : '开始盘点'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isScanning ? Colors.red : Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _tagList.clear());
                  },
                  icon: Icon(Icons.clear),
                  label: Text('清空列表'),
                ),
              ],
            ),
          ),
          
          // 标签列表
          Expanded(
            child: _tagList.isEmpty
                ? Center(child: Text('暂无标签数据'))
                : ListView.builder(
                    itemCount: _tagList.length,
                    itemBuilder: (context, index) {
                      var tag = _tagList[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            'EPC: ${tag['EPC']}',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TID: ${tag['TID']}', style: TextStyle(fontSize: 11)),
                              Text('RSSI: ${tag['RSSI']} dBm', style: TextStyle(fontSize: 11)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.read_more, size: 20),
                                onPressed: () => _readTag(tag['EPC']!),
                                tooltip: '读取',
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, size: 20),
                                onPressed: () => _writeTag(tag['EPC']!),
                                tooltip: '写入',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDeviceInfo() async {
    String? firmware = await rfid.getFirmwareVersion();
    String? deviceId = await rfid.getDeviceId();
    int? power = await rfid.getOutputPower();
    String? temperature = await rfid.getReaderTemperature();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('设备信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('固件版本: $firmware'),
            Text('设备ID: $deviceId'),
            Text('输出功率: $power dBm'),
            Text('温度: $temperature°C'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    rfid.stopInventory();
    rfid.release();
    super.dispose();
  }
}
```

## 注意事项

1. **初始化顺序**:
   ```dart
   // 正确顺序:
   _initEvent();  // 先注册事件监听
   await rfid.init();  // 再初始化RFID
   ```

2. **资源释放**:
   - 必须在`dispose()`中调用`release()`
   - 停止盘点后才能释放资源
   - 释放后需要重新初始化才能使用

3. **EventChannel**:
   - 事件名称必须为`"plugin_rfid_event"`
   - 初始化结果通过`event_init`事件返回
   - 盘点数据通过`event_inventory_tag`事件返回
   - 所有事件都是HashMap格式

4. **数据格式**:
   - 所有HEX数据必须是偶数位字符串
   - 访问密码固定8位HEX(4字节)
   - 1 Word = 2 Bytes = 4位HEX字符
   - `event_inventory_tag`的value是JSON字符串,需要解析

5. **错误码**:
   - `0`: 成功
   - `-19`: 参数错误（插件内部定义的ERR_CODE）
   - `-99`: RFID未初始化
   - 其他负数: 底层SDK错误码

6. **掩码过滤**:
   - 掩码设置后会影响所有盘点操作
   - 使用`clearMask()`清除后才能盘点所有标签
   - 掩码地址单位为bit，数据为HEX字符串

7. **盘点回调**:
   - `startInventory()`会自动注册`IRfidCallback`
   - `stopInventory()`会自动注销回调
   - 重复调用`startInventory()`会覆盖之前的回调

8. **存储区说明**:
   - Reserved区(0): 存储Kill/Access密码
   - EPC区(1): 存储EPC号
   - TID区(2): 标签唯一识别码(只读)
   - USER区(3): 用户自定义数据

9. **Session参数**:
   - 范围0-3，用于标签盘点防冲突
   - Session 0: 标签快速重新参与盘点
   - Session 1-3: 标签保持状态时间更长

10. **功率设置**:
    - 功率过大可能导致过热
    - 功率过小影响读取距离
    - 建议根据实际环境测试最佳值

## 故障排查

### 初始化失败
- 确认设备是否支持RFID功能
- 检查是否有其他应用占用RFID模块
- 查看logcat日志获取详细错误信息

### 盘点不到标签
- 检查输出功率设置（`getOutputPower()`）
- 确认频率区域设置正确
- 检查是否设置了掩码过滤
- 验证标签是否在读取范围内

### 读写失败
- 确认访问密码是否正确
- 检查存储区和地址是否有效
- 验证标签是否被锁定
- 确认数据长度与字数匹配

### EventChannel无事件
- 确认监听在`init()`之前注册
- 检查eventChannel名称是否为`"plugin_rfid_event"`
- 验证`eventSink`是否为null（查看logcat）

## 版本要求

- **Flutter**: 2.0+
- **Dart**: 2.12+
- **Android SDK**: API 19+
- **依赖**: 
  - com.ubx.usdk:USDKManager
  - com.ubx.usdk.rfid:RfidManager
  - com.google.gson:Gson

## 技术支持

如需技术支持,请联系UROVO技术支持团队。

## License

Copyright © UROVO Technology Co., Ltd.
