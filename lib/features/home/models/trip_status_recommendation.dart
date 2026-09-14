import 'package:flutter/material.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/theme/app_colors.dart';

/// Contextual status recommendation computed for a trip on the Home screen.
class TripStatusRecommendation {
  final TripStatus status;
  final String statusLabel;
  final Color statusColor;
  final Color statusBgColor;
  final Color statusBorderColor;
  final IconData? statusIcon;

  /// Actionable recommendation tip (e.g., "Add stops", "Finish packing", "Drive safe")
  final String recommendation;
  final IconData recommendationIcon;
  final Color recommendationColor;
  final Color recommendationBgColor;
  final Color recommendationBorderColor;

  /// Suggested target route to resolve this recommendation
  final String? suggestedActionRoute;

  const TripStatusRecommendation({
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBgColor,
    required this.statusBorderColor,
    this.statusIcon,
    required this.recommendation,
    required this.recommendationIcon,
    required this.recommendationColor,
    required this.recommendationBgColor,
    required this.recommendationBorderColor,
    this.suggestedActionRoute,
  });

  /// Evaluates trip attributes to produce a contextual status and recommendation.
  factory TripStatusRecommendation.fromTrip({
    required TripModel trip,
    int totalStops = 0,
    int visitedStops = 0,
    int? packedItems,
    int? totalPackingItems,
  }) {
    final status = trip.status;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysAway = trip.fromDate.difference(today).inDays;

    if (status == TripStatus.draft) {
      if (trip.destination.trim().isEmpty || trip.destination.trim().toUpperCase() == 'TBD') {
        return const TripStatusRecommendation(
          status: TripStatus.draft,
          statusLabel: 'Draft',
          statusColor: AppColors.warmMuted,
          statusBgColor: Color(0x20B4B2A9),
          statusBorderColor: Color(0x3DB4B2A9),
          statusIcon: Icons.edit_note_rounded,
          recommendation: 'Set destination to finalize',
          recommendationIcon: Icons.add_location_alt_outlined,
          recommendationColor: AppColors.primary,
          recommendationBgColor: AppColors.sand,
          recommendationBorderColor: AppColors.primaryLight,
          suggestedActionRoute: '/trip-detail',
        );
      }
      return const TripStatusRecommendation(
        status: TripStatus.draft,
        statusLabel: 'Draft',
        statusColor: AppColors.warmMuted,
        statusBgColor: Color(0x20B4B2A9),
        statusBorderColor: Color(0x3DB4B2A9),
        statusIcon: Icons.edit_note_rounded,
        recommendation: 'Review & publish plan',
        recommendationIcon: Icons.rocket_launch_outlined,
        recommendationColor: AppColors.primary,
        recommendationBgColor: AppColors.sand,
        recommendationBorderColor: AppColors.primaryLight,
        suggestedActionRoute: '/trip-detail',
      );
    }

    if (status == TripStatus.ongoing) {
      if (totalStops > 0 && visitedStops < totalStops) {
        return TripStatusRecommendation(
          status: TripStatus.ongoing,
          statusLabel: 'Ongoing',
          statusColor: AppColors.greenBright,
          statusBgColor: AppColors.green.withValues(alpha: 0.35),
          statusBorderColor: AppColors.greenBright.withValues(alpha: 0.60),
          statusIcon: Icons.fiber_manual_record_rounded,
          recommendation: 'Next: Stop ${visitedStops + 1} of $totalStops',
          recommendationIcon: Icons.navigation_rounded,
          recommendationColor: AppColors.greenBright,
          recommendationBgColor: AppColors.greenBg,
          recommendationBorderColor: AppColors.greenBright.withValues(alpha: 0.5),
          suggestedActionRoute: '/navigation',
        );
      }
      return TripStatusRecommendation(
        status: TripStatus.ongoing,
        statusLabel: 'Ongoing',
        statusColor: AppColors.greenBright,
        statusBgColor: AppColors.green.withValues(alpha: 0.35),
        statusBorderColor: AppColors.greenBright.withValues(alpha: 0.60),
        statusIcon: Icons.fiber_manual_record_rounded,
        recommendation: 'Live trip in progress • Tap to navigate',
        recommendationIcon: Icons.explore_rounded,
        recommendationColor: AppColors.greenBright,
        recommendationBgColor: AppColors.greenBg,
        recommendationBorderColor: AppColors.greenBright.withValues(alpha: 0.5),
        suggestedActionRoute: '/navigation',
      );
    }

    if (status == TripStatus.completed) {
      final hasUnsettled = trip.expenses.isNotEmpty;
      return TripStatusRecommendation(
        status: TripStatus.completed,
        statusLabel: 'Completed',
        statusColor: const Color(0xFF6B7280),
        statusBgColor: const Color(0x1F6B7280),
        statusBorderColor: const Color(0x386B7280),
        statusIcon: Icons.check_circle_outline_rounded,
        recommendation: hasUnsettled ? 'Settle & review expenses' : 'Trip memories saved',
        recommendationIcon: hasUnsettled ? Icons.receipt_long_outlined : Icons.photo_camera_back_outlined,
        recommendationColor: const Color(0xFF4B5563),
        recommendationBgColor: const Color(0xFFF3F4F6),
        recommendationBorderColor: const Color(0xFFE5E7EB),
        suggestedActionRoute: hasUnsettled ? '/budget' : '/trip-detail',
      );
    }

    // TripStatus.planning (Upcoming)
    if (totalStops == 0) {
      return const TripStatusRecommendation(
        status: TripStatus.planning,
        statusLabel: 'Upcoming',
        statusColor: Colors.white,
        statusBgColor: Color(0x38FFFFFF),
        statusBorderColor: Color(0x59FFFFFF),
        statusIcon: Icons.calendar_today_rounded,
        recommendation: 'Missing stops • Add your first spot',
        recommendationIcon: Icons.add_circle_outline_rounded,
        recommendationColor: AppColors.amberText,
        recommendationBgColor: AppColors.amberLight,
        recommendationBorderColor: Color(0xFFF59E0B),
        suggestedActionRoute: '/itinerary',
      );
    }

    if (trip.totalBudget <= 0) {
      return const TripStatusRecommendation(
        status: TripStatus.planning,
        statusLabel: 'Upcoming',
        statusColor: Colors.white,
        statusBgColor: Color(0x38FFFFFF),
        statusBorderColor: Color(0x59FFFFFF),
        statusIcon: Icons.calendar_today_rounded,
        recommendation: 'Set estimated trip budget',
        recommendationIcon: Icons.savings_outlined,
        recommendationColor: Color(0xFF1E40AF),
        recommendationBgColor: Color(0xFFDBEAFE),
        recommendationBorderColor: Color(0xFF3B82F6),
        suggestedActionRoute: '/budget',
      );
    }

    if (trip.members.length <= 1) {
      return const TripStatusRecommendation(
        status: TripStatus.planning,
        statusLabel: 'Upcoming',
        statusColor: Colors.white,
        statusBgColor: Color(0x38FFFFFF),
        statusBorderColor: Color(0x59FFFFFF),
        statusIcon: Icons.calendar_today_rounded,
        recommendation: 'Invite squad or barkada',
        recommendationIcon: Icons.person_add_outlined,
        recommendationColor: Color(0xFF065F46),
        recommendationBgColor: Color(0xFFD1FAE5),
        recommendationBorderColor: Color(0xFF10B981),
        suggestedActionRoute: '/members',
      );
    }

    if (daysAway <= 2 && daysAway >= 0) {
      return TripStatusRecommendation(
        status: TripStatus.planning,
        statusLabel: daysAway == 0 ? 'Starts Today' : (daysAway == 1 ? 'Starts Tomorrow' : 'In 2 days'),
        statusColor: Colors.white,
        statusBgColor: const Color(0x38FFFFFF),
        statusBorderColor: const Color(0x59FFFFFF),
        statusIcon: Icons.alarm_rounded,
        recommendation: 'Ready for takeoff • Check packing list',
        recommendationIcon: Icons.inventory_2_outlined,
        recommendationColor: AppColors.primary,
        recommendationBgColor: AppColors.sand,
        recommendationBorderColor: AppColors.primaryLight,
        suggestedActionRoute: '/packing',
      );
    }

    return TripStatusRecommendation(
      status: TripStatus.planning,
      statusLabel: 'Upcoming',
      statusColor: Colors.white,
      statusBgColor: const Color(0x38FFFFFF),
      statusBorderColor: const Color(0x59FFFFFF),
      statusIcon: Icons.calendar_today_rounded,
      recommendation: '$daysAway days to go • Itinerary on track',
      recommendationIcon: Icons.check_circle_outline_rounded,
      recommendationColor: AppColors.green,
      recommendationBgColor: AppColors.greenBg,
      recommendationBorderColor: AppColors.greenBright.withValues(alpha: 0.4),
      suggestedActionRoute: '/itinerary',
    );
  }
}
