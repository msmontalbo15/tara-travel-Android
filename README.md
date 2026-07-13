# Tara Travel

A **Flutter** travel planning app showcasing modern architecture, clean UI, and secure authentication.

## Overview
This project demonstrates:

# Install Flutter dependencies
flutter pub get

# Run the app (Android emulator or device)
flutter run
```

## Building for Production
```bash
# Release build (Android .aab)
flutter build appbundle --release

# iOS (requires macOS)
flutter build ipa --release
```

## Security Hardening
- All secrets are loaded from environment variables or secure storage; **no hard‑coded API keys**.
- Network calls enforce **HTTPS** with certificate pinning.
- Local DB uses **SQLCipher** via `sqflite_sqlcipher`.
- ProGuard/R8 rules are configured in `android/app/proguard-rules.pro`.
- Rate‑limiting and abuse detection are built into the backend (via Redis sliding window).

## Contributing
Feel free to open issues or submit pull requests. Follow the existing code style, run `flutter test` before submitting.

## License
MIT License – see `LICENSE` file.
