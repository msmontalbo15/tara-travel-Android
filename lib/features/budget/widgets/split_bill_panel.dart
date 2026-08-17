import 'dart:math';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/member_model.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/utils/currency_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Data Structures
// ─────────────────────────────────────────────────────────────────────────────

enum SplitMode { equal, fixed, percentage, treat }

class _Settlement {
  final MemberModel from;
  final MemberModel to;
  final double amount;
  _Settlement({required this.from, required this.to, required this.amount});
}

// ─────────────────────────────────────────────────────────────────────────────
//  Main Widget
// ─────────────────────────────────────────────────────────────────────────────

class SplitBillPanel extends StatefulWidget {
  final List<MemberModel> members;
  final List<ExpenseModel> expenses;

  const SplitBillPanel({
    super.key,
    required this.members,
    required this.expenses,
  });

  @override
  State<SplitBillPanel> createState() => _SplitBillPanelState();
}

class _SplitBillPanelState extends State<SplitBillPanel>
    with SingleTickerProviderStateMixin {
  SplitMode _mode = SplitMode.equal;
  late TabController _modeController;

  // Fixed mode: peso amount per member
  final Map<String, TextEditingController> _fixedControllers = {};

  // Percentage mode: % per member (0-100)
  final Map<String, double> _percentages = {};

  // Treat mode: selected host member id
  String? _treatHostId;

  // Mark-as-paid settlement ids
  final Set<String> _settledPairs = {};

  @override
  void initState() {
    super.initState();
    _modeController = TabController(length: 4, vsync: this);
    _initModeData();
  }

  void _initModeData() {
    final members = widget.members;
    if (members.isEmpty) return;

    // Fixed — default to equal share
    final approved = _approvedExpenses;
    final total = _totalApproved(approved);
    final equalShare = members.isEmpty ? 0.0 : total / members.length;

    for (final m in members) {
      _fixedControllers[m.id] ??= TextEditingController(
        text: equalShare > 0 ? equalShare.toStringAsFixed(2) : '',
      );
      _percentages[m.id] ??= members.isEmpty ? 0 : 100 / members.length;
    }

    _treatHostId ??= members.first.id;
  }

  @override
  void didUpdateWidget(SplitBillPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenses != widget.expenses ||
        oldWidget.members != widget.members) {
      _initModeData();
    }
  }

  @override
  void dispose() {
    _modeController.dispose();
    for (final c in _fixedControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<ExpenseModel> get _approvedExpenses =>
      widget.expenses.where((e) => e.status == ExpenseStatus.approved).toList();

  double _totalApproved(List<ExpenseModel> expenses) =>
      expenses.fold(0, (s, e) => s + e.amount);

  double _paidBy(String memberId, List<ExpenseModel> approved) =>
      approved.where((e) => e.paidById == memberId).fold(0, (s, e) => s + e.amount);

  /// Returns fair-share map based on active mode.
  Map<String, double> _computeShares(double total) {
    final members = widget.members;
    if (members.isEmpty) return {};
    final result = <String, double>{};

    switch (_mode) {
      case SplitMode.equal:
        final share = total / members.length;
        for (final m in members) { result[m.id] = share; }

      case SplitMode.fixed:
        for (final m in members) {
          result[m.id] =
              double.tryParse(_fixedControllers[m.id]?.text.replaceAll(',', '') ?? '0') ?? 0;
        }

      case SplitMode.percentage:
        final sumPct = _percentages.values.fold(0.0, (a, b) => a + b);
        for (final m in members) {
          result[m.id] = sumPct == 0 ? 0 : ((_percentages[m.id] ?? 0) / sumPct) * total;
        }

      case SplitMode.treat:
        // Host covers everyone — others owe host their equal share
        final share = total / max(members.length, 1);
        for (final m in members) {
          result[m.id] = m.id == _treatHostId ? total : share;
        }
    }
    return result;
  }

  /// Debt-minimization algorithm (min-cash-flow greedy).
  List<_Settlement> _computeSettlements(
    Map<String, double> paid,
    Map<String, double> shares,
  ) {
    final members = widget.members;
    // Balance = paid − owed
    final balance = <String, double>{};
    for (final m in members) {
      balance[m.id] = (paid[m.id] ?? 0) - (shares[m.id] ?? 0);
    }

    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];
    balance.forEach((id, b) {
      if (b > 0.005) creditors.add(MapEntry(id, b));
      if (b < -0.005) debtors.add(MapEntry(id, -b)); // store as positive
    });

    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    final memberById = {for (final m in members) m.id: m};
    final results = <_Settlement>[];

    int ci = 0, di = 0;
    final cBalances = creditors.map((e) => e.value).toList();
    final dBalances = debtors.map((e) => e.value).toList();

    while (ci < creditors.length && di < debtors.length) {
      final settle = min(cBalances[ci], dBalances[di]);
      if (settle > 0.005) {
        results.add(_Settlement(
          from: memberById[debtors[di].key]!,
          to: memberById[creditors[ci].key]!,
          amount: settle,
        ));
      }
      cBalances[ci] -= settle;
      dBalances[di] -= settle;
      if (cBalances[ci] < 0.005) ci++;
      if (dBalances[di] < 0.005) di++;
    }
    return results;
  }

  String _settlementKey(_Settlement s) => '${s.from.id}→${s.to.id}';

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final approved = _approvedExpenses;
    final total = _totalApproved(approved);
    final members = widget.members;

    if (members.isEmpty) return _buildEmptyState('No members in this trip yet.');
    if (total == 0) return _buildEmptyState('No approved expenses to split yet.');

    final paid = {for (final m in members) m.id: _paidBy(m.id, approved)};
    final shares = _computeShares(total);
    final settlements = _computeSettlements(paid, shares);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Selector
        _buildModeSelector(),
        const SizedBox(height: 20),

        // Mode-specific inputs (Fixed / Percentage / Treat)
        if (_mode == SplitMode.fixed) ...[
          _buildFixedInputs(total),
          const SizedBox(height: 20),
        ],
        if (_mode == SplitMode.percentage) ...[
          _buildPercentageSliders(total),
          const SizedBox(height: 20),
        ],
        if (_mode == SplitMode.treat) ...[
          _buildTreatSelector(),
          const SizedBox(height: 20),
        ],

        // Balance Cards
        _buildSectionHeader('Balance Summary', '₱${CurrencyUtils.formatAmount(total)} total'),
        const SizedBox(height: 10),
        ...members.map((m) => _buildBalanceCard(m, paid[m.id] ?? 0, shares[m.id] ?? 0, total)),
        const SizedBox(height: 24),

        // Settlement Plan
        _buildSettlementSection(settlements),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Mode Selector ─────────────────────────────────────────────────────────

  Widget _buildModeSelector() {
    const modes = [
      (SplitMode.equal,      '⚖️', 'Equal'),
      (SplitMode.fixed,      '🎯', 'Fixed'),
      (SplitMode.percentage, '📊', 'Percent'),
      (SplitMode.treat,      '🎁', 'Treat'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Row(
        children: modes.map((t) {
          final active = _mode == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mode = t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: active
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3))]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.$2, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 3),
                    Text(
                      t.$3,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.warmMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Fixed Mode Inputs ─────────────────────────────────────────────────────

  Widget _buildFixedInputs(double total) {
    final fixedSum = widget.members.fold<double>(0, (s, m) {
      return s + (double.tryParse(_fixedControllers[m.id]?.text.replaceAll(',', '') ?? '0') ?? 0);
    });
    final diff = fixedSum - total;
    final isBalanced = diff.abs() < 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Fixed Amounts', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isBalanced ? AppColors.greenLight : AppColors.redLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isBalanced ? '✓ Balanced' : (diff > 0 ? '+₱${CurrencyUtils.formatAmount(diff)} over' : '−₱${CurrencyUtils.formatAmount(-diff)} short'),
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isBalanced ? AppColors.greenBright : AppColors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...widget.members.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                _memberAvatar(m, size: 32),
                const SizedBox(width: 10),
                Expanded(child: Text(m.name, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepEarth))),
                SizedBox(
                  width: 110,
                  height: 38,
                  child: TextField(
                    controller: _fixedControllers[m.id],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepEarth),
                    decoration: InputDecoration(
                      prefixText: '₱ ',
                      prefixStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.warmMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── Percentage Sliders ────────────────────────────────────────────────────

  Widget _buildPercentageSliders(double total) {
    final sumPct = _percentages.values.fold(0.0, (a, b) => a + b);
    final isBalanced = (sumPct - 100).abs() < 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Percentage Split', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isBalanced ? AppColors.greenLight : AppColors.amberLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${sumPct.round()}%',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isBalanced ? AppColors.greenBright : AppColors.amberText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...widget.members.map((m) {
            final pct = _percentages[m.id] ?? 0;
            final share = (pct / 100) * total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _memberAvatar(m, size: 28),
                      const SizedBox(width: 8),
                      Expanded(child: Text(m.name, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepEarth))),
                      Text('${pct.round()}%', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w700, color: m.color)),
                      const SizedBox(width: 6),
                      Text('₱${CurrencyUtils.formatAmount(share)}', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.warmMuted)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      activeTrackColor: m.color,
                      inactiveTrackColor: const Color(0xFFE5E5EA),
                      thumbColor: m.color,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      overlayColor: m.color.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: pct,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      onChanged: (v) => setState(() => _percentages[m.id] = v),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Treat Host Selector ───────────────────────────────────────────────────

  Widget _buildTreatSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Who\'s treating?', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
          const SizedBox(height: 4),
          const Text('This person covers the group — others owe their equal share.', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.warmMuted)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.members.map((m) {
              final active = _treatHostId == m.id;
              return GestureDetector(
                onTap: () => setState(() => _treatHostId = m.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? m.color : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: active ? m.color : const Color(0xFFE5E5EA), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _memberAvatar(m, size: 24),
                      const SizedBox(width: 6),
                      Text(m.name.split(' ').first, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.deepEarth)),
                      if (active) ...[
                        const SizedBox(width: 4),
                        const Text('🎁', style: TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Balance Cards ─────────────────────────────────────────────────────────

  Widget _buildBalanceCard(MemberModel member, double paid, double share, double total) {
    final net = paid - share;
    final isSettled = net.abs() < 0.5;
    final isCreditor = net > 0.5;

    Color netColor;
    Color netBg;
    String netLabel;
    String netIcon;

    if (isSettled) {
      netColor = AppColors.warmMuted;
      netBg = const Color(0xFFF0F0F0);
      netLabel = 'Settled';
      netIcon = '✓';
    } else if (isCreditor) {
      netColor = AppColors.greenBright;
      netBg = AppColors.greenLight;
      netLabel = 'Gets back ₱${CurrencyUtils.formatAmount(net)}';
      netIcon = '↑';
    } else {
      netColor = AppColors.red;
      netBg = AppColors.redLight;
      netLabel = 'Owes ₱${CurrencyUtils.formatAmount(-net)}';
      netIcon = '↓';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _memberAvatar(member, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
                    Text(
                      member.roles.isNotEmpty ? member.roles.map((r) => r.displayName).join(' · ') : 'Member',
                      style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, color: AppColors.warmMuted),
                    ),
                  ],
                ),
              ),
              // Net chip
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: netBg, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(netIcon, style: TextStyle(fontSize: 11, color: netColor, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 3),
                    Text(netLabel, style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, color: netColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Paid', style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, color: AppColors.warmMuted, fontWeight: FontWeight.w600)),
                        Expanded(
                          child: Text(
                            '₱${CurrencyUtils.formatAmount(paid)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, color: member.color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _animatedBar(total == 0 ? 0 : (paid / total).clamp(0, 1), member.color),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fair Share', style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, color: AppColors.warmMuted, fontWeight: FontWeight.w600)),
                        Expanded(
                          child: Text(
                            '₱${CurrencyUtils.formatAmount(share)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.deepEarth),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _animatedBar(total == 0 ? 0 : (share / total).clamp(0, 1), const Color(0xFFD0CFC8)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _animatedBar(double fraction, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) => LayoutBuilder(
        builder: (_, constraints) => Stack(
          children: [
            Container(height: 5, decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(4))),
            Container(
              height: 5,
              width: constraints.maxWidth * value,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Settlement Section ────────────────────────────────────────────────────

  Widget _buildSettlementSection(List<_Settlement> settlements) {
    final pendingCount = settlements.where((s) => !_settledPairs.contains(_settlementKey(s))).length;
    final totalOwed = settlements.fold<double>(0, (s, e) => s + e.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'SETTLEMENT PLAN',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warmMuted, letterSpacing: 1.5),
            ),
            const Spacer(),
            Text(
              settlements.isEmpty ? 'All settled!' : '₱${CurrencyUtils.formatAmount(totalOwed)} · $pendingCount pending',
              style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            if (settlements.isNotEmpty) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final lines = StringBuffer();
                  lines.writeln('💸 SETTLEMENT PLAN');
                  lines.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
                  for (final s in settlements) {
                    lines.writeln('  • ${s.from.name} pays ${s.to.name}  →  ${_currency(s.amount)}');
                  }
                  lines.writeln();
                  lines.writeln('Total: ₱${CurrencyUtils.formatAmount(totalOwed)}');
                  lines.writeln();
                  lines.writeln('📱 Shared via Tara Travel');
                  SharePlus.instance.share(
                    ShareParams(
                      text: lines.toString(),
                      subject: 'Trip Settlement Plan',
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share_rounded, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Share', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (settlements.isEmpty)
          _buildAllSettledCard()
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Column(
              children: [
                // Header banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2C1A14), Color(0xFF3D2118)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      const Text('💸', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Minimum Transactions', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text('${settlements.length} transfer${settlements.length == 1 ? '' : 's'} to settle everything', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: Colors.white54)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          '₱${CurrencyUtils.formatAmount(totalOwed)}',
                          style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                // Rows
                ...settlements.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  final isLast = i == settlements.length - 1;
                  return _buildSettlementRow(s, isLast);
                }),
              ],
            ),
          ),
      ],
    );
  }

  String _currency(double v) => '₱${CurrencyUtils.formatAmount(v)}';

  Widget _buildSettlementRow(_Settlement s, bool isLast) {
    final key = _settlementKey(s);
    final isSettled = _settledPairs.contains(key);
    final hasGcash = s.to.gcashNumber != null && s.to.gcashNumber!.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isSettled ? AppColors.greenLight.withValues(alpha: 0.4) : Colors.white,
        borderRadius: isLast
            ? const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18))
            : BorderRadius.zero,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // From
                Column(
                  children: [
                    _memberAvatar(s.from, size: 34),
                    const SizedBox(height: 3),
                    Text(s.from.name.split(' ').first, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.deepEarth)),
                  ],
                ),
                const SizedBox(width: 10),
                // Arrow + amount
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSettled ? AppColors.greenLight : AppColors.chipBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '₱${CurrencyUtils.formatAmount(s.amount)}',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSettled ? AppColors.greenBright : AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: Container(height: 1.5, color: isSettled ? AppColors.greenBright : const Color(0xFFE5E5EA))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              isSettled ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                              size: 16,
                              color: isSettled ? AppColors.greenBright : AppColors.primary,
                            ),
                          ),
                          Expanded(child: Container(height: 1.5, color: isSettled ? AppColors.greenBright : const Color(0xFFE5E5EA))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // To
                Column(
                  children: [
                    _memberAvatar(s.to, size: 34),
                    const SizedBox(height: 3),
                    Text(s.to.name.split(' ').first, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.deepEarth)),
                  ],
                ),
                const SizedBox(width: 14),
                // Action column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasGcash && !isSettled)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF007AE5), borderRadius: BorderRadius.circular(7)),
                        child: const Text('💙 GCash', style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    GestureDetector(
                      onTap: () => setState(() {
                        if (isSettled) { _settledPairs.remove(key); } else { _settledPairs.add(key); }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSettled ? AppColors.greenBright : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: isSettled ? AppColors.greenBright : const Color(0xFFE5E5EA),
                          ),
                        ),
                        child: Text(
                          isSettled ? '✓ Paid' : 'Mark Paid',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSettled ? Colors.white : AppColors.warmMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isLast)
            const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 14, endIndent: 14),
        ],
      ),
    );
  }

  Widget _buildAllSettledCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFD1FAE5), Color(0xFFECFDF5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.greenBright.withValues(alpha: 0.3)),
      ),
      child: const Column(
        children: [
          Text('🎉', style: TextStyle(fontSize: 36)),
          SizedBox(height: 8),
          Text('All Settled!', style: TextStyle(fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.green)),
          SizedBox(height: 4),
          Text('Everyone\'s contributions are balanced.', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.greenBright), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Shared Helpers ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warmMuted, letterSpacing: 1.5),
        ),
        const Spacer(),
        Text(
          subtitle,
          style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Text('🧾', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: AppColors.warmMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberAvatar(MemberModel m, {double size = 36}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: m.color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: m.color.withValues(alpha: 0.30), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Center(
        child: Text(
          m.initials,
          style: TextStyle(fontSize: size * 0.33, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }
}
