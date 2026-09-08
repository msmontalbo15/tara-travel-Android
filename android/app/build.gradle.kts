import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Sign-In support via google-services.json
    id("com.google.gms.google-services")
}

// ── Signing Config (key.properties or environment variables) ────────
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val releaseStoreFile = keystoreProperties.getProperty("RELEASE_STORE_FILE")
    ?: keystoreProperties.getProperty("storeFile")
    ?: System.getenv("KEYSTORE_PATH")

val releaseStorePassword = keystoreProperties.getProperty("RELEASE_STORE_PASSWORD")
    ?: keystoreProperties.getProperty("storePassword")
    ?: System.getenv("KEYSTORE_PASSWORD")

val releaseKeyAlias = keystoreProperties.getProperty("RELEASE_KEY_ALIAS")
    ?: keystoreProperties.getProperty("keyAlias")
    ?: System.getenv("KEY_ALIAS")

val releaseKeyPassword = keystoreProperties.getProperty("RELEASE_KEY_PASSWORD")
    ?: keystoreProperties.getProperty("keyPassword")
    ?: System.getenv("KEY_PASSWORD")

val resolvedStoreFile = releaseStoreFile?.let { path ->
    val f = file(path)
    if (f.exists()) f else rootProject.file(path)
}

val hasReleaseKey = resolvedStoreFile != null && resolvedStoreFile.exists() &&
                    !releaseStorePassword.isNullOrBlank() &&
                    !releaseKeyAlias.isNullOrBlank() &&
                    !releaseKeyPassword.isNullOrBlank()

android {
    namespace   = "com.taratravel.app"
    compileSdk  = flutter.compileSdkVersion
    ndkVersion  = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // ── Signing Configs ─────────────────────────────────────────────────────
    signingConfigs {
        getByName("debug") {
            val customDebugKeystore = file("tara_debug.keystore")
            if (customDebugKeystore.exists()) {
                storeFile = customDebugKeystore
                storePassword = "taradebug"
                keyAlias = "taradebugkey"
                keyPassword = "taradebug"
            }
        }
        create("release") {
            if (hasReleaseKey && resolvedStoreFile != null) {
                storeFile     = resolvedStoreFile
                storePassword = releaseStorePassword
                keyAlias      = releaseKeyAlias
                keyPassword   = releaseKeyPassword
            }
        }
    }

    defaultConfig {
        applicationId = "com.taratravel.app"
        // minSdk 23 required by flutter_secure_storage EncryptedSharedPreferences
        // and the Google Credential Manager API.
        minSdk = flutter.minSdkVersion
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName

        // Build-time constant exposed to Dart via --dart-define; not a secret.
        buildConfigField("String", "BUILD_TYPE", "\"${project.findProperty("buildType") ?: "debug"}\"")
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        // ── Debug ─────────────────────────────────────────────────────────
        debug {
            isMinifyEnabled   = false
            isShrinkResources = false
            signingConfig     = signingConfigs.getByName("debug")
        }

        // ── Release ───────────────────────────────────────────────────────
        release {
            // R8 full-mode code shrinking + obfuscation.
            isMinifyEnabled   = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing for local `flutter run --release` tests.
                // NEVER ship a Play Store build without a proper release signing config.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
