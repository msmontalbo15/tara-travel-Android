import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/expense_model.dart';
import '../../core/providers/realtime_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/selected_trip_provider.dart';
import 'widgets/budget_overview_card.dart';
import 'widgets/expense_log.dart';
import 'widgets/alert_banner.dart';
import 'widgets/member_contribution_card.dart';
import 'widgets/add_expense_form.dart';
import 'widgets/split_bill_panel.dart';
import 'widgets/category_budget_chart.dart';
import '../../core/constants/trip_types.dart';
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
  int _activeTabIndex = 0; // 0: Overview, 1: Expenses, 2: Split

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(activeTripProvider);

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return const Scaffold(body: Center(child: Text('Trip not found')));
        }

        // Subscribe to live realtime expenses updates
        ref.watch(expenseRealtimeProvider(trip.id));

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
                      if (Navigator.canPop(context)) ...[
                        const Row(
                          children: [
                            AppBackButton(),
                            SizedBox(width: 14),
                            Text('Budget', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      BudgetOverviewCard(
                        totalBudget: trip.totalBudget,
                        totalSpent: trip.totalSpent,
                        memberCount: trip.members.length,
                        tripSubtitle: '${trip.destination} · ${AppTripTypes.getEmoji(trip.tripType)} ${AppTripTypes.getLabel(trip.tripType)}',
                      ),
                      if (trip.totalBudget > 0 && (trip.totalSpent / trip.totalBudget) >= 0.9)
                        AlertBanner(
                          message:
                              '⚠️ Budget is ${(trip.totalSpent / trip.totalBudget * 100).toStringAsFixed(0)}% used.',
                        ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Tabs
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                ),
              ),
              
              // Body Section
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  physics: const BouncingScrollPhysics(),
                  child: _buildActiveTab(trip),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const BudgetScreenSkeleton(),
      error: (e, _) => Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: Text('Error: $e'))),
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
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.deepEarth : Colors.white.withValues(alpha: 0.5),
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
      categoryTotals.update(e.category.name, (v) => v + e.amount, ifAbsent: () => e.amount);
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

  Widget _buildExpensesTab(TripModel trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('All Expenses'),
            TextButton(
              onPressed: () {}, 
              child: const Text('Filter', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold))
            ),
          ],
        ),
        ExpenseLog(expenses: trip.expenses, members: trip.members),
        const SizedBox(height: 24),
        _sectionTitle('Log New Expense'),
        AddExpenseForm(
          members: trip.members,
          onExpenseAdded: (expense) async {
            // Capture messenger before async gap to avoid BuildContext-across-await lint
            final messenger = ScaffoldMessenger.of(context);
            try {
              await ref
                  .read(expenseRepositoryProvider)
                  .addExpense(trip.id, expense);
              // Invalidate all trip providers so totals refresh across every
              // provider path (selected trip, list fallback, active trip).
              ref.invalidate(selectedTripProvider);
              ref.invalidate(allTripsProvider);
              ref.invalidate(activeTripProvider);
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Failed to save expense: $e'),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
            }
          },
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

  Widget _buildDistributionCard(Map<String, double> categoryTotals, double totalSpent) {
    if (totalSpent <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: const Center(
          child: Text(
            'No approved spending yet.',
            style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.warmMuted),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
                      Text(_categoryEmoji(entry.key), style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _categoryLabel(entry.key),
                          style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deepEarth),
                        ),
                      ),
                      Text(
                        '₱${CurrencyUtils.formatAmount(entry.value)}',
                        style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepEarth),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(pct * 100).round()}%',
                        style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.warmMuted),
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
                          Container(height: 5, decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(4))),
                          Container(height: 5, width: constraints.maxWidth * v, decoration: BoxDecoration(color: _categoryColor(entry.key), borderRadius: BorderRadius.circular(4))),
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
      case 'hotel': return '🏨';
      case 'food': return '🍽️';
      case 'transport': return '🚐';
      case 'activities': return '🏝️';
      default: return '📦';
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'hotel': return 'Accommodation';
      case 'food': return 'Food';
      case 'transport': return 'Transport';
      case 'activities': return 'Activities';
      default: return 'Other';
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'hotel': return AppColors.catAccommodation;
      case 'food': return AppColors.catFood;
      case 'transport': return AppColors.catTransport;
      case 'activities': return AppColors.catActivities;
      default: return AppColors.warmMuted;
    }
  }
}
