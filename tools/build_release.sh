#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# Tara Travel — Production Release Build Script
# ═══════════════════════════════════════════════════════════════════════════════
#
# Builds a signed Android App Bundle (.aab) with:
#   • Dart-level code obfuscation (--obfuscate)
#   • Debug symbols split out for crash reporter upload (--split-debug-info)
#   • R8 full-mode shrinking/obfuscation (configured in build.gradle.kts)
#   • ProGuard rules from android/app/proguard-rules.pro
#
# Required environment variables (set in CI/CD secrets — NEVER hardcode here):
#   KEYSTORE_PATH      — absolute path to release .jks keystore
#   KEYSTORE_PASSWORD  — keystore password
#   KEY_ALIAS          — key alias within the keystore
#   KEY_PASSWORD       — key password
#
# Usage:
#   # Local (requires env vars set):
#   bash tools/build_release.sh
#
#   # CI/CD:
#   bash tools/build_release.sh --upload-crashlytics
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEBUG_SYMBOLS_DIR="$PROJECT_ROOT/build/debug-symbols"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "══════════════════════════════════════════════"
echo " Tara Travel — Release Build  ($TIMESTAMP)"
echo "══════════════════════════════════════════════"

# ── Validate required env vars ────────────────────────────────────────────────
required_vars=("KEYSTORE_PATH" "KEYSTORE_PASSWORD" "KEY_ALIAS" "KEY_PASSWORD")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "❌ ERROR: Missing required environment variable: $var"
        echo "   Set it in your CI/CD secrets or local shell environment."
        exit 1
    fi
done

# ── Clean previous build artifacts ────────────────────────────────────────────
echo "▶ Cleaning build artifacts..."
flutter clean
flutter pub get

# ── Run static analysis ───────────────────────────────────────────────────────
echo "▶ Running static analysis..."
flutter analyze --no-pub
if [[ $? -ne 0 ]]; then
    echo "❌ Analysis failed — fix issues before releasing."
    exit 1
fi

# ── Run tests ─────────────────────────────────────────────────────────────────
echo "▶ Running test suite..."
flutter test --coverage
if [[ $? -ne 0 ]]; then
    echo "❌ Tests failed — fix failures before releasing."
    exit 1
fi

# ── Build Android App Bundle ──────────────────────────────────────────────────
echo "▶ Building Android App Bundle (release, obfuscated)..."
mkdir -p "$DEBUG_SYMBOLS_DIR"

flutter build appbundle \
    --release \
    --obfuscate \
    --split-debug-info="$DEBUG_SYMBOLS_DIR" \
    --dart-define=BUILD_TYPE=release

echo ""
echo "✅ Build complete!"
echo "   AAB:           build/app/outputs/bundle/release/app-release.aab"
echo "   Debug symbols: $DEBUG_SYMBOLS_DIR"
echo ""
echo "📤 Next steps:"
echo "   1. Upload debug symbols to Firebase Crashlytics or Sentry:"
echo "      firebase crashlytics:symbols:upload --app=<APP_ID> $DEBUG_SYMBOLS_DIR"
echo "   2. Upload AAB to Google Play Console internal track for testing."
echo "   3. Never commit the AAB or debug symbols to source control."
