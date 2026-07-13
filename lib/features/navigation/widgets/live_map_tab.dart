import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/navigation_models.dart';
import '../providers/navigation_provider.dart';
import 'shared/member_avatar.dart';
import 'shared/mock_map_painter.dart';

class LiveMapTab extends ConsumerStatefulWidget {
  const LiveMapTab({super.key});

  @override
  ConsumerState<LiveMapTab> createState() => _LiveMapTabState();
}

class _LiveMapTabState extends ConsumerState<LiveMapTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _routeController;

  @override
  void initState() {
    super.initState();
    _routeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _routeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider);
    final notifier = ref.read(navigationProvider.notifier);

    return Column(
      children: [
        // ── MAP AREA ──────────────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              // Map background
              AnimatedBuilder(
                animation: _routeController,
                builder: (_, __) => CustomPaint(
                  painter: MockMapPainter(
                    showRoute: true,
                    animationValue: _routeController.value,
                  ),
                  size: Size.infinite,
                ),
              ),

              // Member pins
              ..._buildMemberPins(nav),

              // Destination pin
              _DestinationPin(name: nav.destination.name),

              // LIVE badge
              Positioned(
                top: 16,
                left: 14,
                child: _MapBadge(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BlinkingDot(),
                      const SizedBox(width: 5),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Group view toggle
              Positioned(
                top: 46,
                left: 14,
                child: GestureDetector(
                  onTap: notifier.toggleGroupView,
                  child: _MapBadge(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 5),
                        Text(
                          'Group view ${nav.isGroupViewOn ? 'ON' : 'OFF'}',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Map controls (right)
              const Positioned(
                top: 16,
                right: 12,
                child: Column(
                  children: [
                    _MapControl(icon: Icons.my_location_rounded, color: AppColors.primary),
                    SizedBox(height: 6),
                    _MapControl(icon: Icons.add_rounded, color: AppColors.textPrimary),
                    SizedBox(height: 6),
                    _MapControl(icon: Icons.arrow_forward_rounded, color: AppColors.textPrimary),
                  ],
                ),
              ),

              // Scale indicator
              const Positioned(
                bottom: 12,
                left: 14,
                child: _ScaleBar(),
              ),
            ],
          ),
        ),

        // ── TURN-BY-TURN ──────────────────────────────────────
        if (nav.currentTurn != null)
          _TurnCard(turn: nav.currentTurn!),

        // ── BOTTOM STRIP ─────────────────────────────────────
        _BottomStrip(nav: nav),
      ],
    );
  }

  List<Widget> _buildMemberPins(NavigationState nav) {
    return nav.members.map((m) {
      // Calculate pixel position from normalized map coords
      // The map area is 'Expanded', so we use LayoutBuilder below via Positioned.fill
      String label;
      if (m.isMe) {
        return _buildUserPin(m);
      } else if (m.status == MemberStatus.offline) {
        label = 'offline';
      } else if ((m.distanceKm ?? 0) > 0) {
        label = '${m.distanceKm!.abs().toStringAsFixed(1)} km ahead';
      } else {
        label = '${m.distanceKm!.abs().toStringAsFixed(1)} km behind';
      }

      return Positioned(
        // Use approximate positions based on mockup
        left: _mapX(m.mapPosition.dx),
        top: _mapY(m.mapPosition.dy, context),
        child: MapMemberPin(member: m, labelText: label),
      );
    }).toList();
  }

  Widget _buildUserPin(NavMember m) {
    return Positioned(
      left: _mapX(m.mapPosition.dx) - 5,
      top: _mapY(m.mapPosition.dy, context) - 5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Heading cone
          CustomPaint(
            painter: _HeadingConePainter(),
            size: const Size(36, 36),
          ),
          // Pulse ring
          const _PulseRing(color: AppColors.primary),
          // Avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: m.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              m.initials,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _mapX(double normalized) {
    final w = MediaQuery.of(context).size.width;
    return normalized * w;
  }

  double _mapY(double normalized, BuildContext ctx) {
    // Map takes ~60% of screen height
    final screenH = MediaQuery.of(ctx).size.height;
    final mapH = screenH * 0.50;
    return normalized * mapH;
  }
}

// ── Destination pin ─────────────────────────────────────────────
class _DestinationPin extends StatelessWidget {
  final String name;
  const _DestinationPin({required this.name});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 28,
      left: MediaQuery.of(context).size.width * 0.42,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
                bottomLeft: Radius.circular(2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const Text('Destination',
                    style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 9,
                        color: Colors.white60)),
              ],
            ),
          ),
          Container(width: 2, height: 6, color: AppColors.primary),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map badge (semi-transparent pill) ───────────────────────────
class _MapBadge extends StatelessWidget {
  final Widget child;
  const _MapBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

// ── Map control button ───────────────────────────────────────────
class _MapControl extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _MapControl({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

// ── Scale bar ────────────────────────────────────────────────────
class _ScaleBar extends StatelessWidget {
  const _ScaleBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        const Text('500m',
            style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 9,
                color: Colors.white54,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Turn instruction card ────────────────────────────────────────
class _TurnCard extends StatelessWidget {
  final TurnInstruction turn;
  const _TurnCard({required this.turn});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.turn_right_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(turn.distanceLabel,
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: Colors.white54)),
                const SizedBox(height: 2),
                Text(turn.instruction,
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(turn.kmLeft.toStringAsFixed(1),
                  style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const Text('km left',
                  style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      color: Colors.white38)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bottom stats strip ───────────────────────────────────────────
class _BottomStrip extends StatelessWidget {
  final NavigationState nav;
  const _BottomStrip({required this.nav});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatCell(label: 'ETA', value: nav.etaLabel),
          _StatCell(label: 'Distance', value: '${nav.distanceKm.toStringAsFixed(1)} km'),
          _StatCell(label: 'Duration', value: '${nav.durationMin} min'),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('End',
                  style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'DM Sans', fontSize: 10, color: Color(0xFF8E8E93))),
        Text(value,
            style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black)),
      ],
    );
  }
}

// ── Blinking LIVE dot ────────────────────────────────────────────
class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _opacity = Tween(begin: 1.0, end: 0.25).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
            color: Color(0xFF34A853), shape: BoxShape.circle),
      ),
    );
  }
}

// ── Pulse ring ───────────────────────────────────────────────────
class _PulseRing extends StatefulWidget {
  final Color color;
  const _PulseRing({required this.color});

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _scale = Tween(begin: 0.9, end: 1.8).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween(begin: 0.4, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withValues(alpha: _opacity.value),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Heading cone painter ─────────────────────────────────────────
class _HeadingConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height / 2)
      ..lineTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.8, 0)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFD85A30).withValues(alpha: 0.3)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_) => false;
}
