# ═══════════════════════════════════════════════════════════════════════════════
# Tara Travel — ProGuard / R8 Rules
# ═══════════════════════════════════════════════════════════════════════════════
#
# Applied in release builds via build.gradle.kts:
#   proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
#
# Combined with Flutter's --obfuscate flag (Dart-level obfuscation), this gives
# dual-layer obfuscation: Kotlin/Java classes via R8, Dart code via the Flutter
# toolchain.
# ═══════════════════════════════════════════════════════════════════════════════

# ── Optimisation ──────────────────────────────────────────────────────────────
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# ── Flutter Engine ────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.**

# ── Kotlin ────────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Lazy {
    *;
}

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
-dontwarn kotlinx.coroutines.**

# ── Google Sign-In / Credential Manager ───────────────────────────────────────
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.libraries.**

# ── firebase / google-services ────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ── Supabase / Ktor / OkHttp ──────────────────────────────────────────────────
# Supabase Kotlin SDK (if used via Flutter method channels)
-keep class io.github.jan.supabase.** { *; }
# OkHttp (network layer used by Supabase and various SDKs)
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ── Gson / JSON serialisation ─────────────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ── flutter_secure_storage ────────────────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# ── AndroidX Security (EncryptedSharedPreferences) ───────────────────────────
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**
-keep class androidx.biometric.** { *; }

# ── Android Keystore ──────────────────────────────────────────────────────────
-keep class android.security.keystore.** { *; }

# ── Serializable / Parcelable ─────────────────────────────────────────────────
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# ── Enum ──────────────────────────────────────────────────────────────────────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ── Annotations ───────────────────────────────────────────────────────────────
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes SourceFile
-keepattributes LineNumberTable

# ── Strip debug logging in release builds ────────────────────────────────────
# Eliminates android.util.Log calls — prevents leaking debug info in production.
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# ── Crash reporting stack trace readability (optional) ───────────────────────
# If you use Firebase Crashlytics or Sentry, keep the mapping file by running:
#   flutter build appbundle --release --obfuscate --split-debug-info=build/debug-symbols
# Then upload build/debug-symbols to your crash reporter dashboard.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
