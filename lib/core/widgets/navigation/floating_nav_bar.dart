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
    final sysNavHeight = viewPadding.bottom;
    final bottomMargin = sysNavHeight > 0 ? sysNavHeight + 6.0 : 16.0;

    const double barHeight = 72.0;
    const double centerButtonSize = 56.0;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Navigation Bar Base with Glow & Ambient Shadow
          Container(
            height: barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                // Deep ambient shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                // Brand glow
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 26,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: barHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.32),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Home (0)
                      _navItem(
                        context: context,
                        index: 0,
                        inactiveIcon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Home',
                      ),
                      // Trips (1)
                      _navItem(
                        context: context,
                        index: 1,
                        inactiveIcon: Icons.luggage_outlined,
                        activeIcon: Icons.luggage_rounded,
                        label: 'Trips',
                      ),
                      // Spacer reserve for the elevated center plus button
                      const SizedBox(width: centerButtonSize + 12),
                      // Budget (2)
                      _navItem(
                        context: context,
                        index: 2,
                        inactiveIcon: Icons.account_balance_wallet_outlined,
                        activeIcon: Icons.account_balance_wallet_rounded,
                        label: 'Budget',
                      ),
                      // Explore (3)
                      _navItem(
                        context: context,
                        index: 3,
                        inactiveIcon: Icons.explore_outlined,
                        activeIcon: Icons.explore_rounded,
                        label: 'Explore',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Elevated Centered Circular Plus Button
          Positioned(
            top: -14,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact().catchError((_) {});
                Navigator.pushNamed(context, '/create-trip');
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: centerButtonSize,
                height: centerButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 3.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.38),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.26)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: active
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.38),
                          width: 1.0,
                        )
                      : null,
                ),
                child: Icon(
                  active ? activeIcon : inactiveIcon,
                  size: 24,
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.75),
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
