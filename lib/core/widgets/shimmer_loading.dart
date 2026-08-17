import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer Animation Base
// ─────────────────────────────────────────────────────────────────────────────

/// High-performance animated shimmer sweep effect.
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isDark = false,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE8E5E0);
    final highlightColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.22)
        : const Color(0xFFF7F5F2);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              stops: const [0.0, 0.5, 1.0],
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              transform: _SlidingGradientTransform(slidePercent: _ctrl.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Atomic Shimmer Box
// ─────────────────────────────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isDark;
  final ShapeBorder? shape;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.isDark = false,
    this.shape,
  });

  const ShimmerBox.circle({
    super.key,
    required double size,
    this.isDark = false,
  })  : width = size,
        height = size,
        borderRadius = size / 2,
        shape = const CircleBorder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.12)
            : const Color(0xFFEBE8E3),
        shape: shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Next Trip Hero Skeleton (Dark Theme)
// ─────────────────────────────────────────────────────────────────────────────

class NextTripCardSkeleton extends StatelessWidget {
  const NextTripCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isDark: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 80, height: 22, borderRadius: 10, isDark: true),
                ShimmerBox(width: 110, height: 22, borderRadius: 9, isDark: true),
              ],
            ),
            SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                ShimmerBox(width: 65, height: 48, borderRadius: 12, isDark: true),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 90, height: 14, borderRadius: 6, isDark: true),
                    SizedBox(height: 6),
                    ShimmerBox(width: 65, height: 11, borderRadius: 6, isDark: true),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ShimmerBox(width: 30, height: 30, borderRadius: 9, isDark: true),
                SizedBox(width: 8),
                ShimmerBox(width: 130, height: 14, borderRadius: 6, isDark: true),
                SizedBox(width: 8),
                ShimmerBox(width: 44, height: 20, borderRadius: 8, isDark: true),
              ],
            ),
            SizedBox(height: 14),
            ShimmerBox(width: 180, height: 20, borderRadius: 6, isDark: true),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trip Card Skeleton (Light Theme)
// ─────────────────────────────────────────────────────────────────────────────

class TripCardSkeleton extends StatelessWidget {
  const TripCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 44, height: 44, borderRadius: 14),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 140, height: 16, borderRadius: 6),
                        SizedBox(height: 6),
                        ShimmerBox(width: 90, height: 12, borderRadius: 6),
                      ],
                    ),
                  ),
                  ShimmerBox(width: 28, height: 28, borderRadius: 8),
                ],
              ),
              SizedBox(height: 18),

              // 3 Stats boxes
              Row(
                children: [
                  Expanded(child: ShimmerBox(height: 52, borderRadius: 14)),
                  SizedBox(width: 8),
                  Expanded(child: ShimmerBox(height: 52, borderRadius: 14)),
                  SizedBox(width: 8),
                  Expanded(child: ShimmerBox(height: 52, borderRadius: 14)),
                ],
              ),
              SizedBox(height: 14),

              // Budget bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: 80, height: 12, borderRadius: 4),
                  ShimmerBox(width: 100, height: 12, borderRadius: 4),
                ],
              ),
              SizedBox(height: 8),
              ShimmerBox(height: 6, width: double.infinity, borderRadius: 3),
              SizedBox(height: 14),

              // Avatars row
              Row(
                children: [
                  ShimmerBox.circle(size: 28),
                  SizedBox(width: 6),
                  ShimmerBox.circle(size: 28),
                  SizedBox(width: 6),
                  ShimmerBox.circle(size: 28),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trips List Skeleton (Multiple Cards)
// ─────────────────────────────────────────────────────────────────────────────

class TripsListSkeleton extends StatelessWidget {
  final int count;
  const TripsListSkeleton({super.key, this.count = 2});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const TripCardSkeleton()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget Screen Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class BudgetScreenSkeleton extends StatelessWidget {
  const BudgetScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // Dark Header Hero
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const ShimmerLoading(
                isDark: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 120, height: 26, borderRadius: 8, isDark: true),
                    SizedBox(height: 20),
                    ShimmerBox(height: 130, width: double.infinity, borderRadius: 18, isDark: true),
                    SizedBox(height: 16),
                    ShimmerBox(height: 38, width: double.infinity, borderRadius: 12, isDark: true),
                  ],
                ),
              ),
            ),

            // Body cards
            const Padding(
              padding: EdgeInsets.all(24),
              child: ShimmerLoading(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 130, height: 12, borderRadius: 4),
                    SizedBox(height: 12),
                    ShimmerBox(height: 160, width: double.infinity, borderRadius: 18),
                    SizedBox(height: 24),
                    ShimmerBox(width: 100, height: 12, borderRadius: 4),
                    SizedBox(height: 12),
                    ShimmerBox(height: 120, width: double.infinity, borderRadius: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Itinerary Screen Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class ItineraryScreenSkeleton extends StatelessWidget {
  const ItineraryScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // Dark Header Hero
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const ShimmerLoading(
                isDark: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBox(width: 140, height: 26, borderRadius: 8, isDark: true),
                        ShimmerBox(width: 70, height: 32, borderRadius: 12, isDark: true),
                      ],
                    ),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        ShimmerBox(width: 80, height: 36, borderRadius: 12, isDark: true),
                        SizedBox(width: 8),
                        ShimmerBox(width: 80, height: 36, borderRadius: 12, isDark: true),
                        SizedBox(width: 8),
                        ShimmerBox(width: 80, height: 36, borderRadius: 12, isDark: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Stop items
            Padding(
              padding: const EdgeInsets.all(20),
              child: ShimmerLoading(
                child: Column(
                  children: List.generate(
                    3,
                    (_) => Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: const ShimmerBox(height: 90, width: double.infinity, borderRadius: 18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trip Detail Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class TripDetailSkeleton extends StatelessWidget {
  const TripDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // Dark Hero Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const ShimmerLoading(
                isDark: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back and actions bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBox(width: 38, height: 38, borderRadius: 12, isDark: true),
                        Row(
                          children: [
                            ShimmerBox(width: 38, height: 38, borderRadius: 12, isDark: true),
                            SizedBox(width: 8),
                            ShimmerBox(width: 38, height: 38, borderRadius: 12, isDark: true),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Badge & destination
                    ShimmerBox(width: 88, height: 22, borderRadius: 8, isDark: true),
                    SizedBox(height: 10),
                    ShimmerBox(width: 220, height: 32, borderRadius: 8, isDark: true),
                    SizedBox(height: 8),
                    ShimmerBox(width: 140, height: 16, borderRadius: 6, isDark: true),
                    SizedBox(height: 20),

                    // Quick Stat Chips
                    Row(
                      children: [
                        Expanded(child: ShimmerBox(height: 48, borderRadius: 14, isDark: true)),
                        SizedBox(width: 8),
                        Expanded(child: ShimmerBox(height: 48, borderRadius: 14, isDark: true)),
                        SizedBox(width: 8),
                        Expanded(child: ShimmerBox(height: 48, borderRadius: 14, isDark: true)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Content Sections
            const Padding(
              padding: EdgeInsets.all(20),
              child: ShimmerLoading(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Action Grid
                    Row(
                      children: [
                        Expanded(child: ShimmerBox(height: 72, borderRadius: 16)),
                        SizedBox(width: 12),
                        Expanded(child: ShimmerBox(height: 72, borderRadius: 16)),
                        SizedBox(width: 12),
                        Expanded(child: ShimmerBox(height: 72, borderRadius: 16)),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Big Itinerary card preview
                    ShimmerBox(height: 140, width: double.infinity, borderRadius: 20),
                    SizedBox(height: 16),

                    // Budget card preview
                    ShimmerBox(height: 120, width: double.infinity, borderRadius: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Packing Screen Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class PackingScreenSkeleton extends StatelessWidget {
  const PackingScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // Dark Header Hero with Progress
            Container(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const ShimmerLoading(
                isDark: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBox(width: 38, height: 38, borderRadius: 12, isDark: true),
                        ShimmerBox(width: 120, height: 24, borderRadius: 8, isDark: true),
                        ShimmerBox(width: 38, height: 38, borderRadius: 12, isDark: true),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Progress card
                    ShimmerBox(height: 96, width: double.infinity, borderRadius: 20, isDark: true),
                  ],
                ),
              ),
            ),

            // Category Filter Pills & Items
            Padding(
              padding: const EdgeInsets.all(20),
              child: ShimmerLoading(
                child: Column(
                  children: [
                    // Filter row
                    const Row(
                      children: [
                        ShimmerBox(width: 72, height: 34, borderRadius: 12),
                        SizedBox(width: 8),
                        ShimmerBox(width: 84, height: 34, borderRadius: 12),
                        SizedBox(width: 8),
                        ShimmerBox(width: 90, height: 34, borderRadius: 12),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Item rows
                    ...List.generate(
                      5,
                      (_) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: const ShimmerBox(height: 64, width: double.infinity, borderRadius: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Members Screen Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class MembersScreenSkeleton extends StatelessWidget {
  const MembersScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // Dark Header Hero
            Container(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const ShimmerLoading(
                isDark: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBox(width: 38, height: 38, borderRadius: 12, isDark: true),
                        ShimmerBox(width: 140, height: 24, borderRadius: 8, isDark: true),
                        ShimmerBox(width: 38, height: 38, borderRadius: 12, isDark: true),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Invite Code Card
                    ShimmerBox(height: 90, width: double.infinity, borderRadius: 20, isDark: true),
                  ],
                ),
              ),
            ),

            // Members List
            Padding(
              padding: const EdgeInsets.all(20),
              child: ShimmerLoading(
                child: Column(
                  children: List.generate(
                    4,
                    (_) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: const ShimmerBox(height: 72, width: double.infinity, borderRadius: 18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Friends List Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class FriendsListSkeleton extends StatelessWidget {
  final int count;
  const FriendsListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: count,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Row(
            children: [
              ShimmerBox.circle(size: 44),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 120, height: 14, borderRadius: 6),
                    SizedBox(height: 6),
                    ShimmerBox(width: 160, height: 11, borderRadius: 6),
                  ],
                ),
              ),
              ShimmerBox(width: 32, height: 32, borderRadius: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity List Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class ActivityListSkeleton extends StatelessWidget {
  final int count;
  const ActivityListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        itemCount: count,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox.circle(size: 36),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 180, height: 14, borderRadius: 6),
                    SizedBox(height: 6),
                    ShimmerBox(width: 220, height: 12, borderRadius: 6),
                    SizedBox(height: 6),
                    ShimmerBox(width: 80, height: 10, borderRadius: 4),
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
