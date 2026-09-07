import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// TripQuickActionsGrid
/// ─────────────────────────────────────────────────────────────────────────────
/// Unified 6-tile Quick Action Hub consolidating scattered navigation items:
/// • Itinerary & Schedule (with stop progress count)
/// • Budget & Split Bill (with live spent tally)
/// • Squad & Members (with member count)
/// • Packing Checklist (with packed ratio)
/// • Chat & Polls (group discussions)
/// • Settings & Invite (trip configuration)
/// ─────────────────────────────────────────────────────────────────────────────
class TripQuickActionsGrid extends StatelessWidget {
  final int totalStops;
  final int visitedStops;
  final double totalSpent;
  final double totalBudget;
  final int memberCount;
  final int packedCount;
  final int totalPacking;
  final VoidCallback onItineraryTap;
  final VoidCallback onBudgetTap;
  final VoidCallback onMembersTap;
  final VoidCallback onPackingTap;
  final VoidCallback onChatTap;
  final VoidCallback onSettingsTap;

  const TripQuickActionsGrid({
    super.key,
    required this.totalStops,
    required this.visitedStops,
    required this.totalSpent,
    required this.totalBudget,
    required this.memberCount,
    required this.packedCount,
    required this.totalPacking,
    required this.onItineraryTap,
    required this.onBudgetTap,
    required this.onMembersTap,
    required this.onPackingTap,
    required this.onChatTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.grid_view_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'QUICK ACTIONS & TOOLS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFFD85A30),
                backgroundColor: const Color(0xFFFFF2ED),
                title: 'Itinerary',
                subtitle: totalStops > 0 ? '$visitedStops/$totalStops stops' : 'View plan',
                onTap: onItineraryTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF1E88E5),
                backgroundColor: const Color(0xFFEDF5FF),
                title: 'Budget',
                subtitle: totalBudget > 0
                    ? '₱${totalSpent.toStringAsFixed(0)} spent'
                    : 'Track expenses',
                onTap: onBudgetTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFF2E7D32),
                backgroundColor: const Color(0xFFEEF7EE),
                title: 'Squad',
                subtitle: memberCount > 0 ? '$memberCount travelers' : 'Manage crew',
                onTap: onMembersTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.luggage_rounded,
                iconColor: const Color(0xFF854F0B),
                backgroundColor: const Color(0xFFFFF7EB),
                title: 'Packing',
                subtitle: totalPacking > 0
                    ? '$packedCount/$totalPacking packed'
                    : 'Checklist',
                onTap: onPackingTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.chat_bubble_rounded,
                iconColor: const Color(0xFF6A1B9A),
                backgroundColor: const Color(0xFFF7EDFF),
                title: 'Chat & Polls',
                subtitle: 'Discussions',
                onTap: onChatTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.settings_rounded,
                iconColor: const Color(0xFF455A64),
                backgroundColor: const Color(0xFFECEFF1),
                title: 'Settings',
                subtitle: 'Invite & config',
                onTap: onSettingsTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEBE8E3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
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
