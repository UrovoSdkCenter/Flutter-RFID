group = "com.urovo.rfid"
version = "2.6.0313"

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.11.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "com.urovo.rfid"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 24
        consumerProguardFiles("proguard-sdk.pro")
    }

    // 添加 repositories 配置以支持 flatDir
    repositories {
        flatDir {
            dirs("libs")
        }
    }

    testOptions {
        unitTests.all {
            it.outputs.upToDateWhen { false }

            it.testLogging {
                events("passed", "skipped", "failed", "standardOut", "standardError")
                showStandardStreams = true
            }
        }
    }
}

dependencies {
    //
    implementation(files("libs/platform_sdk_v4.1.0326.jar"))
    implementation(files("libs/gson-2.10.1.jar"))
    compileOnly(files("libs/URFIDLibrary-v2.6.0313.aar"))
    //
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.0.0")
}
