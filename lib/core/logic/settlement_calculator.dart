class SplitSettlement {
  final String fromMemberId;
  final String toMemberId;
  final double amount;
  final String status; // 'Unsettled', 'Sent', 'Confirmed'

  SplitSettlement({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    this.status = 'Unsettled',
  });
}

class SettlementCalculator {
  /// Minimal transaction algorithm
  static List<SplitSettlement> calculate(Map<String, double> netBalances) {
    List<SplitSettlement> settlements = [];
    
    // Separate into debtors and creditors
    var debtors = netBalances.entries
        .where((e) => e.value < -0.01)
        .map((e) => MapEntry(e.key, e.value.abs()))
        .toList();
    var creditors = netBalances.entries
        .where((e) => e.value > 0.01)
        .toList();

    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    int d = 0;
    int c = 0;

    while (d < debtors.length && c < creditors.length) {
      double amount = (debtors[d].value < creditors[c].value)
          ? debtors[d].value
          : creditors[c].value;

      settlements.add(SplitSettlement(
        fromMemberId: debtors[d].key,
        toMemberId: creditors[c].key,
        amount: amount,
      ));

      // Update balances
      // Note: We can't actually mutate MapEntry value directly in Dart without recreating it
      var newDebtorValue = debtors[d].value - amount;
      var newCreditorValue = creditors[c].value - amount;

      debtors[d] = MapEntry(debtors[d].key, newDebtorValue);
      creditors[c] = MapEntry(creditors[c].key, newCreditorValue);

      if (debtors[d].value < 0.01) d++;
      if (creditors[c].value < 0.01) c++;
    }

    return settlements;
  }
}
