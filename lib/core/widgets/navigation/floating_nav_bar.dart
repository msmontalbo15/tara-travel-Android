import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../../features/home/home_route_args.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onItemSelected;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.of(context).viewPadding;
    // In edge-to-edge mode viewPadding.bottom gives the system gesture bar height.
    // We add a small extra gap so the pill floats above it.
    final sysNavHeight = viewPadding.bottom;
    final bottomMargin = sysNavHeight > 0 ? sysNavHeight + 6.0 : 16.0;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          // Ambient depth shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 22,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          // Brand coral glow
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE26135), // Vibrant coral
                  AppColors.primary, // Brand Coral (#D85A30)
                  Color(0xFFC04B22), // Deep burnt coral
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  context: context,
                  index: 0,
                  inactiveIcon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                _navItem(
                  context: context,
                  index: 1,
                  inactiveIcon: Icons.luggage_outlined,
                  activeIcon: Icons.luggage_rounded,
                  label: 'Trips',
                ),
                _navItem(
                  context: context,
                  index: 2,
                  inactiveIcon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'Budget',
                ),
                _navItem(
                  context: context,
                  index: 3,
                  inactiveIcon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  label: 'Explore',
                ),
                _navItem(
                  context: context,
                  index: 4,
                  inactiveIcon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required BuildContext context,
    required int index,
    required IconData inactiveIcon,
    required IconData activeIcon,
    required String label,
  }) {
    final active = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact().catchError((_) {});
          if (onItemSelected != null) {
            onItemSelected!(index);
          } else {
            if (currentIndex == index) return;
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
              arguments: HomeRouteArgs(initialIndex: index),
            );
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.24)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: active
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.0,
                        )
                      : null,
                ),
                child: Icon(
                  active ? activeIcon : inactiveIcon,
                  size: 22,
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.72),
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
