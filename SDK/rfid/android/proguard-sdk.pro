# UART serial JNI (libserial_port_driver.so) — native code uses GetObjectField by name (e.g. mFd)
-keep class com.rfiddevice.** { *; }

# URFIDLibrary / UBX USDK — full tree (reflection, JNI, BLE/UART, beans)
-keep class com.ubx.** { *; }
-keep enum com.ubx.** { *; }
-keep interface com.ubx.** { *; }

# Urovo platform_sdk JAR (android.device.* + AIDL stubs in android.content.pm.*)
-keep class android.device.** { *; }
-keep class android.content.pm.IPackageDeleteObserver { *; }
-keep class android.content.pm.IPackageDeleteObserver$* { *; }
-keep class android.content.pm.IPackageInstallObserver { *; }
-keep class android.content.pm.IPackageInstallObserver$* { *; }
-keep class android.content.pm.OnFinishObserver { *; }
-keep class android.content.pm.OnFinishObserver$* { *; }

# Gson (URFID / beans)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Flutter plugin bridge
-keep class com.urovo.rfid.** { *; }
