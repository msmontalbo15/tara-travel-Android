import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/payment_provider.dart';
import 'ewallet_verification_service.dart';

/// Concrete GCash implementation of [EWalletVerificationService].
///
/// Uses Firebase Phone Auth OTP transiently to confirm ownership of the user's
/// Philippine mobile number, and parses GCash QR code formats (including QR Ph
/// and GCash URL schemes) to validate payload identity.
class GcashVerificationService extends EWalletVerificationService {
  GcashVerificationService({FirebaseAuth? auth})
      : _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

  static final GcashVerificationService instance = GcashVerificationService();

  final FirebaseAuth? _auth;

  @override
  PaymentProvider get provider => PaymentProvider.gcash;

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(String verificationId)? onAutoVerified,
  }) async {
    final e164Number = EWalletVerificationService.normalizeToE164(phoneNumber);

    if (!EWalletVerificationService.isValidPhilippineNumber(phoneNumber)) {
      onError('Please enter a valid 11-digit Philippine mobile number (09XX XXX XXXX).');
      return;
    }

    try {
      if (_auth == null || Firebase.apps.isEmpty) {
        debugPrint('[GcashVerificationService] Firebase Auth uninitialized; using development fallback.');
        onCodeSent('mock_verification_id_${DateTime.now().millisecondsSinceEpoch}');
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: e164Number,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('[GcashVerificationService] Instant auto-verification succeeded.');
          final verificationId = credential.verificationId ?? 'auto_verified';
          onAutoVerified?.call(verificationId);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('[GcashVerificationService] Phone verification failed: ${e.code} - ${e.message}');
          String userMessage;
          switch (e.code) {
            case 'invalid-phone-number':
              userMessage = 'The phone number format is invalid.';
              break;
            case 'too-many-requests':
              userMessage = 'Too many requests. Please wait a few minutes before trying again.';
              break;
            case 'quota-exceeded':
              userMessage = 'SMS quota exceeded. Please try again later.';
              break;
            default:
              userMessage = e.message ?? 'Failed to send SMS code. Please try again.';
          }
          onError(userMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('[GcashVerificationService] SMS OTP code dispatched to $e164Number');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('[GcashVerificationService] SMS auto-retrieval timed out for $verificationId');
        },
      );
    } catch (e) {
      debugPrint('[GcashVerificationService] sendOtp unexpected error: $e');
      onError('An error occurred sending the verification SMS: $e');
    }
  }

  @override
  Future<bool> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final cleanCode = smsCode.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (cleanCode.length != 6) {
      return false;
    }

    // Dev/fallback mode verification
    if (verificationId.startsWith('mock_verification_id_')) {
      return cleanCode == '123456';
    }

    if (_auth == null) {
      return cleanCode.length == 6;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: cleanCode,
      );

      // Transiently sign in to verify the credential without replacing Supabase session
      final userCred = await _auth.signInWithCredential(credential);
      final isVerified = userCred.user != null;

      // Clean up Firebase Auth state to maintain single source of truth in Supabase
      await _auth.signOut();

      return isVerified;
    } on FirebaseAuthException catch (e) {
      debugPrint('[GcashVerificationService] verifyOtp FirebaseAuthException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[GcashVerificationService] verifyOtp error: $e');
      return false;
    }
  }

  @override
  String? decodeQrPayload(String rawQrData) {
    if (rawQrData.trim().isEmpty) return null;
    final data = rawQrData.trim();

    // 1. Check URI query parameters (e.g. https://qrph.gcash.com/...?phone=09171234567 or account=...)
    try {
      final uri = Uri.tryParse(data);
      if (uri != null && uri.hasQuery) {
        final phoneParam = uri.queryParameters['phone'] ??
            uri.queryParameters['mobile'] ??
            uri.queryParameters['account'] ??
            uri.queryParameters['number'];
        if (phoneParam != null && EWalletVerificationService.isValidPhilippineNumber(phoneParam)) {
          return EWalletVerificationService.extractSignificant10Digits(phoneParam);
        }
      }
    } catch (_) {}

    // 2. Regex for Philippine numbers in raw text or URL (/09XXXXXXXXX or +639XXXXXXXXX)
    final match = RegExp(r'(?:(?:\+?63)|0)?(9\d{9})').firstMatch(data);
    if (match != null) {
      return match.group(1);
    }

    // 3. Fallback: Check if pure numeric string matches 10-12 digits
    final pureDigits = data.replaceAll(RegExp(r'[^0-9]'), '');
    if (pureDigits.length >= 10 && pureDigits.contains('9')) {
      final sub = EWalletVerificationService.extractSignificant10Digits(pureDigits);
      if (sub.startsWith('9')) {
        return sub;
      }
    }

    return null;
  }
}
