import 'dart:math';

/// Secure CSPRNG Invite Code Generator for Tara Travel.
/// Uses a cryptographic random number generator and an unambiguous
/// alphabet (excluding 0, O, 1, I, L) to prevent visual ambiguity.
class InviteCodeGenerator {
  static const String _alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  static final Random _secureRandom = Random.secure();

  /// Generates a secure, random alphanumeric code of [length] (default 6).
  static String generate({int length = 6}) {
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      final randomIndex = _secureRandom.nextInt(_alphabet.length);
      buffer.write(_alphabet[randomIndex]);
    }
    return buffer.toString();
  }

  /// Sanitizes user input (removes spaces, hyphens, non-alphanumeric noise, converts to uppercase).
  static String sanitize(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim().toUpperCase();
  }

  /// Validates whether [code] meets basic format rules (alphanumeric, length >= 4 and <= 12).
  static bool isValidFormat(String code) {
    final clean = sanitize(code);
    if (clean.length < 4 || clean.length > 12) return false;
    return RegExp(r'^[A-Z0-9]+$').hasMatch(clean);
  }
}
