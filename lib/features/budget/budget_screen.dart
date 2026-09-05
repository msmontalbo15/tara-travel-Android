import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_responsive.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/expense_model.dart';
import '../../core/models/personal_allowance_model.dart';
import '../../core/providers/realtime_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/providers/personal_allowance_provider.dart';
import 'widgets/trip_budget_hero_card.dart';
import 'widgets/personal_trip_budget_hero_card.dart';
import 'widgets/daily_pacing_card.dart';
import 'widgets/cash_vs_digital_card.dart';
import 'widgets/personal_expense_list.dart';
import 'widgets/expense_log.dart';
import 'widgets/alert_banner.dart';
import 'widgets/member_contribution_card.dart';
import 'widgets/add_expense_form.dart';
import 'widgets/split_bill_panel.dart';
import 'widgets/category_budget_chart.dart';
import '../../core/constants/trip_types.dart';
import '../../core/services/module_view_tracker_service.dart';
import '../../core/widgets/buttons/app_back_button.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/feedback/app_feedback.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/utils/currency_utils.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  final bool showHeader;
  const BudgetScreen({super.key, this.showHeader = true});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  // 0: Personal Budget (with trip summary), 1: Trip Expenses (group fund & CRUD)
  int _scopeIndex = 0; 
  int _activeTripSubTabIndex = 0; // 0: Overview, 1: Expenses, 2: Split

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(activeTripProvider);

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return const Scaffold(body: Center(child: Text('Trip not found')));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ModuleViewTrackerService.instance.markViewed('expenses', trip.id);
        });

        // Live realtime expense updates
        ref.watch(expenseRealtimeProvider(trip.id));

        final allowanceAsync = ref.watch(personalAllowanceProvider(trip.id));
        final myGroupLiability = ref.watch(myGroupLiabilityProvider(trip.id));
        final allowance = allowanceAsync.value;
        final allTrips = ref.watch(allTripsProvider).value ?? const [];

        // Derived calculations (purely client-side from approved expenses)
        final approvedExpenses = trip.expenses.where((e) => e.status == ExpenseStatus.approved).toList();
        final derivedTripSpent = approvedExpenses.fold<double>(0.0, (acc, e) => acc + e.amount);
        final derivedTripRemaining = (trip.totalBudget - derivedTripSpent).clamp(0.0, double.infinity);
        final isTripOverBudget = trip.totalBudget > 0 && derivedTripSpent > trip.totalBudget;

        final categoryTotals = <String, double>{};
        for (final e in approvedExpenses) {
          categoryTotals.update(e.category.name, (v) => v + e.amount, ifAbsent: () => e.amount);
        }

        return Scaffold(
          backgroundColor: AppColors.surfaceLight,
          body: Column(
            children: [
              // ── Header & Hero Section ──────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20, widget.showHeader ? 52 : 12, 20, 16),
                child: Column(
                  children: [
                    if (widget.showHeader) ...[
                      Row(
                        children: [
                          if (Navigator.canPop(context)) ...[
                            const AppBackButton(),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.name.isNotEmpty ? trip.name : 'Budget & Expenses',
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontHeading,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                // Active trip switcher chip (Pure UI state)
                                InkWell(
                                  onTap: allTrips.length > 1
                                      ? () => _showTripSwitcherSheet(context, allTrips, trip.id)
                                      : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '${AppTripTypes.getEmoji(trip.tripType)} ${trip.destination}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFF0997B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (allTrips.length > 1) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 15,
                                            color: Color(0xFFF0997B),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Scope Switcher: Budget (Personal + Summary) vs Trip Expenses (Classic Group Fund) ──
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildScopeBtn(0, '👤 Budget (Personal & Summary)'),
                            _buildScopeBtn(1, '👥 Trip Expenses (Group)'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Hero Card based on active Scope ──────────────────
                    if (_scopeIndex == 0) ...[
                      // Budget is more on personal with trip summary expenses
                      PersonalTripBudgetHeroCard(
                        tripId: trip.id,
                        allowance: allowance,
                        myGroupLiability: myGroupLiability,
                        tripTotalBudget: trip.totalBudget,
                        tripTotalSpent: derivedTripSpent,
                        tripDestination: trip.destination,
                        tripName: trip.name,
                      ),
                    ] else ...[
                      // Trip Expenses: classic overview card with the exact ring chart & trip spending
                      TripBudgetHeroCard(
                        totalBudget: trip.totalBudget,
                        totalSpent: derivedTripSpent,
                        memberCount: trip.members.length,
                        tripSubtitle: '${trip.destination} · ${AppTripTypes.getEmoji(trip.tripType)} ${AppTripTypes.getLabel(trip.tripType)}',
                        tripName: trip.name,
                      ),
                      if (isTripOverBudget)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: AlertBanner(
                            message: '⚠️ Over budget by ₱${CurrencyUtils.formatAmount(derivedTripSpent - trip.totalBudget)}!',
                          ),
                        )
                      else if (trip.totalBudget > 0 && (derivedTripSpent / trip.totalBudget) >= 0.85)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: AlertBanner(
                            message: '⚠️ Budget is ${(derivedTripSpent / trip.totalBudget * 100).toStringAsFixed(0)}% used.',
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Sub-tabs for Trip Expenses (Overview, Expenses, Split)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildTripTabBtn(0, 'Overview'),
                            _buildTripTabBtn(1, 'Expenses'),
                            _buildTripTabBtn(2, 'Split'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Body Section ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  physics: const BouncingScrollPhysics(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey<String>('${_scopeIndex}_$_activeTripSubTabIndex'),
                      child: _scopeIndex == 0
                          ? _buildPersonalBudgetScope(trip, allowance, myGroupLiability, categoryTotals, derivedTripSpent)
                          : _buildTripExpensesScope(trip, categoryTotals, derivedTripSpent, derivedTripRemaining),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: Builder(
            builder: (ctx) {
              final isOnlineAsync = ref.watch(isOnlineProvider);
              final isOnline = isOnlineAsync.value ?? true;

              return FloatingActionButton.extended(
                onPressed: () {
                  if (!isOnline) {
                    AppFeedback.showInfo(
                      context,
                      'You are in offline read-only mode. Logging expenses requires an internet connection.',
                      title: 'Offline Mode ⚡',
                    );
                    return;
                  }
                  _showQuickAddExpenseSheet(trip);
                },
                backgroundColor: isOnline ? AppColors.primary : const Color(0xFF6B4226),
                foregroundColor: Colors.white,
                elevation: 4,
                icon: Icon(
                  isOnline ? Icons.add_rounded : Icons.lock_outline_rounded,
                  size: 20,
                ),
                label: Text(
                  _scopeIndex == 0 ? 'Log Pocket Expense' : 'Log Group Bill',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const BudgetScreenSkeleton(),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.deepEarth,
        body: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildScopeBtn(int index, String label) {
    final active = _scopeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _scopeIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripTabBtn(int index, String label) {
    final active = _activeTripSubTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTripSubTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.deepEarth : Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Budget Scope: More on personal with trip summary expenses ──
  Widget _buildPersonalBudgetScope(
    TripModel trip,
    PersonalAllowanceModel? allowance,
    double myGroupLiability,
    Map<String, double> categoryTotals,
    double totalTripSpent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allowance != null && allowance.totalAllowance > 0) ...[
          DailyPacingCard(
            trip: trip,
            allowance: allowance,
            myGroupLiability: myGroupLiability,
          ),
          const SizedBox(height: 16),
          CashVsDigitalCard(tripId: trip.id, allowance: allowance),
          const SizedBox(height: 20),
        ],

        // Trip Summary Expenses Breakdown (Category Breakdown)
        _sectionTitle('TRIP EXPENSES BREAKDOWN'),
        CategoryBudgetChart(
          categoryTotals: categoryTotals,
          totalBudget: trip.totalBudget,
          totalSpent: totalTripSpent,
        ),
        const SizedBox(height: 20),

        // Personal Expense List
        if (allowance != null && allowance.expenses.isNotEmpty) ...[
          _sectionTitle('PERSONAL POCKET LOG (${allowance.expenses.length})'),
          const SizedBox(height: 6),
          PersonalExpenseList(tripId: trip.id, expenses: allowance.expenses),
          const SizedBox(height: 20),
        ],

        const SizedBox(height: 120),
      ],
    );
  }

  // ── 2. Trip Expenses Scope: The trip itself (Overview, Expenses Log, Split Bill) ──
  Widget _buildTripExpensesScope(
    TripModel trip,
    Map<String, double> categoryTotals,
    double totalSpent,
    double totalRemaining,
  ) {
    switch (_activeTripSubTabIndex) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('CATEGORY BREAKDOWN'),
            CategoryBudgetChart(
              categoryTotals: categoryTotals,
              totalBudget: trip.totalBudget,
              totalSpent: totalSpent,
            ),
            const SizedBox(height: 18),
            _sectionTitle('MEMBER CONTRIBUTIONS'),
            MemberContributionCard(members: trip.members, expenses: trip.expenses),
            const SizedBox(height: 120),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('EXPENSES LOG (${trip.expenses.length})'),
                TextButton.icon(
                  onPressed: () => _showQuickAddExpenseSheet(trip),
                  icon: const Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                  label: const Text(
                    'New',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            ExpenseLog(
              expenses: trip.expenses,
              members: trip.members,
              canApprove: true,
              onStatusUpdate: (expense, status, {rejectionNote}) async {
                await _handleStatusUpdate(trip, expense, status, note: rejectionNote);
              },
              onDelete: (expense) async {
                await _handleDeleteExpense(trip, expense.id);
              },
            ),
            const SizedBox(height: 120),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('SETTLEMENT GRAPH & BALANCES'),
            SplitBillPanel(
              members: trip.members,
              expenses: trip.expenses,
            ),
            const SizedBox(height: 120),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.warmMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Future<void> _handleStatusUpdate(
    TripModel trip,
    ExpenseModel expense,
    ExpenseStatus status, {
    String? note,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(expenseRepositoryProvider).updateStatus(
            expense.id,
            status,
            note: note,
          );
      ref.invalidate(selectedTripProvider);
      ref.invalidate(allTripsProvider);
      ref.invalidate(activeTripProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == ExpenseStatus.approved
                ? 'Expense approved and added to budget!'
                : 'Expense rejected.',
          ),
          backgroundColor: status == ExpenseStatus.approved ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _handleDeleteExpense(TripModel trip, String expenseId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(expenseRepositoryProvider).deleteExpense(expenseId);
      ref.invalidate(selectedTripProvider);
      ref.invalidate(allTripsProvider);
      ref.invalidate(activeTripProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Expense deleted'),
          backgroundColor: AppColors.deepEarth,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete expense: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _handlePersonalExpense(TripModel trip, String desc, double amt,
      ExpenseCategory cat, PaymentMode mode, DateTime dt) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(personalAllowanceControllerProvider).addPersonalExpense(
            tripId: trip.id,
            description: desc,
            amount: amt,
            category: cat,
            paymentMode: mode,
            date: dt,
          );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Personal expense logged!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save personal expense: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _handleGroupExpense(TripModel trip, ExpenseModel expense) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(expenseRepositoryProvider).addExpense(trip.id, expense);
      ref.invalidate(selectedTripProvider);
      ref.invalidate(allTripsProvider);
      ref.invalidate(activeTripProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Group expense logged!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save expense: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _showQuickAddExpenseSheet(TripModel trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: ctx.keyboardHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                AddExpenseForm(
                  members: trip.members,
                  tripId: trip.id,
                  initialIsPersonal: _scopeIndex == 0,
                  onPersonalExpenseAdded: (desc, amt, cat, mode, dt) async {
                    Navigator.pop(ctx);
                    await _handlePersonalExpense(trip, desc, amt, cat, mode, dt);
                  },
                  onExpenseAdded: (expense) async {
                    Navigator.pop(ctx);
                    await _handleGroupExpense(trip, expense);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTripSwitcherSheet(
      BuildContext context, List<TripModel> trips, String currentTripId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Switch Active Trip',
              style: TextStyle(
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.deepEarth,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select which trip budget and personal allowance to manage:',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 14),
            ...trips.map((t) {
              final isSelected = t.id == currentTripId;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.sand : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  leading: Text(
                    AppTripTypes.getEmoji(t.tripType),
                    style: const TextStyle(fontSize: 22),
                  ),
                  title: Text(
                    t.destination,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.deepEarth,
                    ),
                  ),
                  subtitle: Text(
                    '${t.members.length} members · ₱${CurrencyUtils.formatAmount(t.totalBudget)} budget',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () {
                    ref.read(selectedTripIdProvider.notifier).select(t.id);
                    ref.invalidate(activeTripProvider);
                    ref.invalidate(selectedTripProvider);
                    Navigator.pop(ctx);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
