import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/expense_model.dart';
import '../../core/models/personal_allowance_model.dart';
import '../../core/providers/realtime_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/providers/personal_allowance_provider.dart';
import 'widgets/budget_overview_card.dart';
import 'widgets/personal_allowance_card.dart';
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
import '../../core/utils/currency_utils.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  final bool showHeader;
  const BudgetScreen({super.key, this.showHeader = true});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  int _scopeIndex = 0; // 0: Group Fund, 1: My Allowance
  int _activeTabIndex = 0; // 0: Overview, 1: Expenses, 2: Split

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

        // Subscribe to live realtime expenses updates
        ref.watch(expenseRealtimeProvider(trip.id));

        final allowanceAsync = ref.watch(personalAllowanceProvider(trip.id));
        final myGroupLiability = ref.watch(myGroupLiabilityProvider(trip.id));
        final allowance = allowanceAsync.value;
        final allTrips = ref.watch(allTripsProvider).value ?? const [];

        return Scaffold(
          backgroundColor: AppColors.surfaceLight,
          body: Column(
            children: [
              // Dark Header + Hero Section
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(24, widget.showHeader ? 60 : 8, 24, 0),
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
                                  trip.name.isNotEmpty
                                      ? trip.name
                                      : 'Budget & Allowance',
                                  style: const TextStyle(
                                    fontFamily: 'Playfair Display',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                // Active trip badge with switcher dropdown
                                InkWell(
                                  onTap: allTrips.length > 1
                                      ? () => _showTripSwitcherSheet(
                                          context, allTrips, trip.id)
                                      : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
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
                                              fontFamily: 'DM Sans',
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

                      // ── Scope Switcher: Group Fund vs My Allowance ───────
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
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
                            _buildScopeBtn(0, '👤 My Allowance'),
                            _buildScopeBtn(1, '👥 Group Fund'),
                          ],
                        ),
                      ),

                      if (_scopeIndex == 0) ...[
                        PersonalAllowanceCard(
                          tripId: trip.id,
                          allowance: allowance,
                          myGroupLiability: myGroupLiability,
                          tripDestination: trip.destination,
                          tripName: trip.name,
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        BudgetOverviewCard(
                          totalBudget: trip.totalBudget,
                          totalSpent: trip.totalSpent,
                          memberCount: trip.members.length,
                          tripSubtitle:
                              '${trip.destination} · ${AppTripTypes.getEmoji(trip.tripType)} ${AppTripTypes.getLabel(trip.tripType)}',
                          tripName: trip.name,
                        ),
                        if (trip.totalBudget > 0 &&
                            (trip.totalSpent / trip.totalBudget) >= 0.9)
                          AlertBanner(
                            message:
                                '⚠️ Budget is ${(trip.totalSpent / trip.totalBudget * 100).toStringAsFixed(0)}% used.',
                          ),
                        const SizedBox(height: 12),
                        // Sub-tabs for Group Fund
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
                              _buildTabBtn(0, 'Overview'),
                              _buildTabBtn(1, 'Expenses'),
                              _buildTabBtn(2, 'Split'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ],
                  ],
                ),
              ),

              // Body Section
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  physics: const BouncingScrollPhysics(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_scopeIndex),
                      child: _scopeIndex == 0
                          ? _buildMyAllowanceTab(trip, allowance, myGroupLiability)
                          : _buildActiveTab(trip),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showQuickAddExpenseSheet(trip),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              _scopeIndex == 0 ? 'Log Pocket Expense' : 'Log Group Bill',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
      loading: () => const BudgetScreenSkeleton(),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.deepEarth,
        body: Center(child: Text('Error: $e')),
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
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBtn(int index, String label) {
    final active = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTabIndex = index),
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
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active
                  ? AppColors.deepEarth
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTab(TripModel trip) {
    switch (_activeTabIndex) {
      case 0:
        return _buildOverviewTab(trip);
      case 1:
        return _buildExpensesTab(trip);
      case 2:
        return _buildSplitTab(trip);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewTab(TripModel trip) {
    final categoryTotals = <String, double>{};
    for (final e in trip.expenses) {
      if (e.status != ExpenseStatus.approved) continue;
      categoryTotals.update(e.category.name, (v) => v + e.amount,
          ifAbsent: () => e.amount);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Category Breakdown'),
        CategoryBudgetChart(
          categoryTotals: categoryTotals,
          totalBudget: trip.totalBudget,
          totalSpent: trip.totalSpent,
        ),
        const SizedBox(height: 18),
        _sectionTitle('Distribution'),
        _buildDistributionCard(categoryTotals, trip.totalSpent),
        const SizedBox(height: 18),
        _sectionTitle('Member Contributions'),
        MemberContributionCard(members: trip.members, expenses: trip.expenses),
        const SizedBox(height: 130),
      ],
    );
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
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                fontFamily: 'Playfair Display',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.deepEarth,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select which trip budget and personal allowance to manage:',
              style: TextStyle(
                fontFamily: 'DM Sans',
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
                  color: isSelected
                      ? AppColors.sand
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFFE5E7EB),
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
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.deepEarth,
                    ),
                  ),
                  subtitle: Text(
                    '${t.members.length} members · ₱${CurrencyUtils.formatAmount(t.totalBudget)} budget',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 20)
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

  Widget _buildExpensesTab(TripModel trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Expense History (${trip.expenses.length})'),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Filter',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        ExpenseLog(expenses: trip.expenses, members: trip.members),
        const SizedBox(height: 24),
        _sectionTitle('Log New Expense'),
        AddExpenseForm(
          members: trip.members,
          onPersonalExpenseAdded: (desc, amt, cat, mode, dt) =>
              _handlePersonalExpense(trip, desc, amt, cat, mode, dt),
          onExpenseAdded: (expense) => _handleGroupExpense(trip, expense),
        ),
        const SizedBox(height: 130),
      ],
    );
  }

  Widget _buildMyAllowanceTab(
    TripModel trip,
    PersonalAllowanceModel? allowance,
    double myGroupLiability,
  ) {
    if (allowance == null || allowance.totalAllowance <= 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PersonalAllowanceCard(
            tripId: trip.id,
            allowance: allowance,
            myGroupLiability: myGroupLiability,
            tripDestination: trip.destination,
            tripName: trip.name,
          ),
          const SizedBox(height: 130),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DailyPacingCard(
          trip: trip,
          allowance: allowance,
          myGroupLiability: myGroupLiability,
        ),
        const SizedBox(height: 16),
        CashVsDigitalCard(tripId: trip.id, allowance: allowance),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Personal Expenses (${allowance.expenses.length})'),
          ],
        ),
        const SizedBox(height: 8),
        PersonalExpenseList(tripId: trip.id, expenses: allowance.expenses),
        const SizedBox(height: 24),
        _sectionTitle('Log Personal Expense'),
        const SizedBox(height: 8),
        AddExpenseForm(
          members: trip.members,
          initialIsPersonal: true,
          onPersonalExpenseAdded: (desc, amt, cat, mode, dt) =>
              _handlePersonalExpense(trip, desc, amt, cat, mode, dt),
          onExpenseAdded: (expense) => _handleGroupExpense(trip, expense),
        ),
        const SizedBox(height: 130),
      ],
    );
  }

  Widget _buildSplitTab(TripModel trip) {
    return SplitBillPanel(
      members: trip.members,
      expenses: trip.expenses,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.warmMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDistributionCard(
      Map<String, double> categoryTotals, double totalSpent) {
    if (totalSpent <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            'No approved spending yet.',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.warmMuted,
            ),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...categoryTotals.entries.map((entry) {
            final pct = entry.value / totalSpent;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_categoryEmoji(entry.key),
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _categoryLabel(entry.key),
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepEarth,
                          ),
                        ),
                      ),
                      Text(
                        '₱${CurrencyUtils.formatAmount(entry.value)}',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(pct * 100).round()}%',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          color: AppColors.warmMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => LayoutBuilder(
                      builder: (_, constraints) => Stack(
                        children: [
                          Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E5EA),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            height: 5,
                            width: constraints.maxWidth * v,
                            decoration: BoxDecoration(
                              color: _categoryColor(entry.key),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
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

  String _categoryEmoji(String cat) {
    switch (cat) {
      case 'hotel':
        return '🏨';
      case 'food':
        return '🍽️';
      case 'transport':
        return '🚐';
      case 'activities':
        return '🏝️';
      default:
        return '📦';
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'hotel':
        return 'Accommodation';
      case 'food':
        return 'Food';
      case 'transport':
        return 'Transport';
      case 'activities':
        return 'Activities';
      default:
        return 'Other';
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'hotel':
        return AppColors.catAccommodation;
      case 'food':
        return AppColors.catFood;
      case 'transport':
        return AppColors.catTransport;
      case 'activities':
        return AppColors.catActivities;
      default:
        return AppColors.warmMuted;
    }
  }
}
