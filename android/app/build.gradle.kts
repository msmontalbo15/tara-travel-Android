plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Sign-In support via google-services.json
    id("com.google.gms.google-services")
}

// ── Signing Config (environment-variable driven — zero hardcoded paths) ────────
// Set these environment variables in your CI/CD pipeline secrets:
//   KEYSTORE_PATH      — absolute path to the release .jks or .keystore file
//   KEYSTORE_PASSWORD  — the keystore password
//   KEY_ALIAS          — the key alias
//   KEY_PASSWORD       — the key password
//
// During local debug builds these are not required (debug signing is used).
val keystorePath     = System.getenv("KEYSTORE_PATH")
val keystorePassword = System.getenv("KEYSTORE_PASSWORD")
val keyAlias         = System.getenv("KEY_ALIAS")
val keyPassword      = System.getenv("KEY_PASSWORD")
val hasReleaseKey    = keystorePath != null && keystorePassword != null &&
                       keyAlias != null && keyPassword != null

android {
    namespace   = "com.example.tara_travel"
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
        create("release") {
            if (hasReleaseKey) {
                storeFile     = file(keystorePath!!)
                storePassword = keystorePassword
                keyAlias      = keyAlias
                keyPassword   = keyPassword
            }
        }
    }

    defaultConfig {
        applicationId = "com.example.tara_travel"
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
