import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'models/navigation_models.dart';
import 'providers/navigation_provider.dart';
import 'widgets/nav_map_view.dart';
import 'widgets/nav_panels.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  @override
  void initState() {
    super.initState();
    // Start navigation on mount for this hi-fi demo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationProvider.notifier).setNavigating(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(navigationProvider);

    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: Stack(
        children: [
          // ── Background (Map or Arrival Feed) ──────────────────
          if (navState.isArrived)
            Positioned.fill(child: SafeArea(child: ArrivalFeedPanel(state: navState)))
          else
            Positioned.fill(child: LiveMapView(state: navState)),

          // ── Map Overlays (Instruction/Top Bar) ───────────────
          if (!navState.isArrived && !navState.isGroupViewOn) ...[
            // Status bar area padding
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(child: _buildTopMapControls(navState)),
            ),

            Positioned(
              top: 100, left: 0, right: 0,
              child: navState.currentTurn != null
                  ? InstructionPanel(turn: navState.currentTurn!)
                  : const SizedBox.shrink(),
            ),
          ],

          // ── Bottom Panels (Stats or Group Sheet) ────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomArea(navState),
          ),
          
          // ── Proximity Alert Overlay ─────────────────────────
          if (navState.isProximityAlertActive && !navState.isArrived)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: ProximityPanel(
                state: navState,
                onDismiss: () => ref.read(navigationProvider.notifier).setProximityAlert(false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopMapControls(NavigationState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18)),
          ),
          const Spacer(),
          // Right controls column
          Column(
            children: [
              _mapButton(Icons.location_on_rounded, col: AppColors.primary),
              const SizedBox(height: 6),
              _mapButton(Icons.add_rounded),
              const SizedBox(height: 6),
              _mapButton(Icons.arrow_forward_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mapButton(IconData icon, {Color? col}) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: col ?? const Color(0xFF333333), size: 16),
    );
  }

  Widget _buildBottomArea(NavigationState state) {
    if (state.isArrived) return const SizedBox.shrink();

    if (state.isGroupViewOn) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: GroupTrackerPanel(
          state: state,
          onBack: () => ref.read(navigationProvider.notifier).toggleGroupView(),
        ),
      );
    }

    // Default: Stats strip
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live/Group toggle pill row
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 10),
          child: Row(
            children: [
              _statusPill('LIVE', const Color(0xFF34A853)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => ref.read(navigationProvider.notifier).toggleGroupView(),
                child: _statusPill('Group view ON', Colors.transparent, icon: Icons.people_outline, showBorder: true),
              ),
            ],
          ),
        ),
        StatsStrip(
          dest: state.destination,
          onEnd: () {
            // Cycle through demo states: Nav -> Proximity -> Arrived
            final notifier = ref.read(navigationProvider.notifier);
            if (!state.isProximityAlertActive && !state.isArrived) {
              notifier.setProximityAlert(true);
            } else if (state.isProximityAlertActive) {
              notifier.setArrived(true);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  Widget _statusPill(String text, Color color, {IconData? icon, bool showBorder = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: showBorder ? Colors.black54 : Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: showBorder ? Border.all(color: Colors.white24) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 5),
          ] else
            Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          if (icon == null) const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
