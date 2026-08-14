import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatter that formats input digits with thousand-separator commas (e.g. 10000 -> 10,000)
/// while preserving the cursor position intuitively as digits are added/deleted.
class CurrencyInputFormatter extends TextInputFormatter {
  final bool allowDecimal;
  final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');

  CurrencyInputFormatter({this.allowDecimal = false});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    if (allowDecimal) {
      final parts = newValue.text.split('.');
      if (parts.length > 2) {
        return oldValue;
      }
      final integerPartRaw = parts[0].replaceAll(RegExp(r'[^\d]'), '');
      if (integerPartRaw.isEmpty) {
        if (newValue.text.startsWith('.')) {
          return const TextEditingValue(
            text: '0.',
            selection: TextSelection.collapsed(offset: 2),
          );
        }
        return newValue.copyWith(text: '');
      }
      final formattedInt = _formatter.format(int.parse(integerPartRaw));
      final decimalPart = parts.length > 1 ? parts[1].replaceAll(RegExp(r'[^\d]'), '') : null;
      final newText = decimalPart != null
          ? '$formattedInt.${decimalPart.substring(0, decimalPart.length > 2 ? 2 : decimalPart.length)}'
          : (parts.length > 1 ? '$formattedInt.' : formattedInt);

      final selectionIndex = _calculateSelectionIndex(oldValue, newValue, newText);
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selectionIndex),
      );
    } else {
      final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.isEmpty) {
        return newValue.copyWith(text: '');
      }
      final formatted = _formatter.format(int.parse(digitsOnly));
      final selectionIndex = _calculateSelectionIndex(oldValue, newValue, formatted);

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: selectionIndex),
      );
    }
  }

  int _calculateSelectionIndex(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    String newText,
  ) {
    int digitsBeforeCursor = 0;
    for (int i = 0; i < newValue.selection.end && i < newValue.text.length; i++) {
      if (RegExp(r'[\d.]').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    int newSelectionIndex = 0;
    int count = 0;
    while (newSelectionIndex < newText.length && count < digitsBeforeCursor) {
      if (RegExp(r'[\d.]').hasMatch(newText[newSelectionIndex])) {
        count++;
      }
      newSelectionIndex++;
    }

    return newSelectionIndex.clamp(0, newText.length);
  }
}
