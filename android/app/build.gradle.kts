import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Google Services設定ファイルの存在確認
val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    // 設定ファイルが存在する場合のみGoogle Services Pluginを適用
    apply(plugin = "com.google.gms.google-services")
    println("Google Services Plugin applied (google-services.json found)")
} else {
    println("Google Services Plugin skipped (google-services.json not found)")
}

// キーストア設定を読み込み
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.ikcoding.maikago"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // 警告を非表示にする設定
    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf("-Xlint:-options", "-Xlint:-deprecation"))
    }

    defaultConfig {
        // 本番用のApplication ID
        applicationId = "com.ikcoding.maikago"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
        
        // CMake設定を追加 - より多くのデバイスアーキテクチャをサポート
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")
        }
        

    }

    signingConfigs {
        create("release") {
            // key.propertiesファイルから署名設定を読み込み
            keyAlias = keystoreProperties["keyAlias"] as String? ?: "upload"
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // リリース用の署名設定
            signingConfig = signingConfigs.getByName("release")
            // ProGuardとリソース最適化を完全に無効化
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    // CMakeの問題を回避するための設定
    packagingOptions {
        pickFirst("**/libc++_shared.so")
        pickFirst("**/libjsc.so")
    }
    

    

}

flutter {
    source = "../.."
}

dependencies {
    // Firebase依存関係は設定ファイルがある場合のみ適用
    if (googleServicesFile.exists()) {
        // Import the Firebase BoM
        implementation(platform("com.google.firebase:firebase-bom:33.16.0"))

        // Firebase Analytics
        implementation("com.google.firebase:firebase-analytics")
    }
    
    // Google Play Services
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    implementation("com.google.android.gms:play-services-base:18.2.0")
    
    // Google Play Billing Library 7.0.0以降
    implementation("com.android.billingclient:billing:7.0.0")
    
    // Google Play Coreライブラリは削除（重複クラスエラーのため）
    // implementation("com.google.android.play:core:1.10.3")
    // implementation("com.google.android.play:core-ktx:1.8.1")
}
