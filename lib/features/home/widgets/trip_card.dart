import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/member_avatar_circle.dart';
import '../../../core/constants/trip_types.dart';
import '../../../core/utils/currency_utils.dart';
import '../models/trip_card_badge_data.dart';

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
  final int? visitedStops;
  final int? totalStops;
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
  final TripQuickActionChanges? actionChanges;
  final String? overlappingTripName;

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
    this.visitedStops,
    this.totalStops,
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
    this.actionChanges,
    this.overlappingTripName,
  })  : isUpcoming = true;

  const TripCard.draft({
    super.key,
    required this.name,
    required this.dateRange,
    this.destination,
    this.isIncomplete = true,
    this.onTap,
    this.onMore,
    this.overlappingTripName,
  })  : isUpcoming = false,
        budget = null,
        totalBudget = null,
        totalSpent = null,
        days = null,
        people = null,
        visitedStops = null,
        totalStops = null,
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
        onNavigation = null,
        actionChanges = null;

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
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            if (overlappingTripName != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7), // Warm amber
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFF59E0B)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFB45309)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Overlaps: $overlappingTripName',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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
                        fontFamily: AppTextStyles.fontHeading,
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
                    child: _statBox(
                      'ITINERARY',
                      '${visitedStops ?? 0}/${totalStops ?? 0}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _statBox('PEOPLE', '${people ?? 0}')),
                ],
              ),
              const SizedBox(height: 14),

              // Informational Budget Bar & Tracker (non-clickable, no Manage >)
              Padding(
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
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isOverBudget ? const Color(0xFFDC2626) : AppColors.textPrimary,
                            ),
                          )
                        else
                          const Text(
                            '₱0',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warmMuted,
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
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isOverBudget ? const Color(0xFFDC2626) : AppColors.warmMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
                            child: MemberAvatarCircle(
                              photoUrl: e.value.photoUrl,
                              initials: e.value.initials,
                              color: Color(e.value.color),
                              size: 30,
                              border: Border.all(color: Colors.white, width: 2.5),
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
                  _actionButton(
                    Icons.calendar_today_outlined,
                    'Itinerary',
                    const Color(0xFF5B8DEF),
                    onItinerary,
                    hasNotificationDot: actionChanges?.hasItineraryChanges ?? false,
                  ),
                  _actionButton(
                    Icons.inventory_2_outlined,
                    'Packing',
                    const Color(0xFFF59E0B),
                    onPacking,
                    hasNotificationDot: actionChanges?.hasPackingChanges ?? false,
                  ),
                  _actionButton(
                    Icons.group_outlined,
                    'Members',
                    const Color(0xFF10B981),
                    onMembers,
                    hasNotificationDot: actionChanges?.hasMemberChanges ?? false,
                  ),
                  _actionButton(
                    Icons.attach_money_rounded,
                    'Expenses',
                    const Color(0xFFD85A30),
                    onExpenses,
                    hasNotificationDot: actionChanges?.hasExpenseChanges ?? false,
                  ),
                  _actionButton(
                    Icons.chat_bubble_outline_rounded,
                    'Chat',
                    const Color(0xFF8B5CF6),
                    onChat,
                    hasNotificationDot: actionChanges?.hasChatChanges ?? false,
                  ),
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
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warmMuted.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DRAFT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warmMuted,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          if (overlappingTripName != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFF59E0B)),
                              ),
                              child: Text(
                                '⚠️ Overlaps: $overlappingTripName',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontHeading,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    destination != null && destination!.isNotEmpty
                        ? destination!
                        : 'Destination not set',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onMore != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
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
    IconData icon,
    String label,
    Color accentColor,
    VoidCallback? onPressed, {
    bool hasNotificationDot = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
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
                if (hasNotificationDot)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IgnorePointer(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444), // High-visibility red
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
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
  final String? photoUrl;
  const TravelerInfo(this.initials, this.color, {this.photoUrl});
}

// Convenience constructor helpers
class TravelerData {
  static const primary = TravelerInfo('T1', 0xFFD85A30);
  static const secondary = TravelerInfo('T2', 0xFF8B5CF6);
  static const tertiary = TravelerInfo('T3', 0xFF0D9488);
}
