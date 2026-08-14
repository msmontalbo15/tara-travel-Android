import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _currencyFormatter = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimalFormatter = NumberFormat('#,##0.00', 'en_US');

  /// Formats a numeric amount with commas (e.g. 10000 -> 10,000)
  static String formatAmount(num amount, {bool showDecimals = false}) {
    if (showDecimals) {
      return _decimalFormatter.format(amount);
    }
    return _currencyFormatter.format(amount);
  }

  /// Formats a numeric amount with currency symbol and commas (e.g. 10000 -> ₱10,000)
  static String formatCurrency(num amount, {String symbol = '₱', bool showDecimals = false}) {
    return '$symbol${formatAmount(amount, showDecimals: showDecimals)}';
  }
}
