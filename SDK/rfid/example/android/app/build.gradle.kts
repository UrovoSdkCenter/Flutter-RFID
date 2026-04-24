plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.urovo.rfid_example"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.urovo.rfid_example"
        minSdk = 24 // integration_test requires API 24+
        targetSdk = flutter.targetSdkVersion
        // 与 URFIDLibrary-v2.6.0313 版本名对齐（pub semver 无前导零 patch，此处展示原生库一致名称）
        versionCode = 260313
        versionName = "2.6.0313"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                file("../../../android/proguard-sdk.pro"),
            )
        }
    }

    // 让 Gradle 能解析本地 AAR / Allow Gradle to resolve local AARs
    repositories {
        flatDir {
            dirs("../../../../rfid/android/libs")
        }
    }
}

dependencies {
    // URFIDLibrary 及其依赖在插件库中以 compileOnly 引入（仅编译期），
    // 运行时需要在 app 层以 implementation 打入 APK。
    // Runtime dependency: URFIDLibrary and its companions must be bundled in the APK.
    val rfidLibs = file("../../../../rfid/android/libs")
    implementation(fileTree(mapOf("dir" to rfidLibs, "include" to listOf("*.aar", "*.jar"))))
}

flutter {
    source = "../.."
}
