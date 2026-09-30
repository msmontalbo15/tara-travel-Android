import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/services/gcash_qr_processor.dart';

void main() {
  group('GCash QR Processor Tests', () {
    test('QrProcessingResult handles mismatch and error formatting', () {
      final mismatch = QrProcessingResult.mismatch(
        extractedNumber: '09171234567',
        verifiedNumber: '09189998888',
      );

      expect(mismatch.isSuccess, isFalse);
      expect(mismatch.isMismatch, isTrue);
      expect(mismatch.errorMessage, contains('0917 123 4567'));
      expect(mismatch.errorMessage, contains('0918 999 8888'));
    });

    test('QrProcessingResult handles failure formatting', () {
      final failure = QrProcessingResult.failure('Image is too blurry');
      expect(failure.isSuccess, isFalse);
      expect(failure.isMismatch, isFalse);
      expect(failure.errorMessage, 'Image is too blurry');
    });

    test('processAndValidate returns failure for non-existent image file', () async {
      final processor = GcashQrProcessor.instance;
      final result = await processor.processAndValidate(
        imageFile: File('non_existent_file_path_12345.png'),
        verifiedNumber: '09171234567',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('could not be found'));
    });
  });
}
