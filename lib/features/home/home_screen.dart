import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/packing_provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/theme/app_colors.dart';
import '../budget/budget_screen.dart';
import '../explore/explore_screen.dart';
import '../profile/profile_screen.dart';
import '../trips/trips_screen.dart';
import 'home_route_args.dart';
import 'widgets/next_trip_card.dart';
import 'widgets/quick_action_tile.dart';
import 'widgets/trip_card.dart';

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
        body: IndexedStack(
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
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.dividerLight, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
            _navItem(1, Icons.luggage_outlined, Icons.luggage_rounded, 'Trips'),
            _navItem(
              2,
              Icons.account_balance_wallet_outlined,
              Icons.account_balance_wallet_rounded,
              'Budget',
            ),
            _navItem(3, Icons.explore_outlined, Icons.explore_rounded, 'Explore'),
            _navItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
  ) {
    final active = _navIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _navIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: active ? AppColors.sand : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                active ? activeIcon : inactiveIcon,
                size: 22,
                color: active ? AppColors.primary : AppColors.warmMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? AppColors.primary : AppColors.warmMuted,
                letterSpacing: 0.2,
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

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    const unreadCount = 0;
    
    final activeTripAsync = ref.watch(activeTripProvider);
    final trip = activeTripAsync.value;
    final String packedPct;
    if (trip != null) {
      final packing = ref.watch(ref.watch(packingProvider(trip.id)));
      packedPct = (packing.overallProgress * 100).toStringAsFixed(0);
    } else {
      packedPct = '0';
    }

    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A0A04), Color(0xFF2C1A14)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    _TourFocus(
                      highlight: _tourVisible && _tourStep == 0,
                      borderRadius: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              Text(
                                profile.firstName,
                                style: const TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/notifications'),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
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
                                        size: 22,
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.deepEarth,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              '$unreadCount',
                                              style: TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: profile.avatarColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      profile.initials,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    ref.watch(activeTripProvider).when(
                      data: (trip) => trip != null
                          ? NextTripCard(trip: trip)
                          : const SizedBox.shrink(),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, _) => Text('Error: $error'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TourFocus(
                            highlight: _tourVisible && _tourStep == 1,
                            borderRadius: 22,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Your trips',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/trips'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.sand,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'See all',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
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
                          ref.watch(allTripsProvider).when(
                            data: (trips) => Column(
                              children: trips
                                  .map(
                                    (trip) => TripCard.upcoming(
                                      name: trip.name,
                                      dateRange:
                                          '${trip.fromDate.month}/${trip.fromDate.day}-${trip.toDate.day}, ${trip.toDate.year}',
                                      budget:
                                          'P${(trip.totalBudget / 1000).toStringAsFixed(0)}k',
                                      days: trip.toDate
                                              .difference(trip.fromDate)
                                              .inDays +
                                          1,
                                      people: trip.members.length,
                                      travelers: trip.members
                                          .map(
                                            (member) => TravelerInfo(
                                              member.initials,
                                              member.color.toARGB32(),
                                            ),
                                          )
                                          .toList(),
                                      onTap: () {
                                        // Set selected trip before navigating
                                        ref
                                            .read(selectedTripIdProvider.notifier)
                                            .select(trip.id);
                                        Navigator.pushNamed(
                                          context,
                                          '/trip-detail',
                                        );
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (error, _) =>
                                Text('Error loading trips: $error'),
                          ),
                          const SizedBox(height: 20),
                          _TourFocus(
                            highlight: _tourVisible && _tourStep == 2,
                            borderRadius: 22,
                            child: const Text(
                              'Quick actions',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
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
                            childAspectRatio: 1.45,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _TourFocus(
                                highlight: _tourVisible && _tourStep == 3,
                                borderRadius: 24,
                                child: _PulsingGuide(
                                  active: profile.isFirstRun ||
                                      (_tourVisible && _tourStep == 3),
                                  onTap: () {
                                    ref
                                        .read(profileProvider.notifier)
                                        .setFirstRunCompleted();
                                    Navigator.pushNamed(
                                      context,
                                      '/create-trip',
                                    );
                                  },
                                  child: QuickActionTile(
                                    icon: Icons.add_rounded,
                                    label: 'New trip',
                                    sublabel: 'Start planning',
                                    orange: true,
                                    onTap: () {
                                      ref
                                          .read(profileProvider.notifier)
                                          .setFirstRunCompleted();
                                      Navigator.pushNamed(
                                        context,
                                        '/create-trip',
                                      );
                                    },
                                  ),
                                ),
                              ),
                              QuickActionTile(
                                icon: Icons.person_add_outlined,
                                label: 'Invite',
                                sublabel: 'Plan together',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/members'),
                              ),
                              QuickActionTile(
                                icon: Icons.receipt_long_outlined,
                                label: 'Split bill',
                                sublabel: 'Settle fast',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/budget'),
                              ),
                              QuickActionTile(
                                icon: Icons.checklist_rounded,
                                label: 'Packing',
                                sublabel: '$packedPct% packed',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/packing'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
                    actionLabel: _tourStep == _tourSteps.length - 1
                        ? 'Done'
                        : 'Next',
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
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Playfair Display',
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
                fontFamily: 'DM Sans',
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
                      fontFamily: 'DM Sans',
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
                      fontFamily: 'DM Sans',
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
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return Container(
                width: 140,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(
                      alpha: 1.0 - _pulseAnim.value,
                    ),
                    width: 4 * _pulseAnim.value,
                  ),
                ),
              );
            },
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
