import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/member_model.dart';
import '../../core/models/expense_model.dart';
import '../../core/providers/realtime_provider.dart';
import '../../core/providers/trip_provider.dart';
import 'widgets/budget_overview_card.dart';
import 'widgets/expense_log.dart';
import 'widgets/alert_banner.dart';
import 'widgets/member_contribution_card.dart';
import 'widgets/add_expense_form.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  final bool showHeader;
  const BudgetScreen({super.key, this.showHeader = true});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  int _activeTabIndex = 0; // 0: Overview, 1: Expenses, 2: Split
  String _activeSplitMode = 'equal'; // equal, fixed, bigger, treat

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
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text('Budget', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      BudgetOverviewCard(
                        totalBudget: trip.totalBudget,
                        totalSpent: trip.totalSpent,
                        memberCount: trip.members.length,
                        tripSubtitle: '${trip.destination} · ${trip.tripType}',
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
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
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
      loading: () => const Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: CircularProgressIndicator())),
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
            borderRadius: BorderRadius.circular(8),
            boxShadow: active 
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 1))]
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
        _buildCategoryBreakdownCard(categoryTotals),
        const SizedBox(height: 18),
        _sectionTitle('Distribution'),
        _buildDistributionCard(categoryTotals, trip.totalSpent),
        const SizedBox(height: 18),
        _sectionTitle('Member Contributions'),
        MemberContributionCard(members: trip.members, expenses: trip.expenses),
        const SizedBox(height: 40),
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
        AddExpenseForm(members: trip.members),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSplitTab(TripModel trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Split Method'),
        _buildSplitMethodCard(trip),
        const SizedBox(height: 18),
        _sectionTitle('Settlement Plan'),
        _buildSettlementCard(trip),
        const SizedBox(height: 40),
      ],
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

  Widget _buildSplitMethodCard(TripModel trip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _splitModeBtn('⚖️', 'Equal', 'equal'),
              const SizedBox(width: 8),
              _splitModeBtn('🎯', 'Fixed', 'fixed'),
              const SizedBox(width: 8),
              _splitModeBtn('💰', 'Bigger', 'bigger'),
              const SizedBox(width: 8),
              _splitModeBtn('🎁', 'Treat', 'treat'),
            ],
          ),
          const SizedBox(height: 20),
          ...trip.members.map((m) => _buildSplitMemberRow(m, trip)),
        ],
      ),
    );
  }

  Widget _splitModeBtn(String icon, String label, String mode) {
    final active = _activeSplitMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeSplitMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.chipBackground : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? AppColors.primary : const Color(0xFFE5E5EA), width: 1.5),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.primary : AppColors.deepEarth,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitMemberRow(MemberModel member, TripModel trip) {
    final approvedExpenses = trip.expenses
        .where((e) => e.status == ExpenseStatus.approved && e.paidById == member.id)
        .fold<double>(0, (sum, e) => sum + e.amount);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: member.color, shape: BoxShape.circle),
            child: Center(child: Text(member.initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepEarth)),
                Text(
                  member.roles.isNotEmpty
                    ? _capitalizeRole(member.roles.first)
                    : 'Member',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            '₱${approvedExpenses.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepEarth),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementCard(TripModel trip) {
    final approved = trip.expenses.where((e) => e.status == ExpenseStatus.approved).toList();
    final totalApproved = approved.fold<double>(0, (s, e) => s + e.amount);
    final members = trip.members;
    final settlements = <({String from, String to, double amount})>[];
    if (members.isNotEmpty && totalApproved > 0) {
      final share = totalApproved / members.length;
      final paidByMember = <String, double>{};
      for (final m in members) {
        paidByMember[m.id] = approved
            .where((e) => e.paidById == m.id)
            .fold<double>(0, (s, e) => s + e.amount);
      }
      final creditor = members.reduce((a, b) => (paidByMember[a.id] ?? 0) > (paidByMember[b.id] ?? 0) ? a : b);
      for (final m in members) {
        if (m.id == creditor.id) continue;
        final paid = paidByMember[m.id] ?? 0;
        final due = share - paid;
        if (due > 0) {
          settlements.add((from: m.name, to: creditor.name, amount: due));
        }
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.deepEarth,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💸 Minimum Transactions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('Computed from approved expenses', style: TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          if (settlements.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No settlements yet.',
                style: TextStyle(fontFamily: 'DM Sans', color: AppColors.warmMuted),
              ),
            )
          else
            ...settlements.map((s) => _buildSettlementRow(s.from, s.to, s.amount)),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(Map<String, double> categoryTotals) {
    if (categoryTotals.isEmpty) {
      return const Text(
        'No approved expenses yet.',
        style: TextStyle(fontFamily: 'DM Sans', color: AppColors.warmMuted),
      );
    }
    final total = categoryTotals.values.fold<double>(0, (a, b) => a + b);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: categoryTotals.entries.map((entry) {
          final pct = total == 0 ? 0.0 : entry.value / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(child: Text(entry.key, style: const TextStyle(fontFamily: 'DM Sans'))),
                Text('₱${entry.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)'),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDistributionCard(Map<String, double> categoryTotals, double totalSpent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Text(
        totalSpent <= 0
            ? 'No spending distribution yet.'
            : 'Approved spending: ₱${totalSpent.toStringAsFixed(0)} across ${categoryTotals.length} categories.',
        style: const TextStyle(fontFamily: 'DM Sans', color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildSettlementRow(String from, String to, double amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
      ),
      child: Row(
        children: [
          Text(from, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(to, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₱${amount.toInt()}', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFF0066CC), borderRadius: BorderRadius.circular(8)),
                child: const Text('💙 GCash', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalizeRole(MemberRole role) {
    switch (role) {
      case MemberRole.organizer:  return 'Organizer';
      case MemberRole.treasurer:  return 'Treasurer';
      case MemberRole.navigator:  return 'Navigator';
      case MemberRole.buyer:      return 'Buyer';
      case MemberRole.documenter: return 'Documenter';
      case MemberRole.member:     return 'Member';
    }
  }
}
