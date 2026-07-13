import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'models/navigation_models.dart';
import 'providers/navigation_provider.dart';
import 'widgets/live_map_tab.dart';
import 'widgets/group_tracker_tab.dart';
import 'widgets/proximity_alert_tab.dart';
import 'widgets/arrived_tab.dart';

/// Entry point for the Live Navigation feature.
/// Can be pushed via Navigator.push or embedded inside a tab shell.
///
/// Usage:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => const LiveNavigationScreen(),
///   ));
class LiveNavigationScreen extends ConsumerStatefulWidget {
  const LiveNavigationScreen({super.key});

  @override
  ConsumerState<LiveNavigationScreen> createState() =>
      _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends ConsumerState<LiveNavigationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    _TabDef(label: 'Live Map',  icon: Icons.navigation_rounded),
    _TabDef(label: 'Group',     icon: Icons.group_rounded),
    _TabDef(label: 'Proximity', icon: Icons.my_location_rounded),
    _TabDef(label: 'Arrived',   icon: Icons.check_circle_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) return;
    final notifier = ref.read(navigationProvider.notifier);
    switch (_tabController.index) {
      case 2:
        notifier.setProximityAlert(true);
        notifier.setArrived(false);
        break;
      case 3:
        notifier.setArrived(true);
        break;
      default:
        notifier.setProximityAlert(false);
        notifier.setArrived(false);
        break;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    super.dispose();
  }

  bool get _isDarkTab {
    final i = _tabController.index;
    return i == 0 || i == 3; // Live Map + Arrived use dark backgrounds
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDarkTab
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _screenBg(),
        body: Column(
          children: [
            _NavHeader(
              nav: nav,
              tabController: _tabController,
              tabs: _tabs,
              isDark: _isDarkTab,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  LiveMapTab(),
                  GroupTrackerTab(),
                  ProximityAlertTab(),
                  ArrivedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _screenBg() {
    switch (_tabController.index) {
      case 0:
        return const Color(0xFF2D3748);
      case 1:
        return AppColors.background;
      case 2:
        return const Color(0xFF2D3748);
      case 3:
        return AppColors.deepEarth;
      default:
        return AppColors.background;
    }
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _NavHeader extends StatelessWidget {
  final NavigationState nav;
  final TabController tabController;
  final List<_TabDef> tabs;
  final bool isDark;

  const _NavHeader({
    required this.nav,
    required this.tabController,
    required this.tabs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(0, topPad, 0, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepEarth : Colors.white,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                if (Navigator.canPop(context))
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                if (Navigator.canPop(context)) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nav.destination.name,
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _phaseLabel(nav),
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _LiveBadge(isArrived: nav.isArrived, isLive: nav.isNavigating),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: tabController,
            tabs: tabs
                .map((t) => Tab(
                      height: 42,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(t.icon, size: 14),
                          const SizedBox(width: 5),
                          Text(t.label),
                        ],
                      ),
                    ))
                .toList(),
            labelStyle: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            labelColor: AppColors.primary,
            unselectedLabelColor:
                isDark ? Colors.white54 : AppColors.warmMuted,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: isDark ? Colors.white12 : const Color(0xFFE5E5EA),
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }

  String _phaseLabel(NavigationState nav) {
    if (nav.isArrived) return 'Arrived at ${nav.destination.name}';
    if (nav.isProximityAlertActive) return 'Almost there! · 300 m away';
    return 'En route · ${nav.destination.distanceKm.toStringAsFixed(1)} km away';
  }
}

// ── LIVE / Arrived badge ──────────────────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  final bool isArrived;
  final bool isLive;
  const _LiveBadge({required this.isArrived, required this.isLive});

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _fade = Tween(begin: 1.0, end: 0.3).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isArrived) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF34A853).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                color: Color(0xFF34A853), size: 12),
            SizedBox(width: 4),
            Text(
              'Arrived',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF34A853),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _fade,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                  color: Color(0xFF34A853), shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab definition ────────────────────────────────────────────────────────────

class _TabDef {
  final String label;
  final IconData icon;
  const _TabDef({required this.label, required this.icon});
}
