import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/trip_types.dart';
import '../../../core/utils/currency_utils.dart';

/// A trip list card — used for both "Upcoming" and "Draft" states.
/// Brand-aligned with premium card styling and animations.
class TripCard extends StatelessWidget {
  final String name;
  final String dateRange;
  final String? destination;
  final bool isUpcoming;
  final bool isIncomplete;
  final String? budget;
  final double? totalBudget;
  final double? totalSpent;
  final int? days;
  final int? people;
  final List<TravelerInfo>? travelers;
  final VoidCallback? onTap;
  // New metadata
  final String? tripId;
  final Color? coverColor;
  final String? tripType;
  final String? coverEmoji;
  final VoidCallback? onItinerary;
  final VoidCallback? onPacking;
  final VoidCallback? onMembers;
  final VoidCallback? onExpenses;
  final VoidCallback? onBudgetTap;
  final VoidCallback? onSetBudget;
  final VoidCallback? onChat;
  final VoidCallback? onNavigation;
  final VoidCallback? onMore;

  const TripCard.upcoming({
    super.key,
    required this.name,
    required this.dateRange,
    this.destination,
    this.isIncomplete = false,
    this.budget,
    this.totalBudget,
    this.totalSpent,
    this.days,
    this.people,
    this.travelers,
    this.onTap,
    this.onMore,
    this.tripId,
    this.coverColor,
    this.tripType,
    this.coverEmoji,
    this.onItinerary,
    this.onPacking,
    this.onMembers,
    this.onExpenses,
    this.onBudgetTap,
    this.onSetBudget,
    this.onChat,
    this.onNavigation,
  })  : isUpcoming = true;

  const TripCard.draft({
    super.key,
    required this.name,
    required this.dateRange,
    this.destination,
    this.isIncomplete = true,
    this.onTap,
    this.onMore,
  })  : isUpcoming = false,
        budget = null,
        totalBudget = null,
        totalSpent = null,
        days = null,
        people = null,
        travelers = null,
        tripId = null,
        coverColor = null,
        tripType = null,
        coverEmoji = null,
        onItinerary = null,
        onPacking = null,
        onMembers = null,
        onExpenses = null,
        onBudgetTap = null,
        onSetBudget = null,
        onChat = null,
        onNavigation = null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: isUpcoming ? _buildUpcoming() : _buildDraft(),
        ),
      ),
    );
  }

  Widget _buildUpcoming() {
    final accent = isIncomplete
        ? AppColors.warmMuted
        : (coverColor ?? AppTripTypes.getColor(tripType));
    final HSLColor hsl = HSLColor.fromColor(accent);
    final darkGrad = isIncomplete
        ? const Color(0xFF6E6A67)
        : hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    final lightGrad = isIncomplete
        ? const Color(0xFF9E9A96)
        : hsl.withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0)).toColor();
    final emojiDisplay = coverEmoji ?? AppTripTypes.getEmoji(tripType);

    final budgetVal = totalBudget ?? 0.0;
    final spentVal = totalSpent ?? 0.0;
    final hasBudget = budgetVal > 0;
    final pct = hasBudget ? (spentVal / budgetVal).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = hasBudget && spentVal > budgetVal;
    final isWarning = hasBudget && !isOverBudget && (spentVal / budgetVal) >= 0.7;
    final budgetText = hasBudget
        ? '₱${CurrencyUtils.formatAmount(spentVal)} / ₱${CurrencyUtils.formatAmount(budgetVal)}'
        : (spentVal > 0 ? '₱${CurrencyUtils.formatAmount(spentVal)} spent' : '₱0 / ₱0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover color accent strip
        Container(
          width: double.infinity,
          height: 5,
          color: accent,
        ),
        // Trip hero section with dynamic theme gradient + emoji watermark
        ClipRect(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [darkGrad, lightGrad],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          child: const Text(
                            'Upcoming',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (onMore != null)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onMore,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                              ),
                              child: const Icon(
                                Icons.more_horiz_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    if (destination != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              destination!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      dateRange,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              // Low-opacity emoji watermark — bottom-right of hero
              Positioned(
                right: -16,
                bottom: -28,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.10,
                    child: Transform.rotate(
                      angle: -0.12,
                      child: Text(
                        emojiDisplay,
                        style: const TextStyle(
                          fontSize: 130,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Info section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats boxes
              Row(
                children: [
                  Expanded(child: _statBox('DAYS', '${days ?? 0}')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: hasBudget ? onBudgetTap : onSetBudget,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        decoration: BoxDecoration(
                          color: hasBudget
                              ? (isOverBudget ? const Color(0xFFFEE2E2) : AppColors.surfaceLight)
                              : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasBudget
                                ? (isOverBudget ? const Color(0xFFFCA5A5) : AppColors.cardBorder)
                                : AppColors.primary.withValues(alpha: 0.3),
                            width: hasBudget ? 1.0 : 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'BUDGET',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 10,
                                    color: hasBudget
                                        ? (isOverBudget ? const Color(0xFFDC2626) : AppColors.warmMuted)
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  hasBudget ? Icons.chevron_right_rounded : Icons.add_circle_outline_rounded,
                                  size: 11,
                                  color: hasBudget
                                      ? (isOverBudget ? const Color(0xFFDC2626) : AppColors.warmMuted)
                                      : AppColors.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasBudget ? (budget ?? '—') : 'Set',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: hasBudget ? 20 : 16,
                                fontWeight: FontWeight.w700,
                                color: hasBudget
                                    ? (isOverBudget ? const Color(0xFFDC2626) : AppColors.textPrimary)
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _statBox('PEOPLE', '${people ?? 0}')),
                ],
              ),
              const SizedBox(height: 14),

              // Interactive Budget Bar & Tracker
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasBudget ? onBudgetTap : onSetBudget,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 13,
                                  color: isOverBudget
                                      ? const Color(0xFFDC2626)
                                      : (isWarning ? const Color(0xFFD97706) : AppColors.textSecondary),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  hasBudget
                                      ? (isOverBudget
                                          ? 'Over budget (${(pct * 100).round()}%)'
                                          : 'Budget used (${(pct * 100).round()}%)')
                                      : 'No budget set',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    fontWeight: isOverBudget || isWarning ? FontWeight.w700 : FontWeight.w500,
                                    color: isOverBudget
                                        ? const Color(0xFFDC2626)
                                        : (isWarning ? const Color(0xFFD97706) : AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            if (hasBudget)
                              Text(
                                budgetText,
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isOverBudget ? const Color(0xFFDC2626) : AppColors.textPrimary,
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: onSetBudget,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, size: 12, color: AppColors.primary),
                                      SizedBox(width: 2),
                                      Text(
                                        'Set budget',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: pct,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isOverBudget
                                      ? const [Color(0xFFEF4444), Color(0xFFB91C1C)]
                                      : isWarning
                                          ? const [Color(0xFFF59E0B), Color(0xFFD97706)]
                                          : const [AppColors.primary, AppColors.primaryLight],
                                ),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  if (pct > 0.05)
                                    BoxShadow(
                                      color: (isOverBudget
                                              ? const Color(0xFFEF4444)
                                              : (isWarning ? const Color(0xFFF59E0B) : AppColors.primary))
                                          .withValues(alpha: 0.35),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (hasBudget) ...[
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isOverBudget
                                    ? 'Exceeded by ₱${CurrencyUtils.formatAmount((spentVal - budgetVal).abs())}'
                                    : '₱${CurrencyUtils.formatAmount((budgetVal - spentVal).clamp(0, double.infinity))} remaining',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isOverBudget ? const Color(0xFFDC2626) : AppColors.warmMuted,
                                ),
                              ),
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Manage',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 1),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 9,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Avatars row
              if (travelers != null && travelers!.isNotEmpty)
                Row(
                  children: [
                    SizedBox(
                      height: 30,
                      width: (travelers!.length * 20.0) + 10,
                      child: Stack(
                        children: travelers!.asMap().entries.map((e) {
                          return Positioned(
                            left: e.key * 18.0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Color(e.value.color),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(e.value.color).withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  e.value.initials,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),

              // Action button bar — full width, evenly spaced
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton(Icons.navigation_rounded, 'Live Nav',
                      AppColors.primary, onNavigation),
                  _actionButton(Icons.calendar_today_outlined, 'Itinerary',
                      const Color(0xFF5B8DEF), onItinerary),
                  _actionButton(Icons.inventory_2_outlined, 'Packing',
                      const Color(0xFFF59E0B), onPacking),
                  _actionButton(Icons.group_outlined, 'Members',
                      const Color(0xFF10B981), onMembers),
                  _actionButton(Icons.attach_money_rounded, 'Expenses',
                      const Color(0xFFD85A30), onExpenses),
                  _actionButton(Icons.chat_bubble_outline_rounded, 'Chat',
                      const Color(0xFF8B5CF6), onChat),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDraft() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.warmMuted, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: AppColors.warmMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (destination != null)
                    Text(
                      destination!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    dateRange,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.amberBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFAC775)),
                  ),
                  child: const Text(
                    'Draft',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.amberText,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (onMore != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onMore,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              color: AppColors.warmMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
      IconData icon, String label, Color accentColor, VoidCallback? onPressed) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 20,
              color: onPressed != null ? accentColor : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: onPressed != null ? AppColors.textPrimary : AppColors.textSecondary,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class TravelerInfo {
  final String initials;
  final int color;
  const TravelerInfo(this.initials, this.color);
}

// Convenience constructor helpers
class TravelerData {
  static const primary = TravelerInfo('T1', 0xFFD85A30);
  static const secondary = TravelerInfo('T2', 0xFF8B5CF6);
  static const tertiary = TravelerInfo('T3', 0xFF0D9488);
}
