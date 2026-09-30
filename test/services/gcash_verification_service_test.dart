import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/models/payment_provider.dart';
import 'package:tara_travel/core/services/ewallet_verification_service.dart';
import 'package:tara_travel/core/services/gcash_verification_service.dart';

void main() {
  group('E-Wallet & GCash Verification Service Tests', () {
    final service = GcashVerificationService.instance;

    test('PaymentProvider parsing handles valid and fallback cases', () {
      expect(PaymentProvider.fromString('gcash'), PaymentProvider.gcash);
      expect(PaymentProvider.fromString('GCASH'), PaymentProvider.gcash);
      expect(PaymentProvider.fromString('maya'), PaymentProvider.maya);
      expect(PaymentProvider.fromString('PayMaya'), PaymentProvider.maya);
      expect(PaymentProvider.fromString(null), PaymentProvider.gcash);
      expect(PaymentProvider.fromString('unknown'), PaymentProvider.gcash);
    });

    test('isValidPhilippineNumber correctly identifies valid and invalid numbers', () {
      // Valid
      expect(EWalletVerificationService.isValidPhilippineNumber('09171234567'), isTrue);
      expect(EWalletVerificationService.isValidPhilippineNumber('+639171234567'), isTrue);
      expect(EWalletVerificationService.isValidPhilippineNumber('639171234567'), isTrue);
      expect(EWalletVerificationService.isValidPhilippineNumber('9171234567'), isTrue);
      expect(EWalletVerificationService.isValidPhilippineNumber('0917 123 4567'), isTrue);
      expect(EWalletVerificationService.isValidPhilippineNumber('+63 917-123-4567'), isTrue);

      // Invalid
      expect(EWalletVerificationService.isValidPhilippineNumber('0281234567'), isFalse); // Landline
      expect(EWalletVerificationService.isValidPhilippineNumber('08171234567'), isFalse); // Wrong prefix
      expect(EWalletVerificationService.isValidPhilippineNumber('0917123456'), isFalse);  // Too short
      expect(EWalletVerificationService.isValidPhilippineNumber('091712345678'), isFalse); // Too long
      expect(EWalletVerificationService.isValidPhilippineNumber('abcdefghijk'), isFalse);
    });

    test('normalizeToE164 converts PH numbers to +639XXXXXXXXX standard', () {
      expect(EWalletVerificationService.normalizeToE164('09171234567'), '+639171234567');
      expect(EWalletVerificationService.normalizeToE164('9171234567'), '+639171234567');
      expect(EWalletVerificationService.normalizeToE164('+639171234567'), '+639171234567');
      expect(EWalletVerificationService.normalizeToE164('639171234567'), '+639171234567');
      expect(EWalletVerificationService.normalizeToE164('0918 555 1234'), '+639185551234');
    });

    test('formatForDisplay renders standard Philippine phone spacing', () {
      expect(EWalletVerificationService.formatForDisplay('09171234567'), '0917 123 4567');
      expect(EWalletVerificationService.formatForDisplay('+639171234567'), '0917 123 4567');
      expect(EWalletVerificationService.formatForDisplay('9185551234'), '0918 555 1234');
    });

    test('extractSignificant10Digits returns invariant 9XXXXXXXXX suffix', () {
      expect(EWalletVerificationService.extractSignificant10Digits('09171234567'), '9171234567');
      expect(EWalletVerificationService.extractSignificant10Digits('+639171234567'), '9171234567');
      expect(EWalletVerificationService.extractSignificant10Digits('0917 123 4567'), '9171234567');
    });

    test('decodeQrPayload extracts embedded numbers from various GCash QR URI schemes', () {
      // GCash URL scheme with query params
      expect(
        service.decodeQrPayload('https://qrph.gcash.com/p2p?phone=09171234567&amount=100'),
        '9171234567',
      );
      expect(
        service.decodeQrPayload('https://m.gcash.com/transfer?account=09185559876'),
        '9185559876',
      );

      // Embedded URL path with number
      expect(
        service.decodeQrPayload('https://gcash.com/qr/09198887766'),
        '9198887766',
      );

      // Plain numeric QR
      expect(
        service.decodeQrPayload('09171234567'),
        '9171234567',
      );

      // Empty or invalid payload
      expect(service.decodeQrPayload(''), isNull);
      expect(service.decodeQrPayload('https://randomwebsite.com/invalid'), isNull);
    });

    test('validateQrMatchesVerifiedNumber accurately matches verified numbers', () {
      const verifiedPhone = '0917 123 4567';
      const matchingQr = 'https://qrph.gcash.com/pay?phone=+639171234567';
      const differentQr = 'https://qrph.gcash.com/pay?phone=09189998888';

      expect(
        service.validateQrMatchesVerifiedNumber(
          rawQrData: matchingQr,
          verifiedNumber: verifiedPhone,
        ),
        isTrue,
      );

      expect(
        service.validateQrMatchesVerifiedNumber(
          rawQrData: differentQr,
          verifiedNumber: verifiedPhone,
        ),
        isFalse,
      );
    });

    test('verifyOtp handles mock verification session in test environment', () async {
      final success = await service.verifyOtp(
        verificationId: 'mock_verification_id_12345',
        smsCode: '123456',
      );
      expect(success, isTrue);

      final invalidCode = await service.verifyOtp(
        verificationId: 'mock_verification_id_12345',
        smsCode: '000000',
      );
      expect(invalidCode, isFalse);

      final shortCode = await service.verifyOtp(
        verificationId: 'mock_verification_id_12345',
        smsCode: '12',
      );
      expect(shortCode, isFalse);
    });
  });
}
