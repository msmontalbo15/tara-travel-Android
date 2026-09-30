import '../models/payment_provider.dart';

/// Abstract contract for Philippine e-wallet ownership verification (OTP + QR).
///
/// Ensures provider-agnostic extensibility so GCash and Maya (and future e-wallets)
/// can share the same verification pipelines, trust badges, and security gates.
abstract class EWalletVerificationService {
  PaymentProvider get provider;

  /// Validates whether [input] represents a valid 11-digit Philippine mobile number.
  static bool isValidPhilippineNumber(String input) {
    final clean = input.replaceAll(RegExp(r'[\s\-+()]'), '');
    if (clean.startsWith('63') && clean.length == 12) {
      return clean.startsWith('639');
    }
    if (clean.startsWith('09') && clean.length == 11) {
      return true;
    }
    if (clean.startsWith('9') && clean.length == 10) {
      return true;
    }
    return false;
  }

  /// Converts Philippine mobile number into standard E.164 format (+639XXXXXXXXX).
  static String normalizeToE164(String input) {
    final clean = input.replaceAll(RegExp(r'[\s\-+()]'), '');
    if (clean.startsWith('63') && clean.length == 12) {
      return '+$clean';
    }
    if (clean.startsWith('09') && clean.length == 11) {
      return '+63${clean.substring(1)}';
    }
    if (clean.startsWith('9') && clean.length == 10) {
      return '+63$clean';
    }
    return input.trim();
  }

  /// Formats number for Philippine local UI display (e.g. `0917 123 4567`).
  static String formatForDisplay(String input) {
    final digits10 = extractSignificant10Digits(input);
    if (digits10.length != 10) return input;
    final prefix = '0${digits10.substring(0, 3)}';
    final mid = digits10.substring(3, 6);
    final tail = digits10.substring(6);
    return '$prefix $mid $tail';
  }

  /// Extracts the core 10 significant digits (`9XXXXXXXXX`) for invariant comparison.
  static String extractSignificant10Digits(String input) {
    final clean = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length >= 10) {
      return clean.substring(clean.length - 10);
    }
    return clean;
  }

  /// Sends a one-time SMS verification code to [phoneNumber].
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(String verificationId)? onAutoVerified,
  });

  /// Validates the entered 6-digit [smsCode] against [verificationId].
  Future<bool> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Extracts the embedded phone number from the e-wallet QR code URI payload.
  String? decodeQrPayload(String rawQrData);

  /// Validates whether the scanned QR code payload matches the user's verified number.
  bool validateQrMatchesVerifiedNumber({
    required String rawQrData,
    required String verifiedNumber,
  }) {
    final extractedNumber = decodeQrPayload(rawQrData);
    if (extractedNumber == null) return false;

    final qr10 = extractSignificant10Digits(extractedNumber);
    final verified10 = extractSignificant10Digits(verifiedNumber);
    return qr10.isNotEmpty && qr10 == verified10;
  }
}
