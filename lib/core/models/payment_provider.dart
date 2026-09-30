import 'package:flutter/material.dart';

/// Supported Philippine e-wallet payment providers for group expenses and settlements.
enum PaymentProvider {
  gcash,
  maya;

  String get displayName {
    switch (this) {
      case PaymentProvider.gcash:
        return 'GCash';
      case PaymentProvider.maya:
        return 'Maya';
    }
  }

  Color get brandColor {
    switch (this) {
      case PaymentProvider.gcash:
        return const Color(0xFF007DFE); // GCash Blue
      case PaymentProvider.maya:
        return const Color(0xFF2FB86E); // Maya Green
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentProvider.gcash:
      case PaymentProvider.maya:
        return Icons.account_balance_wallet_rounded;
    }
  }

  static PaymentProvider fromString(String? value) {
    if (value == null) return PaymentProvider.gcash;
    final normalized = value.toLowerCase().trim();
    if (normalized == 'maya' || normalized == 'paymaya') {
      return PaymentProvider.maya;
    }
    return PaymentProvider.gcash;
  }
}
