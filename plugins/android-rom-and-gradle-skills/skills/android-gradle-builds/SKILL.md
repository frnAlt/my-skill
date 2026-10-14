---
name: android-gradle-builds
description: Instructions and best practices for Android app development and Gradle build systems. Use when configuring build.gradle, settings.gradle, libs.versions.toml version catalogs, ProGuard/R8 shrinking rules, signing configurations, multi-module Android projects, or troubleshooting Gradle build errors and daemon issues.
---

# Android Gradle Build Specialist

This skill provides comprehensive instructions for managing, optimizing, and troubleshooting Android Gradle builds, Kotlin DSL (`build.gradle.kts`), Version Catalogs, and build variants.

## 1. Version Catalogs (`gradle/libs.versions.toml`)

Always prefer Gradle Version Catalogs for declaring dependencies in modern Android projects.

```toml
[versions]
agp = "8.3.2"
kotlin = "2.0.0"
coreKtx = "1.13.1"
composeBom = "2024.06.00"

[libraries]
androidx-core-ktx = { group = "androidx.core", name = "core-ktx", version.ref = "coreKtx" }
androidx-compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "composeBom" }
androidx-compose-ui = { group = "androidx.compose.ui", name = "ui" }
androidx-compose-material3 = { group = "androidx.compose.material3", name = "material3" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
compose-compiler = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
```

## 2. Optimized App-Level `build.gradle.kts`

```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.compose.compiler)
}

android {
    namespace = "com.example.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            applicationIdSuffix = ".debug"
            isDebuggable = true
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf(
            "-opt-in=kotlinx.coroutines.ExperimentalCoroutinesApi"
        )
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.material3)
}
```

## 3. Build Performance & Speed Optimizations (`gradle.properties`)

Ensure these flags are configured to accelerate local compilation:

```properties
# Enable Gradle Daemon and parallel project execution
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.vfs.watch=true

# JVM memory allocation tuned for modern Android builds
org.gradle.jvmargs=-Xmx4096m -XX:+UseG1GC -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError

# Enable configuration caching (Android Gradle Plugin 8+)
org.gradle.configuration-cache=true

# Kotlin incremental compilation
kotlin.incremental=true
kotlin.incremental.useClasspathSnapshot=true
```

## 4. Essential Troubleshooting Commands

- **Diagnose Dependency Conflicts:**
  ```bash
  ./gradlew app:dependencies --configuration implementation
  ./gradlew app:dependencyInsight --dependency <artifact-name> --configuration implementation
  ```
- **Verbose Error Tracing:**
  ```bash
  ./gradlew assembleDebug --stacktrace --info
  ```
- **Clean Daemon and Lock State:**
  ```bash
  ./gradlew --stop
  rm -rf ~/.gradle/caches/
  ./gradlew clean assembleDebug
  ```
- **Generate Build Scans:**
  ```bash
  ./gradlew assembleDebug --scan
  ```
