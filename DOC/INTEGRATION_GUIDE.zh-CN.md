# Urovo RFID Flutter 插件 — 接入指南

本文说明如何将 `rfid` 插件集成到宿主应用：依赖、Android 原生库、权限、BLE 注意事项、通信通道与事件订阅、典型业务流程。  
**Dart API 与数据类型速查**见 [API_REFERENCE.zh-CN.md](API_REFERENCE.zh-CN.md)。  
English: [INTEGRATION_GUIDE.en.md](INTEGRATION_GUIDE.en.md).

---

## 1. 插件概述

| 项 | 说明 |
|----|------|
| **包名** | `rfid` |
| **支持平台** | **Android**（`pluginClass: RfidPlugin`，包名 `com.urovo.rfid`） |
| **Dart SDK** | `^3.11.1`（以 `pubspec.yaml` 为准） |
| **原生依赖** | `URFIDLibrary` AAR、`platform_sdk` JAR、`gson` 等（位于插件 `android/libs/`，宿主 App 需 **runtime 打入**，见下文） |

---

## 2. 宿主工程接入

### 2.1 添加 Flutter 依赖

在应用 `pubspec.yaml` 中：

```yaml
dependencies:
  rfid:
    path: ../rfid
```

执行：

```bash
flutter pub get
```

### 2.2 Android：将原生库打入 APK（必做）

插件 `android` 模块对 `URFIDLibrary` 等为 **compileOnly**，**不会**自动把 AAR 打进最终 APK。宿主 **application** 模块需显式依赖插件目录下的 `libs`（与官方 Demo 一致）：

在 **`android/app/build.gradle.kts`** 中：

```kotlin
repositories {
    flatDir {
        dirs("path/to/rfid_plugin/android/libs")
    }
}

dependencies {
    val rfidLibs = file("path/to/rfid_plugin/android/libs")
    implementation(fileTree(mapOf("dir" to rfidLibs, "include" to listOf("*.aar", "*.jar"))))
}
```

路径请按实际 monorepo / 拷贝位置调整（例如相对 `android/app` 的 `../../../../rfid/android/libs`）。

### 2.3 Android：版本与编译选项

- **minSdk**：建议 **24+**（与 Demo 一致；若使用 `integration_test` 等也需满足其要求）。
- **Java**：插件侧使用 **17**（与宿主 `sourceCompatibility` / `targetCompatibility` 对齐）。

### 2.4 权限（蓝牙 / 定位）

BLE 扫描与连接需按系统版本在 `AndroidManifest.xml` 中声明并在运行时申请：

- `BLUETOOTH_SCAN`、`BLUETOOTH_CONNECT`（Android 12+）
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`（扫描 LE 时常需要）

可使用 `permission_handler` 等（参见 `example` 工程）。

### 2.5 BLE 分体设备接入注意

- **扫描**：由宿主 App 完成（如 `flutter_blue_plus`），插件 **不负责** 扫描 UI。
- **连接**：调用 `initSdkBle(String mac)`，**MAC 格式**与系统回调一致（如 `AA:BB:CC:DD:EE:FF`）。
- **避免双 GATT**：在调用 `initSdkBle` 前，应 **停止扫描**，并对已由 FBP 等建立的 **同 MAC 连接执行 disconnect**，短暂延迟后再初始化（否则易出现 GATT `133` 或 `InitListener` 长时间不回调）。建议对 `initSdkBle` 做 **超时**（如 45s）并提示用户重试。

### 2.6 Release 混淆（R8 / ProGuard）注意事项

宿主 App 的 **release** 若开启 **代码压缩与混淆**（R8），必须保留 URFID 及配套原生库对 **类名、包名、部分字段名** 的约定，否则易出现运行时异常甚至 JNI 崩溃（例如 `releaseSdk` 时 `SerialPort.close` 报 `mFd` 字段找不到）。

**插件已提供统一规则文件**：`rfid/android/proguard-sdk.pro`，并在插件 `android/build.gradle.kts` 的 `defaultConfig` 中通过 **`consumerProguardFiles("proguard-sdk.pro")`** 声明。使用 **`path` 依赖本插件** 时，Gradle 通常会把该规则 **合并进宿主 App** 的 R8 配置。

规则文件当前覆盖（随 SDK 升级可能扩展，以仓库内文件为准）包括但不限于：

| 范围 | 说明 |
|------|------|
| **`com.rfiddevice.**`** | 串口 JNI（如 `libserial_port_driver.so` 通过 `GetObjectField` 访问 `SerialPort.mFd` 等），**字段名不可被混淆或剔除** |
| **`com.ubx.**`** | URFIDLibrary / USDK 全包（反射、Bean、连接实现等） |
| **`android.device.**` 与 `android.content.pm.*` 桩类** | `platform_sdk` JAR 中的设备 API 与 AIDL 桩 |
| **`com.google.gson.**` 等** | Gson 与序列化相关保留 |
| **`com.urovo.rfid.**`** | 本 Flutter 插件 Java 桥接 |

**请宿主工程自检**：

1. 若 release **未**合并到上述规则（例如仅拷贝 `libs`、未依赖插件 Android 子工程），请在 **`android/app/build.gradle(.kts)`** 的 `buildTypes.release` 中 **`proguardFiles(...)`** 显式加入插件目录下的 **`proguard-sdk.pro`**（路径按工程结构调整）。  
2. 官方 **`example`** 已在 `android/app/build.gradle.kts` 的 release 中引用 `../../../android/proguard-sdk.pro`，可作模板对照。

---

## 3. 通信通道

| 类型 | 名称 | 说明 |
|------|------|------|
| **MethodChannel** | `rfid` | 所有 `Future` 形式 API（请求 / 异步完成） |
| **EventChannel** | `plugin_rfid_event` | 原生主动推送；Dart 通过 **`Rfid.rawEventStream`** 订阅（插件内 **单次** 订阅 + **broadcast**，支持多监听方） |

---

## 4. 事件流 `Rfid.rawEventStream`

每条事件为 `Map`，至少包含：

- **`eventType`**：`String`
- **`data`**：视类型而定（`Map` / `String` / 其他）

| eventType | 含义 | data 说明 |
|-----------|------|-----------|
| `event_inventory_tag` | 盘存到标签 | `Map`：`EPC`、`TID`、`RSSI`、`BID` 等 |
| `event_inventory_tag_end` | 本轮盘存结束 | 占位 |
| `event_battery` | 电池变化 | `Map`：`isCharging`、`level` |
| `event_barcode` | 条码结果 | 字符串 |
| `event_key` | 按键 | `Map`：`keyCode`、`isDown` |
| `event_module_switch` | 模块开关（若 SDK 支持） | 视实现 |
| `event_fw_update` | 固件升级进度 | `Map`：`code`、`progress` 等 |
| **`event_connection`** | **读写器链路状态** | **`Map`**：`**connected`** → `bool`。每次原生 `InitListener.onStatus` 都会推送。与单次 `initSdk` / `initSdkBle` 的 MethodChannel 返回值 **独立**。 |

**订阅建议**：按 `eventType` 分支处理。请使用 **`Rfid.rawEventStream`**，不要对 `EventChannel` 自行多次 `listen`（会覆盖原生单一 `EventSink`）。

---

## 5. 典型调用流程

### 5.1 一体机

1. `await rfid.initSdk()` → `0` 表示成功。  
2. `Rfid.rawEventStream.listen` 处理盘存、电池、`event_connection` 等。  
3. 调用盘存 / 读写 / 设置等 API（见 API 速查表）。  
4. 退出模块或页面：`await rfid.releaseSdk()`。

### 5.2 BLE 分体

1. 宿主扫描得到 MAC。  
2. **停止扫描**、**断开** 其他库对同 MAC 的 GATT（如有）。  
3. 短延迟后 `await rfid.initSdkBle(mac)`（建议 **timeout**）。  
4. 监听 `rawEventStream`；断线时会收到 **`event_connection`：`connected: false`**。  
5. 使用完毕 `await rfid.releaseSdk()`。

### 5.3 初始化 Future 与 `event_connection`

- **`initSdk` / `initSdkBle` 的 `Future<int>`**：仅表示**本次**初始化是否完成并成功注册（`0` 成功）。  
- **后续断开/重连**：由 **`event_connection`** 通知；**不会**再次完成已结束的 init Future（插件对 `Result` 做一次性回复，避免崩溃）。

---

## 6. 参考工程

仓库 **`example/`** 含可运行 Demo（连接、盘存、读写、设置、断开、BLE/一体机切换）。对照其 `pubspec.yaml` 与 `android/app/build.gradle.kts`。

---

## 7. 文档维护

- 行为以 **`lib/rfid.dart`**、**`lib/rfid_method_channel.dart`**、**Android `RfidPlugin.java`** 为准。  
- API 列表以 **`lib/rfid_platform_interface.dart`** 为准（见 [API_REFERENCE.zh-CN.md](API_REFERENCE.zh-CN.md)）。    
- **Release 混淆**：见 **§2.6**，规则源文件为 **`rfid/android/proguard-sdk.pro`**。
