# Urovo RFID Flutter Plugin — Integration Guide

How to integrate the `rfid` plugin: dependencies, Android native libraries, permissions, BLE notes, channels, events, and typical flows.  
**Dart API quick reference**: [API_REFERENCE.en.md](API_REFERENCE.en.md).  
中文: [INTEGRATION_GUIDE.zh-CN.md](INTEGRATION_GUIDE.zh-CN.md).

---

## 1. Overview

| Item | Description |
|------|-------------|
| **Package** | `rfid` |
| **Platforms** | **Android** (`pluginClass: RfidPlugin`, package `com.urovo.rfid`) |
| **Dart SDK** | `^3.11.1` (see `pubspec.yaml`) |
| **Native** | `URFIDLibrary` AAR, `platform_sdk` JAR, `gson`, etc. under `android/libs/` — the **host app must bundle them at runtime** (see below). |

---

## 2. Host app setup

### 2.1 Flutter dependency

In your app `pubspec.yaml`:

```yaml
dependencies:
  rfid:
    path: ../rfid
```

Then:

```bash
flutter pub get
```

### 2.2 Android: bundle native libs into the APK (required)

The plugin’s `android` module uses **compileOnly** for `URFIDLibrary`; AARs are **not** shipped in the final APK automatically. Your **application** module must depend on the plugin’s `libs` folder (same as the official example).

In **`android/app/build.gradle.kts`**:

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

Adjust paths for your repo layout (e.g. `../../../../rfid/android/libs` relative to `android/app`).

### 2.3 Android: SDK and Java

- **minSdk**: **24+** recommended (matches the example; satisfy `integration_test` if used).
- **Java**: **17** (align `sourceCompatibility` / `targetCompatibility` with the plugin).

### 2.4 Permissions (Bluetooth / location)

Declare in `AndroidManifest.xml` and request at runtime where required:

- `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` (Android 12+)
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` (often needed for LE scan)

You may use `permission_handler` (see `example/`).

### 2.5 BLE handheld / split reader

- **Scanning**: implemented by the host app (e.g. `flutter_blue_plus`); the plugin does **not** provide scan UI.
- **Connection**: call `initSdkBle(String mac)` with the same MAC string shape as the OS (e.g. `AA:BB:CC:DD:EE:FF`).
- **Avoid dual GATT**: before `initSdkBle`, **stop scanning** and **disconnect** any other library’s connection to the **same MAC** (e.g. FBP), then wait briefly — otherwise GATT `133` or a stuck `InitListener` is common. Consider a **timeout** (e.g. 45s) around `initSdkBle` and user-facing retry.

### 2.6 Release shrinking / obfuscation (R8 / ProGuard)

If your app’s **release** build uses **R8** (code shrinking and obfuscation), you must keep the class / package / **field names** that URFID and bundled native code rely on. Otherwise you may see runtime failures or JNI aborts (e.g. on `releaseSdk`, `SerialPort.close` with **`NoSuchFieldError` for `mFd`**).

**Bundled rules file**: `rfid/android/proguard-sdk.pro`, registered in the plugin’s `android/build.gradle.kts` via **`consumerProguardFiles("proguard-sdk.pro")`**. With a **`path`** dependency on this plugin, Gradle usually **merges** those rules into the host app’s R8 configuration.

The file (authoritative copy is in the repo) currently keeps, among others:

| Scope | Notes |
|-------|--------|
| **`com.rfiddevice.**`** | Serial JNI (`libserial_port_driver.so` uses `GetObjectField` on e.g. `SerialPort.mFd`) — **names must not be stripped or obfuscated** |
| **`com.ubx.**`** | Full URFIDLibrary / USDK tree (reflection, beans, connection stack) |
| **`android.device.**` and `android.content.pm.*` stubs** | `platform_sdk` JAR |
| **Gson** | Serialization-related keeps |
| **`com.urovo.rfid.**`** | Flutter plugin Java bridge |

**Host app checklist**:

1. If rules are **not** merged (e.g. you only copy `libs` and skip the plugin’s Android library), add **`proguard-sdk.pro`** explicitly under **`proguardFiles(...)`** in **`android/app`** `buildTypes.release` (adjust the path).  
2. The official **`example`** references `../../../android/proguard-sdk.pro` in `android/app/build.gradle.kts` — use it as a template.

---

## 3. Channels

| Kind | Name | Role |
|------|------|------|
| **MethodChannel** | `rfid` | All `Future`-based calls |
| **EventChannel** | `plugin_rfid_event` | Native → Dart events; subscribe via **`Rfid.rawEventStream`** (single engine subscription + **broadcast** to multiple Dart listeners) |

---

## 4. Event stream `Rfid.rawEventStream`

Each event is a `Map` with at least:

- **`eventType`**: `String`
- **`data`**: type depends on event (`Map`, `String`, etc.)

| eventType | Meaning | `data` |
|-----------|---------|--------|
| `event_inventory_tag` | Tag in inventory | `Map`: `EPC`, `TID`, `RSSI`, `BID`, … |
| `event_inventory_tag_end` | Inventory round ended | placeholder |
| `event_battery` | Battery update | `Map`: `isCharging`, `level` |
| `event_barcode` | Barcode result | `String` |
| `event_key` | Key event | `Map`: `keyCode`, `isDown` |
| `event_module_switch` | Module switch (if supported) | implementation-specific |
| `event_fw_update` | Firmware update progress | `Map`: `code`, `progress`, … |
| **`event_connection`** | **Reader link state** | **`Map`**: **`connected`** → `bool`. Fired on **every** native `InitListener.onStatus`. **Independent** of the one-shot `initSdk` / `initSdkBle` MethodChannel result. |

**Use `Rfid.rawEventStream`** and branch on `eventType`. Do not attach multiple raw `EventChannel` listeners yourself — the native side keeps a single `EventSink`.

---

## 5. Typical flows

### 5.1 Integrated / UART

1. `await rfid.initSdk()` → `0` means success.  
2. `Rfid.rawEventStream.listen` for inventory, battery, `event_connection`, etc.  
3. Call inventory / read-write / settings APIs (see API reference).  
4. When leaving: `await rfid.releaseSdk()`.

### 5.2 BLE

1. Host scans and obtains MAC.  
2. **Stop scan**, **disconnect** other GATT clients for that MAC if any.  
3. Short delay, then `await rfid.initSdkBle(mac)` (with **timeout** recommended).  
4. Listen to `rawEventStream`; link loss → **`event_connection` with `connected: false`**.  
5. When done: `await rfid.releaseSdk()`.

### 5.3 Init `Future` vs `event_connection`

- **`initSdk` / `initSdkBle` `Future<int>`**: completes once for **that** init attempt (`0` = OK).  
- **Later disconnect/reconnect**: reported via **`event_connection`** only; the old init `Future` is **not** completed again (plugin guards `Result` to avoid “Reply already submitted”).

---

## 6. Example app

The **`example/`** project is a runnable demo (connect, inventory, read/write, settings, disconnect, BLE vs integrated). Use its `pubspec.yaml` and `android/app/build.gradle.kts` as templates.

---

## 7. Maintaining this doc

- Behavior: **`lib/rfid.dart`**, **`lib/rfid_method_channel.dart`**, Android **`RfidPlugin.java`**.  
- API surface: **`lib/rfid_platform_interface.dart`** ([API_REFERENCE.en.md](API_REFERENCE.en.md)).   
- **Release obfuscation**: see **§2.6**; source file **`rfid/android/proguard-sdk.pro`**.
