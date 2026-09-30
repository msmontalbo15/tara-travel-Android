import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_colors.dart';
import 'ewallet_verification_service.dart';
import 'gcash_verification_service.dart';

/// Result of analyzing and cross-validating an uploaded e-wallet QR code.
class QrProcessingResult {
  final bool isSuccess;
  final bool isMismatch;
  final String? errorMessage;
  final String? rawPayload;
  final String? extractedNumber;
  final File? processedImageFile;

  const QrProcessingResult._({
    required this.isSuccess,
    this.isMismatch = false,
    this.errorMessage,
    this.rawPayload,
    this.extractedNumber,
    this.processedImageFile,
  });

  factory QrProcessingResult.success({
    required String rawPayload,
    required String extractedNumber,
    required File processedImageFile,
  }) {
    return QrProcessingResult._(
      isSuccess: true,
      rawPayload: rawPayload,
      extractedNumber: extractedNumber,
      processedImageFile: processedImageFile,
    );
  }

  factory QrProcessingResult.mismatch({
    required String extractedNumber,
    required String verifiedNumber,
  }) {
    final formattedExtracted = EWalletVerificationService.formatForDisplay(extractedNumber);
    final formattedVerified = EWalletVerificationService.formatForDisplay(verifiedNumber);
    return QrProcessingResult._(
      isSuccess: false,
      isMismatch: true,
      extractedNumber: extractedNumber,
      errorMessage:
          'This QR code belongs to a different number ($formattedExtracted). Please upload the QR for your verified number ($formattedVerified).',
    );
  }

  factory QrProcessingResult.failure(String message) {
    return QrProcessingResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

/// Service that auto-decodes uploaded QR screenshots, verifies that the QR matches
/// the user's OTP-verified phone number, and regenerates a clean branded QR code.
class GcashQrProcessor {
  GcashQrProcessor({
    EWalletVerificationService? verificationService,
    MobileScannerController? scannerController,
  })  : _verificationService = verificationService ?? GcashVerificationService.instance,
        _scannerController = scannerController;

  static final GcashQrProcessor instance = GcashQrProcessor();

  final EWalletVerificationService _verificationService;
  final MobileScannerController? _scannerController;

  /// Decodes, cross-validates, and regenerates a pristine branded QR from [imageFile].
  Future<QrProcessingResult> processAndValidate({
    required File imageFile,
    required String verifiedNumber,
  }) async {
    if (!imageFile.existsSync()) {
      return QrProcessingResult.failure('Image file could not be found.');
    }

    try {
      final controller = _scannerController ??
          MobileScannerController(
            detectionSpeed: DetectionSpeed.noDuplicates,
            facing: CameraFacing.back,
          );

      // 1. Decode QR payload using mobile_scanner image analyzer
      final BarcodeCapture? capture = await controller.analyzeImage(imageFile.path);

      if (capture == null || capture.barcodes.isEmpty) {
        return QrProcessingResult.failure(
          'Could not detect a clear QR code in this image. Please upload a clear, uncropped screenshot of your payment QR.',
        );
      }

      final barcode = capture.barcodes.first;
      final rawValue = barcode.rawValue;

      if (rawValue == null || rawValue.trim().isEmpty) {
        return QrProcessingResult.failure(
          'QR code could not be decoded. Please ensure the QR code is legible.',
        );
      }

      // 2. Cross-validate payload against the verified phone number
      final extracted = _verificationService.decodeQrPayload(rawValue);
      if (extracted == null) {
        return QrProcessingResult.failure(
          'Unable to extract account credentials from this QR code. Please make sure this is an official GCash/QR Ph code.',
        );
      }

      final matches = _verificationService.validateQrMatchesVerifiedNumber(
        rawQrData: rawValue,
        verifiedNumber: verifiedNumber,
      );

      if (!matches) {
        return QrProcessingResult.mismatch(
          extractedNumber: extracted,
          verifiedNumber: verifiedNumber,
        );
      }

      // 3. Regenerate pristine, branded QR image artifact (300x300 canvas)
      final cleanFile = await regenerateBrandedQrFile(
        rawPayload: rawValue,
        filenamePrefix: 'verified_qr_${DateTime.now().millisecondsSinceEpoch}',
      );

      return QrProcessingResult.success(
        rawPayload: rawValue,
        extractedNumber: extracted,
        processedImageFile: cleanFile ?? imageFile,
      );
    } catch (e) {
      debugPrint('[GcashQrProcessor] Error processing QR: $e');
      return QrProcessingResult.failure('Error processing QR image: $e');
    }
  }

  /// Regenerates a clean branded QR code PNG file from [rawPayload].
  Future<File?> regenerateBrandedQrFile({
    required String rawPayload,
    required String filenamePrefix,
  }) async {
    try {
      const size = 320.0;
      final painter = QrPainter(
        data: rawPayload,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        gapless: true,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppColors.deepEarth,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: AppColors.primary,
        ),
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // White background card with slight padding
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, size, size),
          const Radius.circular(16),
        ),
        bgPaint,
      );

      // Paint QR with 20px quiet margin
      canvas.save();
      canvas.translate(20, 20);
      painter.paint(canvas, const Size(size - 40, size - 40));
      canvas.restore();

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final targetFile = File('${tempDir.path}/$filenamePrefix.png');
      await targetFile.writeAsBytes(byteData.buffer.asUint8List());

      return targetFile;
    } catch (e) {
      debugPrint('[GcashQrProcessor] Error regenerating QR: $e');
      return null;
    }
  }
}
