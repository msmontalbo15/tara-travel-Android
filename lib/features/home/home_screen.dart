import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/models/trip_model.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/packing_provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/providers/itinerary_provider.dart';
import '../../core/providers/trip_action_changes_provider.dart';
import '../../core/services/module_view_tracker_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_responsive.dart';
import '../../core/widgets/app_brand_logo.dart';
import '../../core/widgets/navigation/floating_nav_bar.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/utils/jit_guard.dart';
import '../../core/utils/trip_conflict_helper.dart';

import '../budget/budget_screen.dart';
import '../explore/explore_screen.dart';
import '../profile/profile_screen.dart';
import '../trips/trips_screen.dart';
import 'home_route_args.dart';
import 'widgets/next_trip_card.dart';
import 'widgets/quick_action_tile.dart';
import 'widgets/trip_card.dart';
import 'widgets/trip_action_sheet.dart';
import 'widgets/quick_budget_sheet.dart';
import 'widgets/empty_trip_hero_card.dart';
import 'widgets/starter_templates_carousel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;
  bool _didReadRouteArgs = false;
  bool _startTour = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      SizedBox.shrink(),
      TripsScreen(),
      BudgetScreen(),
      ExploreScreen(),
      ProfileScreen(),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadRouteArgs) return;
    _didReadRouteArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is HomeRouteArgs) {
      _startTour = args.startTour;
      if (args.initialIndex != 0) {
        _navIndex = args.initialIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _navIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _navIndex != 0) {
          setState(() => _navIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceLight,
        body: Stack(
          children: [
            IndexedStack(
              index: _navIndex,
              children: [
                _HomeBody(
                  startTour: _startTour,
                  onTourConsumed: () {
                    if (_startTour) {
                      setState(() => _startTour = false);
                    }
                  },
                ),
                ..._pages.skip(1),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingNavBar(
                currentIndex: _navIndex,
                onItemSelected: (index) => setState(() => _navIndex = index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerStatefulWidget {
  final bool startTour;
  final VoidCallback onTourConsumed;

  const _HomeBody({
    required this.startTour,
    required this.onTourConsumed,
  });

  @override
  ConsumerState<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<_HomeBody> {
  bool _tourVisible = false;
  bool _tourScheduled = false;
  int _tourStep = 0;
  final ScrollController _scrollCtrl = ScrollController();
  bool _cardCollapsed = false;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
    if (widget.startTour) {
      _scheduleTour();
    }
    _scrollCtrl.addListener(() {
      final collapsed = _scrollCtrl.offset > 60;
      if (collapsed != _cardCollapsed) {
        setState(() => _cardCollapsed = collapsed);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _HomeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startTour && !_tourVisible && !_tourScheduled) {
      _scheduleTour();
    }
  }

  void _scheduleTour() {
    _tourScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _tourVisible = true;
        _tourStep = 0;
        _tourScheduled = false;
      });
      widget.onTourConsumed();
    });
  }

  void _dismissTour() {
    if (!_tourVisible) return;
    setState(() => _tourVisible = false);
  }

  void _advanceTour() {
    if (_tourStep >= _tourSteps.length - 1) {
      _dismissTour();
      return;
    }
    setState(() => _tourStep += 1);
  }

  Widget _buildAvatar(ProfileState profile) {
    final photoUrl = profile.profilePhotoUrl;
    Widget? imageWidget;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        imageWidget = CachedNetworkImage(
          imageUrl: photoUrl,
          fit: BoxFit.cover,
          width: 42,
          height: 42,
          errorWidget: (_, __, ___) => _initialsAvatar(profile),
        );
      } else {
        final file = File(photoUrl);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            fit: BoxFit.cover,
            width: 42,
            height: 42,
            errorBuilder: (_, __, ___) => _initialsAvatar(profile),
          );
        }
      }
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: imageWidget ?? _initialsAvatar(profile),
      ),
    );
  }

  Widget _initialsAvatar(ProfileState profile) {
    return Container(
      color: profile.avatarColor,
      alignment: Alignment.center,
      child: profile.initials.isNotEmpty
          ? Text(
              profile.initials,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.person_rounded,
              size: 20,
              color: Colors.white,
            ),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isProfileIncomplete =
        profile.homeCity.isEmpty || (profile.gcashNumber == null || profile.gcashNumber!.isEmpty);
    final unreadCount = isProfileIncomplete ? 1 : 0;

    final activeTripAsync = ref.watch(activeTripProvider);
    final trip = activeTripAsync.value;
    final String packedPct;
    if (trip != null) {
      final packing = ref.watch(ref.watch(packingProvider(trip.id)));
      packedPct = (packing.overallProgress * 100).toStringAsFixed(0);
    } else {
      packedPct = '0';
    }

    final topPadding = context.topInset;

    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allTripsProvider);
              ref.invalidate(activeTripProvider);
              ref.invalidate(profileProvider);
            },
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeHeaderDelegate(
                    profile: profile,
                    activeTrip: trip,
                    isLoadingTrip: activeTripAsync.isLoading,
                    tripError: activeTripAsync.error?.toString(),
                    unreadCount: unreadCount,
                    topPadding: topPadding,
                    tourVisible: _tourVisible,
                    tourStep: _tourStep,
                    greeting: _greeting(),
                    buildAvatar: _buildAvatar,
                    onTapTrip: trip == null ? null : () { ref.read(selectedTripIdProvider.notifier).select(trip.id); Navigator.pushNamed(context, '/trip-detail'); },
                    onNavigateTrip: trip == null ? null : () { ref.read(selectedTripIdProvider.notifier).select(trip.id); Navigator.pushNamed(context, '/navigation'); },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ref.watch(allTripsProvider).when(
                                data: (trips) {
                                  // Exclude archived trips from the homepage
                                  final visibleTrips = trips.where((t) => !t.isArchived).toList();
                                  if (visibleTrips.isEmpty) {
                                    return const StarterTemplatesCarousel();
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _TourFocus(
                                        highlight:
                                            _tourVisible && _tourStep == 1,
                                        borderRadius: 22,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Your trips',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => Navigator.pushNamed(
                                                  context, '/trips'),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.sand,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  'See all',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                          Column(
                                            children: visibleTrips.map(
                                              (trip) {
                                                final String dateRangeStr;
                                                if (trip.fromDate.year == trip.toDate.year) {
                                                  if (trip.fromDate.month == trip.toDate.month) {
                                                    dateRangeStr =
                                                        '${DateFormat('MMM d').format(trip.fromDate)}–${trip.toDate.day}, ${trip.toDate.year}';
                                                  } else {
                                                    dateRangeStr =
                                                        '${DateFormat('MMM d').format(trip.fromDate)} – ${DateFormat('MMM d').format(trip.toDate)}, ${trip.toDate.year}';
                                                  }
                                                } else {
                                                  dateRangeStr =
                                                      '${DateFormat('MMM d, yyyy').format(trip.fromDate)} – ${DateFormat('MMM d, yyyy').format(trip.toDate)}';
                                                }

                                                // Detect schedule overlap with other visible trips
                                                final conflicts = TripConflictHelper.findConflictingTrips(
                                                  trips: visibleTrips,
                                                  start: trip.fromDate,
                                                  end: trip.toDate,
                                                  excludeTripId: trip.id,
                                                );
                                                final overlappingTripName = conflicts.isNotEmpty ? conflicts.first.name : null;

                                                if (trip.isDraft) {
                                                  return TripCard.draft(
                                                    name: trip.name,
                                                    destination: trip.destination.isNotEmpty ? trip.destination : null,
                                                    isIncomplete: trip.isIncomplete,
                                                    dateRange: dateRangeStr,
                                                    overlappingTripName: overlappingTripName,
                                                    onMore: () => TripActionSheet.show(context, ref, trip),
                                                    onTap: () {
                                                      ref
                                                          .read(selectedTripIdProvider
                                                              .notifier)
                                                          .select(trip.id);
                                                      Navigator.pushNamed(
                                                          context, '/trip-detail');
                                                    },
                                                  );
                                                }

                                                return _HomeTripCardItem(
                                                  trip: trip,
                                                  dateRange: dateRangeStr,
                                                  overlappingTripName: overlappingTripName,
                                                );
                                              },
                                            ).toList(),
                                          ),
                                        const SizedBox(height: 20),
                                      ],
                                    );
                                  },
                                  loading: () =>
                                      const TripsListSkeleton(count: 2),
                                  error: (error, _) =>
                                      Text('Error loading trips: $error'),
                                ),
                            _TourFocus(
                              highlight: _tourVisible && _tourStep == 2,
                              borderRadius: 22,
                              child: const Text(
                                'Quick actions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.52,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                QuickActionTile(
                                  icon: Icons.add_rounded,
                                  label: 'New trip',
                                  sublabel: 'Start planning',
                                  orange: true,
                                  onTap: () async {
                                    final canProceed = await JitGuard.checkCreateTripGuard(context, ref);
                                    if (!canProceed || !context.mounted) return;
                                    ref
                                        .read(profileProvider.notifier)
                                        .setFirstRunCompleted();
                                    Navigator.pushNamed(
                                      context,
                                      '/create-trip',
                                    );
                                  },
                                ),
                                QuickActionTile(
                                  icon: Icons.person_add_outlined,
                                  label: 'Invite',
                                  sublabel: 'Plan together',
                                  onTap: () async {
                                    final activeTrip = await ref
                                        .read(activeTripProvider.future);
                                    if (activeTrip != null) {
                                      ref
                                          .read(selectedTripIdProvider.notifier)
                                          .select(activeTrip.id);
                                    }
                                    if (context.mounted) {
                                      Navigator.pushNamed(context, '/members');
                                    }
                                  },
                                ),
                                QuickActionTile(
                                  icon: Icons.receipt_long_outlined,
                                  label: 'Split bill',
                                  sublabel: 'Settle fast',
                                  onTap: () async {
                                    final canProceed = await JitGuard.checkExpensePaymentGuard(context, ref);
                                    if (!canProceed || !context.mounted) return;
                                    final activeTrip = await ref
                                        .read(activeTripProvider.future);
                                    if (activeTrip != null) {
                                      ref
                                          .read(selectedTripIdProvider.notifier)
                                          .select(activeTrip.id);
                                    }
                                    if (context.mounted) {
                                      Navigator.pushNamed(context, '/budget');
                                    }
                                  },
                                ),
                                QuickActionTile(
                                  icon: Icons.checklist_rounded,
                                  label: 'Packing',
                                  sublabel: '$packedPct% packed',
                                  onTap: () async {
                                    final activeTrip = await ref
                                        .read(activeTripProvider.future);
                                    if (activeTrip != null) {
                                      ref
                                          .read(selectedTripIdProvider.notifier)
                                          .select(activeTrip.id);
                                    }
                                    if (context.mounted) {
                                      Navigator.pushNamed(context, '/packing');
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 140),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_tourVisible)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.42),
                ),
              ),
            ),
          if (_tourVisible)
            Positioned(
              left: 20,
              right: 20,
              top: _tourStep == 0 ? 106 : null,
              bottom: _tourStep == 0 ? null : 36,
              child: SafeArea(
                child: Align(
                  alignment: _tourStep == 0
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  child: _TourCard(
                    step: _tourStep + 1,
                    totalSteps: _tourSteps.length,
                    title: _tourSteps[_tourStep].title,
                    description: _tourSteps[_tourStep].description,
                    actionLabel:
                        _tourStep == _tourSteps.length - 1 ? 'Done' : 'Next',
                    onSkip: _dismissTour,
                    onNext: _advanceTour,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TourFocus extends StatelessWidget {
  final Widget child;
  final bool highlight;
  final double borderRadius;

  const _TourFocus({
    required this.child,
    required this.highlight,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (!highlight) return child;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.primaryLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TourCard extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _TourCard({
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.deepEarth,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick tour $step of $totalSteps',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
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

class _PulsingGuide extends StatefulWidget {
  final Widget child;
  final bool active;
  final VoidCallback onTap;

  const _PulsingGuide({
    required this.child,
    required this.active,
    required this.onTap,
  });

  @override
  State<_PulsingGuide> createState() => _PulsingGuideState();
}

class _PulsingGuideState extends State<_PulsingGuide>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    if (widget.active) {
      _pulseCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat();
    } else if (!widget.active && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: (1.0 - _pulseAnim.value).clamp(0.0, 1.0),
                      ),
                      width: 2.5 * _pulseAnim.value + 0.5,
                    ),
                  ),
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _TourStep {
  final String title;
  final String description;

  const _TourStep({
    required this.title,
    required this.description,
  });
}

const List<_TourStep> _tourSteps = [
  _TourStep(
    title: 'This is your travel hub',
    description:
        'Home is where you can check your next trip, keep an eye on updates, and jump back into planning fast.',
  ),
  _TourStep(
    title: 'Your trips stay together here',
    description:
        'Upcoming adventures and drafts live in one place, so reopening a plan feels quick and obvious.',
  ),
  _TourStep(
    title: 'Quick actions save taps',
    description:
        'Use these shortcuts to invite your group, manage budgets, and keep packing on track without hunting through menus.',
  ),
  _TourStep(
    title: 'Start with New trip',
    description:
        'When you are ready, tap New trip to create your plan, add travelers, and begin organizing everything in one flow.',
  ),
];

// ── Name Loading Shimmer ─────────────────────────────────────────────────────
// Shown in place of the user's name while the profile is still being fetched.

class _NameLoadingShimmer extends StatelessWidget {
  const _NameLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading(
      isDark: true,
      child: ShimmerBox(
        width: 140,
        height: 26,
        borderRadius: 6,
        isDark: true,
      ),
    );
  }
}

// ── Pinned Collapsible Home Header Delegate ──────────────────────────────────

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ProfileState profile;
  final TripModel? activeTrip;
  final bool isLoadingTrip;
  final String? tripError;
  final int unreadCount;
  final double topPadding;
  final bool tourVisible;
  final int tourStep;
  final String greeting;
  final Widget Function(ProfileState) buildAvatar;
  final VoidCallback? onTapTrip;
  final VoidCallback? onNavigateTrip;

  const _HomeHeaderDelegate({
    required this.profile,
    required this.activeTrip,
    required this.isLoadingTrip,
    this.tripError,
    required this.unreadCount,
    required this.topPadding,
    required this.tourVisible,
    required this.tourStep,
    required this.greeting,
    required this.buildAvatar,
    this.onTapTrip,
    this.onNavigateTrip,
  });

  @override
  double get minExtent {
    if (activeTrip == null && !isLoadingTrip) {
      // Fixed header + full empty hero card height
      return topPadding + 290.0;
    }
    return topPadding + 215.0;
  }

  @override
  double get maxExtent {
    if (activeTrip == null && !isLoadingTrip) {
      // Same as minExtent — hero card is non-collapsible
      return topPadding + 290.0;
    }
    return topPadding + 348.0;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final isCollapsed = t > 0.25;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A04), Color(0xFF2C1A14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brand Bar & Action Buttons ──────────────────────────
          _TourFocus(
            highlight: tourVisible && tourStep == 0,
            borderRadius: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppBrandLogo(
                  size: 32,
                  showWordmark: true,
                  isDark: true,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Friends',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(context, '/friends'),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: const Icon(Icons.people_outline,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Notifications',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              Navigator.pushNamed(context, '/notifications'),
                          customBorder: const CircleBorder(),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 20),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.elasticOut,
                                    builder: (context, scale, child) {
                                      return Transform.scale(
                                          scale: scale, child: child);
                                    },
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.deepEarth,
                                            width: 2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$unreadCount',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
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
                    Tooltip(
                      message: 'Profile',
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: Semantics(
                          label: profile.displayNameForHome.isNotEmpty
                              ? 'User avatar, ${profile.displayNameForHome}'
                              : 'User avatar',
                          child: buildAvatar(profile),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ── Greeting & Name ────────────────────────────────────
          Text(
            greeting,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: profile.displayNameForHome.isEmpty
                ? const _NameLoadingShimmer(key: ValueKey('shimmer'))
                : Text(
                    profile.displayNameForHome,
                    key: ValueKey(profile.displayNameForHome),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontHeading,
                      fontFamilyFallback: AppTextStyles.serifFallbacks,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          // ── Next Trip / Empty Hero Section ─────────────────────
          if (activeTrip != null) ...[
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: NextTripCard(
                      trip: activeTrip!,
                      collapsed: isCollapsed,
                      onTap: onTapTrip,
                      onNavigation: onNavigateTrip,
                    ),
                  ),
                ),
              ),
            ),
          ] else if (isLoadingTrip) ...[
            const SizedBox(height: 12),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: NextTripCardSkeleton(),
              ),
            ),
          ] else ...[
            // No active trip — show the glassmorphic hero card
            const SizedBox(height: 12),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: EmptyTripHeroCard(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return oldDelegate.profile != profile ||
        oldDelegate.activeTrip != activeTrip ||
        oldDelegate.isLoadingTrip != isLoadingTrip ||
        oldDelegate.tripError != tripError ||
        oldDelegate.unreadCount != unreadCount ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.tourVisible != tourVisible ||
        oldDelegate.tourStep != tourStep ||
        oldDelegate.greeting != greeting;
  }
}

class _HomeTripCardItem extends ConsumerWidget {
  final TripModel trip;
  final String dateRange;
  final String? overlappingTripName;

  const _HomeTripCardItem({
    required this.trip,
    required this.dateRange,
    this.overlappingTripName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryAsync = ref.watch(ref.watch(itineraryProvider(trip.id)));
    final itineraryState = itineraryAsync.value;

    int totalStops = 0;
    int visitedStops = 0;

    if (itineraryState != null) {
      for (final day in itineraryState.days) {
        totalStops += day.stops.length;
        for (final stop in day.stops) {
          if (stop.isCompleted) {
            visitedStops++;
          }
        }
      }
    }

    final actionChangesAsync = ref.watch(tripQuickActionChangesProvider(trip));
    final actionChanges = actionChangesAsync.value;

    return TripCard.upcoming(
      name: trip.name,
      destination: trip.destination,
      tripId: trip.id,
      isIncomplete: trip.isIncomplete,
      dateRange: dateRange,
      budget: 'P${(trip.totalBudget / 1000).toStringAsFixed(0)}k',
      totalBudget: trip.totalBudget,
      totalSpent: trip.totalSpent,
      days: trip.toDate.difference(trip.fromDate).inDays + 1,
      people: trip.members.length,
      visitedStops: visitedStops,
      totalStops: totalStops,
      tripType: trip.tripType,
      coverColor: trip.coverColor,
      coverEmoji: trip.coverEmoji,
      actionChanges: actionChanges,
      overlappingTripName: overlappingTripName,
      onMore: () => TripActionSheet.show(context, ref, trip),
      onTap: () {
        ref.read(selectedTripIdProvider.notifier).select(trip.id);
        Navigator.pushNamed(context, '/trip-detail');
      },
      onItinerary: () async {
        await ModuleViewTrackerService.instance.markViewed('itinerary', trip.id);
        ref.invalidate(tripQuickActionChangesProvider(trip));
        ref.read(selectedTripIdProvider.notifier).select(trip.id);
        if (context.mounted) Navigator.pushNamed(context, '/itinerary');
      },
      onPacking: () async {
        await ModuleViewTrackerService.instance.markViewed('packing', trip.id);
        ref.invalidate(tripQuickActionChangesProvider(trip));
        ref.read(selectedTripIdProvider.notifier).select(trip.id);
        if (context.mounted) Navigator.pushNamed(context, '/packing');
      },
      onMembers: () async {
        await ModuleViewTrackerService.instance.markViewed('members', trip.id);
        ref.invalidate(tripQuickActionChangesProvider(trip));
        ref.read(selectedTripIdProvider.notifier).select(trip.id);
        if (context.mounted) Navigator.pushNamed(context, '/members');
      },
      onExpenses: () async {
        await ModuleViewTrackerService.instance.markViewed('expenses', trip.id);
        ref.invalidate(tripQuickActionChangesProvider(trip));
        ref.read(selectedTripIdProvider.notifier).select(trip.id);
        if (context.mounted) Navigator.pushNamed(context, '/budget');
      },
      onBudgetTap: () async {
        await ModuleViewTrackerService.instance.markViewed('expenses', trip.id);
        ref.invalidate(tripQuickActionChangesProvider(trip));
        ref.read(selectedTripIdProvider.notifier).select(trip.id);
        if (context.mounted) Navigator.pushNamed(context, '/budget');
      },
      onSetBudget: () {
        QuickBudgetSheet.show(context, trip);
      },
      onChat: () async {
        await ModuleViewTrackerService.instance.markViewed('chat', trip.id);
        ref.invalidate(tripQuickActionChangesProvider(trip));
        ref.read(selectedTripIdProvider.notifier).select(trip.id);
        if (context.mounted) Navigator.pushNamed(context, '/chat');
      },
      onNavigation: () {
        ref.read(selectedTripIdProvider.notifier).select(trip.id);
        Navigator.pushNamed(context, '/navigation');
      },
    );
  }
}

