import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_responsive.dart';
import '../../models/trip_model.dart';
import '../../models/expense_model.dart';
import '../../providers/itinerary_provider.dart';
import '../../providers/packing_provider.dart';
import '../../providers/expense_provider.dart';
import '../../utils/share_format_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ShareTripModal — bottom sheet for sharing trip content to Messenger/apps
// ─────────────────────────────────────────────────────────────────────────────

enum ShareScope {
  overview,
  itinerary,
  currentDay,
  packing,
  budget,
}

extension ShareScopeX on ShareScope {
  String get label {
    switch (this) {
      case ShareScope.overview:    return 'Trip Overview';
      case ShareScope.itinerary:   return 'Full Itinerary';
      case ShareScope.currentDay:  return 'Today\'s Plan';
      case ShareScope.packing:     return 'Packing List';
      case ShareScope.budget:      return 'Budget & Split';
    }
  }

  String get emoji {
    switch (this) {
      case ShareScope.overview:    return '✈️';
      case ShareScope.itinerary:   return '🗺️';
      case ShareScope.currentDay:  return '📆';
      case ShareScope.packing:     return '🎒';
      case ShareScope.budget:      return '💸';
    }
  }
}

class ShareTripModal extends ConsumerStatefulWidget {
  final TripModel trip;
  final ShareScope initialScope;
  final int? activeDayIndex;

  const ShareTripModal({
    super.key,
    required this.trip,
    this.initialScope = ShareScope.overview,
    this.activeDayIndex,
  });

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    TripModel trip, {
    ShareScope initialScope = ShareScope.overview,
    int? activeDayIndex,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ShareTripModal(
        trip: trip,
        initialScope: initialScope,
        activeDayIndex: activeDayIndex,
      ),
    );
  }

  @override
  ConsumerState<ShareTripModal> createState() => _ShareTripModalState();
}

class _ShareTripModalState extends ConsumerState<ShareTripModal> {
  late ShareScope _scope;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _scope = widget.initialScope;
  }

  // ── Formatted text generation ─────────────────────────────────────────────

  String _buildText() {
    final trip = widget.trip;

    // Itinerary state (may be unavailable)
    final itineraryProvInst = ref.read(itineraryProvider(trip.id));
    final itineraryAsync = ref.read(itineraryProvInst);
    final itinerary = itineraryAsync.value;

    // Packing state
    final packingProvInst = ref.read(packingProvider(trip.id));
    final packingState = ref.read(packingProvInst);

    // Expense data for budget
    final expensesAsync = ref.read(expenseProvider(trip.id));
    final expenses = expensesAsync.value ?? trip.expenses;

    switch (_scope) {
      case ShareScope.overview:
        return ShareFormatHelper.formatTripOverview(
          trip: trip,
          itinerary: itinerary,
          packingState: packingState,
        );

      case ShareScope.itinerary:
        if (itinerary == null) return '(Itinerary not loaded yet)';
        return ShareFormatHelper.formatItinerary(
          trip: trip,
          itinerary: itinerary,
        );

      case ShareScope.currentDay:
        if (itinerary == null) return '(Itinerary not loaded yet)';
        return ShareFormatHelper.formatItinerary(
          trip: trip,
          itinerary: itinerary,
          dayIndex: widget.activeDayIndex ?? itinerary.activeDay,
        );

      case ShareScope.packing:
        return ShareFormatHelper.formatPackingList(
          trip: trip,
          packingState: packingState,
          members: trip.members,
        );

      case ShareScope.budget:
        // Build settlements from the split panel's logic
        final members = trip.members;
        if (members.isEmpty || expenses.isEmpty) {
          return ShareFormatHelper.formatBudgetSplit(
            trip: trip,
            expenses: expenses,
            members: members,
            shares: {},
            settlements: [],
          );
        }
        final approved = expenses.where((e) => e.status == ExpenseStatus.approved).toList();
        final total = approved.fold<double>(0, (s, e) => s + e.amount);
        final share = members.isEmpty ? 0.0 : total / members.length;
        final sharesMap = {for (final m in members) m.id: share};

        // Simple debt-minimization
        final paid = <String, double>{
          for (final m in members)
            m.id: approved.where((e) => e.paidById == m.id).fold<double>(0, (s, e) => s + e.amount),
        };
        final balances = <String, double>{
          for (final m in members)
            m.id: (paid[m.id] ?? 0) - (sharesMap[m.id] ?? 0),
        };

        final creditors = balances.entries.where((e) => e.value > 0.5).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final debtors = balances.entries.where((e) => e.value < -0.5).toList()
          ..sort((a, b) => a.value.compareTo(b.value));

        final memberById = {for (final m in members) m.id: m};
        final settlements = <BudgetSettlement>[];

        final cBalances = creditors.map((e) => e.value).toList();
        final dBalances = debtors.map((e) => -e.value).toList();
        int ci = 0, di = 0;
        while (ci < creditors.length && di < debtors.length) {
          final settle = cBalances[ci] < dBalances[di] ? cBalances[ci] : dBalances[di];
          if (settle > 0.005) {
            settlements.add(BudgetSettlement(
              fromName: memberById[debtors[di].key]?.name ?? debtors[di].key,
              toName: memberById[creditors[ci].key]?.name ?? creditors[ci].key,
              amount: settle,
            ));
          }
          cBalances[ci] -= settle;
          dBalances[di] -= settle;
          if (cBalances[ci] < 0.005) ci++;
          if (dBalances[di] < 0.005) di++;
        }

        return ShareFormatHelper.formatBudgetSplit(
          trip: trip,
          expenses: expenses,
          members: members,
          shares: sharesMap,
          settlements: settlements,
        );
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _shareViaApps(String text) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: '${widget.trip.name} — Tara Travel',
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final text = _buildText();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF2F2F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.share_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share Trip',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontHeading,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepEarth,
                            ),
                          ),
                          Text(
                            'Messenger-ready format with Google Maps links',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Scope selector
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ShareScope.values.map((scope) {
                    final active = _scope == scope;
                    return GestureDetector(
                      onTap: () => setState(() => _scope = scope),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? AppColors.primary : const Color(0xFFE5E5EA),
                          ),
                          boxShadow: active
                              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                              : null,
                        ),
                        child: Text(
                          '${scope.emoji}  ${scope.label}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : AppColors.warmMuted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              // Preview area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollCtrl,
                      physics: const BouncingScrollPhysics(),
                      child: SelectableText(
                        text,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.6,
                          color: AppColors.deepEarth,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Action row
              Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, context.safeBottomPadding(16)),
                child: Row(
                  children: [
                    // Copy
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _copyToClipboard(text),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 52,
                          decoration: BoxDecoration(
                            color: _copied ? AppColors.green : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _copied ? AppColors.green : const Color(0xFFE5E5EA),
                            ),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _copied ? Icons.check_rounded : Icons.copy_rounded,
                                size: 18,
                                color: _copied ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _copied ? 'Copied!' : 'Copy Text',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _copied ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Share to apps
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => _shareViaApps(text),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD85A30), Color(0xFFB8420B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Share to Messenger / Apps',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
