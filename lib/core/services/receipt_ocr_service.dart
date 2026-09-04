import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight receipt parsing and OCR utility for Tara Travel.
///
/// Features:
/// 1. Receipt image upload to Supabase Storage (`avatars` bucket fallback or storage).
/// 2. Heuristic extraction of Peso amounts and itemized dates from filename or receipt text.
class ReceiptOcrService {
  ReceiptOcrService._();
  static final ReceiptOcrService instance = ReceiptOcrService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Uploads a receipt image to Supabase Storage and returns its public URL.
  Future<String?> uploadReceiptImage({
    required String tripId,
    required String localFilePath,
  }) async {
    try {
      final file = File(localFilePath);
      if (!file.existsSync()) return null;

      final ext = localFilePath.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'receipts/$tripId/receipt_$timestamp.$ext';

      await _supabase.storage.from('avatars').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('[ReceiptOcrService] uploadReceiptImage error: $e');
      // If offline or storage error, return null so local flow proceeds
      return null;
    }
  }

  /// Parses text from a scanned receipt or file metadata to extract probable total amount and description.
  ReceiptExtractionResult extractReceiptData({
    required String rawText,
    String? filePath,
  }) {
    double? detectedAmount;
    String? detectedDescription;
    DateTime? detectedDate;

    // 1. Look for currency patterns: "₱ 1,250.00", "PHP 500", "Total: 450", "Amount: 120"
    final amountRegexes = [
      RegExp(r'(?:total|amount|due|subtotal|balance|php|p|₱)\s*[:=]?\s*[₱p]?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'[₱p]\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'\b([0-9]{2,6}(?:\.[0-9]{2}))\b'),
    ];

    for (final reg in amountRegexes) {
      final match = reg.firstMatch(rawText);
      if (match != null && match.groupCount >= 1) {
        final cleanStr = match.group(1)?.replaceAll(',', '');
        final val = double.tryParse(cleanStr ?? '');
        if (val != null && val > 0) {
          detectedAmount = val;
          break;
        }
      }
    }

    // 2. If nothing found in rawText, inspect filename if available (e.g., "Jollibee_500.jpg")
    if (detectedAmount == null && filePath != null) {
      final nameOnly = filePath.split(Platform.pathSeparator).last;
      final numMatch = RegExp(r'(\d+(?:\.\d{1,2})?)').firstMatch(nameOnly);
      if (numMatch != null) {
        detectedAmount = double.tryParse(numMatch.group(1) ?? '');
      }
      // Infer description from filename without extension
      final cleanName = nameOnly.replaceAll(RegExp(r'\.[^.]+$'), '').replaceAll(RegExp(r'[_-\d]'), ' ').trim();
      if (cleanName.length >= 3) {
        detectedDescription = cleanName;
      }
    }

    // 3. Look for merchant/category hints
    if (detectedDescription == null) {
      final lower = rawText.toLowerCase();
      if (lower.contains('jollibee') || lower.contains('mcdo') || lower.contains('restaurant') || lower.contains('cafe') || lower.contains('coffee') || lower.contains('food')) {
        detectedDescription = 'Dining & Refreshments';
      } else if (lower.contains('hotel') || lower.contains('resort') || lower.contains('inn') || lower.contains('room')) {
        detectedDescription = 'Accommodation Booking';
      } else if (lower.contains('grab') || lower.contains('taxi') || lower.contains('ferry') || lower.contains('bus') || lower.contains('gas')) {
        detectedDescription = 'Transportation Fare';
      } else if (lower.contains('island') || lower.contains('tour') || lower.contains('entrance') || lower.contains('ticket')) {
        detectedDescription = 'Tour / Activity Fee';
      }
    }

    return ReceiptExtractionResult(
      amount: detectedAmount,
      description: detectedDescription,
      date: detectedDate ?? DateTime.now(),
    );
  }
}

class ReceiptExtractionResult {
  final double? amount;
  final String? description;
  final DateTime date;

  ReceiptExtractionResult({
    this.amount,
    this.description,
    required this.date,
  });
}
