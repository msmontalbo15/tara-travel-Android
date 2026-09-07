import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// TripDetailBottomBar
/// ─────────────────────────────────────────────────────────────────────────────
/// Frosted-glass floating navigation dock pinned at the bottom of the Trip
/// Detail screen. Provides 5 primary navigation targets styled as compact
/// icon+label pills within a deep-earth glassmorphism container.
///
/// **Tabs**: Itinerary · Packing · Members · Expenses · Chat
///
/// For **active/ongoing** trips, long-pressing the Itinerary icon triggers
/// live navigation. The dock visually mirrors `ItineraryBottomDock` design.
/// ─────────────────────────────────────────────────────────────────────────────
class TripDetailBottomBar extends StatelessWidget {
  final bool isOngoing;
  final VoidCallback onNavigationTap;
  final VoidCallback onItineraryTap;
  final VoidCallback onPackingTap;
  final VoidCallback onMembersTap;
  final VoidCallback onExpensesTap;
  final VoidCallback onChatTap;

  const TripDetailBottomBar({
    super.key,
    required this.isOngoing,
    required this.onNavigationTap,
    required this.onItineraryTap,
    required this.onPackingTap,
    required this.onMembersTap,
    required this.onExpensesTap,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      left: 12,
      right: 12,
      bottom: bottomInset > 0 ? bottomInset + 8 : 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.deepEarth.withValues(alpha: 0.93),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ── 1. Itinerary (hero for ongoing → live nav on long-press)
                _DockNavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Itinerary',
                  isHero: true,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onItineraryTap();
                  },
                  onLongPress: isOngoing
                      ? () {
                          HapticFeedback.mediumImpact();
                          onNavigationTap();
                        }
                      : null,
                ),

                // ── 2. Packing
                _DockNavItem(
                  icon: Icons.backpack_rounded,
                  label: 'Packing',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onPackingTap();
                  },
                ),

                // ── 3. Members
                _DockNavItem(
                  icon: Icons.groups_rounded,
                  label: 'Members',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onMembersTap();
                  },
                ),

                // ── 4. Expenses
                _DockNavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Expenses',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onExpensesTap();
                  },
                ),

                // ── 5. Chat
                _DockNavItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onChatTap();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Navigation Item
// ─────────────────────────────────────────────────────────────────────────────

class _DockNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHero;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _DockNavItem({
    required this.icon,
    required this.label,
    this.isHero = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container with optional hero accent
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHero
                      ? AppColors.primary.withValues(alpha: 0.20)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isHero
                      ? const Color(0xFFF0997B) // Light coral for hero
                      : Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 4),
              // Label
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isHero ? FontWeight.w700 : FontWeight.w500,
                  color: isHero
                      ? const Color(0xFFF0997B)
                      : Colors.white.withValues(alpha: 0.65),
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
