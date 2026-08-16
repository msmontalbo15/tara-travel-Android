import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/providers/packing_provider.dart';
import '../../core/providers/itinerary_provider.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/expense_model.dart';
import '../../core/widgets/buttons/app_back_button.dart';
import '../../core/widgets/navigation/floating_nav_bar.dart';
import '../../core/constants/trip_types.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TripDetailScreen — dashboard UI (glassmorphic iOS 17/18 layout)
// ─────────────────────────────────────────────────────────────────────────────

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(selectedTripProvider);

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return const Scaffold(
            backgroundColor: AppColors.surfaceLight,
            body: Center(child: Text('Trip not found')),
          );
        }
        return _TripDashboard(trip: trip);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.surfaceLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.surfaceLight,
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TripDashboard extends ConsumerStatefulWidget {
  final TripModel trip;
  const _TripDashboard({required this.trip});

  @override
  ConsumerState<_TripDashboard> createState() => _TripDashboardState();
}

class _TripDashboardState extends ConsumerState<_TripDashboard> {
  /// Parse cover color string/int with AppColors.parseTripColor
  Color _parseCoverColor(String? raw) =>
      AppColors.parseTripColor(raw, defaultColor: const Color(0xFF2C1A14));

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final coverColor = _parseCoverColor(trip.coverColor);

    // ── Expenses ─────────────────────────────────────────────────
    final expensesAsync = ref.watch(expenseProvider(trip.id));
    final expenses = expensesAsync.asData?.value ?? trip.expenses;

    final totalSpent = expenses
        .where((e) => e.status == ExpenseStatus.approved)
        .fold<double>(0, (s, e) => s + e.amount);
    final totalPending = expenses
        .where((e) => e.status == ExpenseStatus.pending)
        .fold<double>(0, (s, e) => s + e.amount);
    final remaining = trip.totalBudget - totalSpent;
    final budgetPct =
        trip.totalBudget > 0 ? (totalSpent / trip.totalBudget).clamp(0.0, 1.0) : 0.0;

    // ── Packing ──────────────────────────────────────────────────
    final packingProviderInst = ref.watch(packingProvider(trip.id));
    final packingState = ref.watch(packingProviderInst);
    final packedCount = packingState.packedItems;
    final totalPacking = packingState.totalItems;

    // ── Itinerary ────────────────────────────────────────────────
    final itineraryProviderInst = ref.watch(itineraryProvider(trip.id));
    final itineraryAsync = ref.watch(itineraryProviderInst);
    final itineraryDayCount = itineraryAsync.asData?.value.days.length ?? 0;

    final nights = trip.toDate.difference(trip.fromDate).inDays;
    final now = DateTime.now();
    final isActive = now.isAfter(trip.fromDate) && now.isBefore(trip.toDate);

    // ── Section definitions (vertical list) ──────────────────────
    final sections = [
      _SectionItem(
        icon: Icons.calendar_month_rounded,
        label: 'Itinerary',
        subtitle: '$itineraryDayCount days planned',
        color: const Color(0xFF185FA5),
        route: '/itinerary',
      ),
      _SectionItem(
        icon: Icons.luggage_rounded,
        label: 'Packing',
        subtitle: '$packedCount / $totalPacking items packed',
        color: const Color(0xFF854F0B),
        route: '/packing',
      ),
      _SectionItem(
        icon: Icons.group_rounded,
        label: 'Members',
        subtitle: '${trip.members.length} people',
        color: const Color(0xFF3B6D11),
        route: '/members',
      ),
      _SectionItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Budget & Expenses',
        subtitle: '₱${_fmt(totalSpent)} spent',
        color: AppColors.primary,
        route: '/budget',
      ),
      const _SectionItem(
        icon: Icons.chat_bubble_rounded,
        label: 'Chat & Polls',
        subtitle: 'Group chat',
        color: Color(0xFF4A2C7A),
        route: '/chat',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroHeader(
                  trip: trip,
                  coverColor: coverColor,
                  nights: nights,
                  isActive: isActive,
                ),
              ),

              // ── Body ────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Stats row
                    _StatsRow(trip: trip, nights: nights),
                    const SizedBox(height: 12),

                    // Budget bar
                    if (trip.totalBudget > 0) ...[
                      _BudgetCard(
                        totalSpent: totalSpent,
                        totalPending: totalPending,
                        remaining: remaining,
                        budget: trip.totalBudget,
                        budgetPct: budgetPct,
                        onTap: () => Navigator.pushNamed(context, '/budget'),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Section links
                    _SectionLinks(sections: sections),
                    const SizedBox(height: 12),

                    // Navigate CTA — active trips only
                    if (isActive) ...[
                      _NavButton(
                        onTap: () => Navigator.pushNamed(context, '/navigation'),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Invite code
                    if (trip.inviteCode.isNotEmpty)
                      _InviteCard(inviteCode: trip.inviteCode),

                    // Bottom clearance for floating nav
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),

          // ── Bottom navigation bar ────────────────────────────────
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavBar(
              currentIndex: 1,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      NumberFormat('#,##0', 'en_PH').format(v.toInt());
}


// ─────────────────────────────────────────────────────────────────────────────
// Hero Header — ambient gradient mesh + frosted status pill
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends ConsumerWidget {
  final TripModel trip;
  final Color coverColor;
  final int nights;
  final bool isActive;

  const _HeroHeader({
    required this.trip,
    required this.coverColor,
    required this.nights,
    required this.isActive,
  });

  Future<void> _confirmDeleteTrip(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text('Are you sure you want to delete "${trip.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final repo = ref.read(tripRepositoryProvider);
      await repo.deleteTrip(trip.id);
      ref.read(selectedTripIdProvider.notifier).clear();
      ref.invalidate(allTripsProvider);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;

    // Derived ambient accent — slightly lighter tone for mesh
    final accentLight = HSLColor.fromColor(coverColor)
        .withLightness((HSLColor.fromColor(coverColor).lightness + 0.18).clamp(0.0, 1.0))
        .toColor();

    final emoji = trip.coverEmoji ?? AppTripTypes.getEmoji(trip.tripType);
    final imageUrl = trip.destinationDetails?['image'] ??
        trip.destinationDetails?['cover_image'] ??
        trip.destinationDetails?['image_url'];

    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              HSLColor.fromColor(coverColor)
                  .withLightness(
                      (HSLColor.fromColor(coverColor).lightness - 0.12).clamp(0.0, 1.0))
                  .toColor(),
              coverColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // ── Background cover image watermark (if available) ──────
            if (imageUrl != null && imageUrl.toString().isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.12,
                    child: Image.network(
                      imageUrl.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

            // ── Large emoji watermark — bottom right ─────────────────
            Positioned(
              right: -20,
              bottom: -30,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.10,
                  child: Transform.rotate(
                    angle: -0.10,
                    child: Text(
                      emoji,
                      style: const TextStyle(
                        fontSize: 160,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Ambient mesh blobs
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentLight.withValues(alpha: 0.22),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppBackButton(),
                      IconButton(
                        onPressed: () => _confirmDeleteTrip(context, ref),
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
                        tooltip: 'Delete Trip',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _StatusBadge(isActive: isActive, isArchived: trip.isArchived),
                  const SizedBox(height: 10),

                  Text(
                    trip.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.12,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.place_rounded,
                          color: Colors.white.withValues(alpha: 0.60), size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trip.destination,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.60),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    '${DateFormat('MMM d').format(trip.fromDate)}–'
                    '${DateFormat('MMM d, yyyy').format(trip.toDate)} · $nights nights',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge — glassmorphic pill
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final bool isArchived;
  const _StatusBadge({required this.isActive, required this.isArchived});

  @override
  Widget build(BuildContext context) {
    final label = isActive ? 'Active' : isArchived ? 'Completed' : 'Planning';
    final dot = isActive
        ? AppColors.greenBright
        : isArchived
            ? AppColors.warmMuted
            : AppColors.amber;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row  (Nights / Budget / People) — glassmorphic cells
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final TripModel trip;
  final int nights;
  const _StatsRow({required this.trip, required this.nights});

  @override
  Widget build(BuildContext context) {
    final budget = trip.totalBudget;
    final budgetLabel = budget >= 1000
        ? '₱${(budget / 1000).toStringAsFixed(0)}k'
        : '₱${budget.toInt()}';

    return Row(
      children: [
        Expanded(
          child: _StatCell(
            label: 'Nights',
            value: '$nights',
            icon: Icons.nights_stay_rounded,
            iconColor: const Color(0xFF7E57C2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCell(
            label: 'Budget',
            value: budgetLabel,
            icon: Icons.account_balance_wallet_rounded,
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCell(
            label: 'People',
            value: '${trip.members.length}',
            icon: Icons.group_rounded,
            iconColor: const Color(0xFF3B6D11),
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget Card — glass with animated progress
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  final double totalSpent;
  final double totalPending;
  final double remaining;
  final double budget;
  final double budgetPct;
  final VoidCallback onTap;

  const _BudgetCard({
    required this.totalSpent,
    required this.totalPending,
    required this.remaining,
    required this.budget,
    required this.budgetPct,
    required this.onTap,
  });

  Color get _barColor {
    if (budgetPct >= 0.9) return const Color(0xFFA32D2D);
    if (budgetPct > 0.7) return const Color(0xFFE09A30);
    return AppColors.primary;
  }

  Color get _pctColor =>
      budgetPct > 0.9 ? const Color(0xFFA32D2D) : AppColors.primary;

  static String _fmt(double v) =>
      NumberFormat('#,##0', 'en_PH').format(v.toInt());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _barColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.account_balance_wallet_rounded,
                          size: 18, color: _barColor),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Budget',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _pctColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(budgetPct * 100).round()}% used',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _pctColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: budgetPct),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => LinearProgressIndicator(
                  value: val,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF2F2F7),
                  valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Spent / Pending / Remaining
            Row(
              children: [
                Expanded(
                  child: _BudgetStat(
                    label: 'Spent',
                    value: '₱${_fmt(totalSpent)}',
                    valueColor: const Color(0xFF1A1A1A),
                  ),
                ),
                Expanded(
                  child: _BudgetStat(
                    label: 'Pending',
                    value: '₱${_fmt(totalPending)}',
                    valueColor: const Color(0xFF854F0B),
                    align: CrossAxisAlignment.center,
                  ),
                ),
                Expanded(
                  child: _BudgetStat(
                    label: 'Remaining',
                    value:
                        '₱${_fmt(remaining.abs())}${remaining < 0 ? ' over' : ''}',
                    valueColor: remaining < 0
                        ? const Color(0xFFA32D2D)
                        : const Color(0xFF3B6D11),
                    align: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final CrossAxisAlignment align;

  const _BudgetStat({
    required this.label,
    required this.value,
    required this.valueColor,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                color: Color(0xFF8E8E93))),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor)),
      ],
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Section Links — glass card container
// ─────────────────────────────────────────────────────────────────────────────

class _SectionItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String route;

  const _SectionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.route,
  });
}

class _SectionLinks extends StatelessWidget {
  final List<_SectionItem> sections;

  const _SectionLinks({required this.sections});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: sections.asMap().entries.map((entry) {
          final isLast = entry.key == sections.length - 1;
          return _SectionRow(
            item: entry.value,
            showDivider: !isLast,
            onTap: () => Navigator.pushNamed(context, entry.value.route),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionRow extends StatefulWidget {
  final _SectionItem item;
  final bool showDivider;
  final VoidCallback onTap;

  const _SectionRow({
    required this.item,
    required this.showDivider,
    required this.onTap,
  });

  @override
  State<_SectionRow> createState() => _SectionRowState();
}

class _SectionRowState extends State<_SectionRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        color: _pressed ? const Color(0xFFF2F2F7) : Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.item.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(widget.item.icon,
                        size: 20, color: widget.item.color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.item.label,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            )),
                        const SizedBox(height: 2),
                        Text(widget.item.subtitle,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            )),
                      ],
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chevron_right_rounded,
                        size: 18, color: Color(0xFFB0B0BA)),
                  ),
                ],
              ),
            ),
            if (widget.showDivider)
              const Divider(
                  height: 1,
                  thickness: 0.8,
                  indent: 72,
                  color: Color(0xFFEEEEEE)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation CTA
// ─────────────────────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NavButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD85A30), Color(0xFFEF8A5E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.40),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Start Navigation',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invite Code Card — dark glass with ambient glow
// ─────────────────────────────────────────────────────────────────────────────

class _InviteCard extends StatefulWidget {
  final String inviteCode;
  const _InviteCard({required this.inviteCode});

  @override
  State<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<_InviteCard> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.inviteCode));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite code copied!',
            style: TextStyle(fontFamily: 'DM Sans')),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(
        text: 'Join my trip on Tara Travel! Enter invite code: ${widget.inviteCode}',
        subject: 'Tara Travel Trip Invite',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A04), Color(0xFF2C1A14)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow blob
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INVITE CODE',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.40),
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.inviteCode,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Share with your squad to join this trip',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _InviteIconBtn(
                        icon: Icons.share_rounded,
                        onTap: _share,
                      ),
                      const SizedBox(height: 8),
                      _InviteIconBtn(
                        icon: _copied
                            ? Icons.check_circle_rounded
                            : Icons.copy_rounded,
                        activeColor: _copied ? AppColors.greenBright : null,
                        onTap: _copy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? activeColor;
  const _InviteIconBtn({required this.icon, required this.onTap, this.activeColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: activeColor ?? Colors.white.withValues(alpha: 0.70),
        ),
      ),
    );
  }
}
