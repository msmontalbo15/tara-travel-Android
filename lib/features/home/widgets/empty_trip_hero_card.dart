import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/jit_guard.dart';
import '../../trips/widgets/join_trip_modal.dart';

/// Glassmorphic card displayed in the dark home-screen header when the user
/// has no active trip. Features:
///   • Dynamic rotating animated pill badges
///   • Breathing ambient glow & subtle travel watermark
///   • Tactile bouncy CTAs: [ + Plan a Trip ] and [ 🏷️ Join with Code ]
class EmptyTripHeroCard extends ConsumerStatefulWidget {
  const EmptyTripHeroCard({super.key});

  @override
  ConsumerState<EmptyTripHeroCard> createState() => _EmptyTripHeroCardState();
}

class _EmptyTripHeroCardState extends ConsumerState<EmptyTripHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;
  Timer? _badgeTimer;
  int _badgeIndex = 0;

  static const List<_BadgeItem> _badges = [
    _BadgeItem(emoji: '✈️', text: 'READY FOR YOUR NEXT GETAWAY?'),
    _BadgeItem(emoji: '🌴', text: 'TIME FOR AN ISLAND ESCAPE?'),
    _BadgeItem(emoji: '🚗', text: 'WEEKEND ROAD TRIP CALLING?'),
    _BadgeItem(emoji: '⛰️', text: 'READY FOR MOUNTAIN BREEZES?'),
    _BadgeItem(emoji: '🏖️', text: 'LIFE IS BETTER AT THE BEACH!'),
  ];

  @override
  void initState() {
    super.initState();
    // Ambient breathing glow controller (3-second cycle)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    // Rotate the badge every 3.5 seconds
    _badgeTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (mounted) {
        setState(() {
          _badgeIndex = (_badgeIndex + 1) % _badges.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentBadge = _badges[_badgeIndex];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Animated Ambient Glow Blob — Top Right ───────────────
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  final glowAlpha = 0.14 + (_glowAnimation.value * 0.14);
                  return Positioned(
                    right: -20,
                    top: -20,
                    child: IgnorePointer(
                      child: Container(
                        width: 115,
                        height: 115,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.amber.withValues(alpha: glowAlpha),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ── Animated Ambient Glow Blob — Bottom Left ─────────────
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  final glowAlpha = 0.10 + (_glowAnimation.value * 0.10);
                  return Positioned(
                    left: -30,
                    bottom: -30,
                    child: IgnorePointer(
                      child: Container(
                        width: 95,
                        height: 95,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: glowAlpha),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ── Subtle Travel Compass Watermark ───────────────────────
              Positioned(
                right: 14,
                bottom: 8,
                child: IgnorePointer(
                  child: Icon(
                    Icons.explore_outlined,
                    size: 96,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // ── Card Content ──────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Dynamic Rotating Animated Badge Pill ────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.35),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            ),
                          );
                        },
                        child: Row(
                          key: ValueKey<int>(_badgeIndex),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentBadge.emoji,
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                currentBadge.text,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryLight,
                                  letterSpacing: 0.6,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Headline ─────────────────────────────────────────
                    const Text(
                      'No active trips\non your radar',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Interactive CTA Buttons Row ──────────────────────
                    Row(
                      children: [
                        // Primary: Plan a Trip
                        Expanded(
                          child: _InteractiveCtaButton(
                            isPrimary: true,
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final canProceed =
                                  await JitGuard.checkCreateTripGuard(
                                      context, ref);
                              if (!canProceed || !context.mounted) return;
                              Navigator.pushNamed(context, '/create-trip');
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Plan a Trip',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Secondary: Join with Code
                        Expanded(
                          child: _InteractiveCtaButton(
                            isPrimary: false,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              showJoinTripModal(context, ref);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '🏷️',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Join with Code',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white
                                              .withValues(alpha: 0.90),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private Badge Data Model ─────────────────────────────────────────────────

class _BadgeItem {
  final String emoji;
  final String text;

  const _BadgeItem({required this.emoji, required this.text});
}

// ── Interactive CTA Button with Press Down Scale Animation ───────────────────

class _InteractiveCtaButton extends StatefulWidget {
  final bool isPrimary;
  final VoidCallback onTap;
  final Widget child;

  const _InteractiveCtaButton({
    required this.isPrimary,
    required this.onTap,
    required this.child,
  });

  @override
  State<_InteractiveCtaButton> createState() => _InteractiveCtaButtonState();
}

class _InteractiveCtaButtonState extends State<_InteractiveCtaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) async {
        await _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          height: 40,
          decoration: widget.isPrimary
              ? BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                )
              : BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                    width: 1.2,
                  ),
                ),
          child: widget.child,
        ),
      ),
    );
  }
}
