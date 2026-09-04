import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/map_tile_config.dart';
import '../../../core/theme/app_colors.dart';
import '../models/navigation_models.dart';
import '../providers/navigation_provider.dart';
import 'convoy_alert_banner.dart';
import 'navigate_to_member_sheet.dart';
import 'privacy_control_sheet.dart';
import 'sos_emergency_modal.dart';

class LiveMapTab extends ConsumerStatefulWidget {
  const LiveMapTab({super.key});

  @override
  ConsumerState<LiveMapTab> createState() => _LiveMapTabState();
}

class _LiveMapTabState extends ConsumerState<LiveMapTab> {
  final MapController _mapController = MapController();
  bool _didFitInitialBounds = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitGroupBounds();
    });
  }

  void _centerOnMe() {
    final nav = ref.read(navigationProvider);
    final me = nav.members.firstWhere((m) => m.isMe, orElse: () => nav.members.first);
    if (me.latitude != null && me.longitude != null) {
      _mapController.move(LatLng(me.latitude!, me.longitude!), 15.5);
      HapticFeedback.selectionClick();
    }
  }

  void _fitGroupBounds() {
    final nav = ref.read(navigationProvider);
    final points = <LatLng>[];

    for (final m in nav.members) {
      if (m.latitude != null && m.longitude != null) {
        points.add(LatLng(m.latitude!, m.longitude!));
      }
    }

    if (nav.destination.latitude != null && nav.destination.longitude != null) {
      points.add(LatLng(nav.destination.latitude!, nav.destination.longitude!));
    }

    if (points.isEmpty) {
      // Default fallback (Manila coordinates)
      _mapController.move(const LatLng(14.5995, 120.9842), 14);
      return;
    }

    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(56),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider);
    final notifier = ref.read(navigationProvider.notifier);

    final me = nav.members.firstWhere(
      (m) => m.isMe,
      orElse: () => const NavMember(
        id: 'me',
        name: 'You',
        initials: 'Y',
        color: AppColors.primary,
        status: MemberStatus.enRoute,
        role: 'You',
        isMe: true,
        latitude: 14.5995,
        longitude: 120.9842,
      ),
    );

    final myLatLng = LatLng(
      me.latitude ?? 14.5995,
      me.longitude ?? 120.9842,
    );

    final destLatLng = LatLng(
      nav.destination.latitude ?? (myLatLng.latitude + 0.02),
      nav.destination.longitude ?? (myLatLng.longitude + 0.015),
    );

    // Dynamic route points for polyline
    final List<LatLng> routePoints = [myLatLng];
    if (nav.activeMemberRoute != null &&
        nav.activeMemberRoute!.latitude != null &&
        nav.activeMemberRoute!.longitude != null) {
      routePoints.add(LatLng(
        nav.activeMemberRoute!.latitude!,
        nav.activeMemberRoute!.longitude!,
      ));
    } else {
      routePoints.add(destLatLng);
    }

    if (!_didFitInitialBounds && nav.members.isNotEmpty) {
      _didFitInitialBounds = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitGroupBounds());
    }

    return Column(
      children: [
        // ── ACTIVE SOS BEACON BANNER ──────────────────────────
        const ActiveSosAlertBanner(),

        // ── CONVOY SEPARATION ALERTS ──────────────────────────
        const ConvoyAlertBanner(),

        // ── INTERACTIVE MAP AREA ──────────────────────────────
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: myLatLng,
                  initialZoom: 14.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  // ── Map Tile Layer (Mapbox Streets / CartoDB Voyager) ──
                  MapTileConfig.buildTileLayer(),

                  // ── Live Routing Polyline ───────────────────────────
                  if (routePoints.length > 1)
                    PolylineLayer(
                      polylines: [
                        // Ambient glow stroke
                        Polyline(
                          points: routePoints,
                          color: AppColors.primary.withValues(alpha: 0.35),
                          strokeWidth: 9,
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                        ),
                        // Sharp inner route line
                        Polyline(
                          points: routePoints,
                          color: AppColors.primary,
                          strokeWidth: 4.5,
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                        ),
                      ],
                    ),

                  // ── Real Marker Layer ───────────────────────────────
                  MarkerLayer(
                    markers: [
                      // 1. Destination Marker
                      Marker(
                        point: destLatLng,
                        width: 140,
                        height: 60,
                        alignment: Alignment.topCenter,
                        child: _RealDestinationMarker(
                          name: nav.destination.name,
                          eta: nav.destination.eta,
                        ),
                      ),

                      // 2. Active SOS Panic Marker (if active)
                      if (nav.activeSos != null)
                        Marker(
                          point: LatLng(nav.activeSos!.lat, nav.activeSos!.lng),
                          width: 80,
                          height: 80,
                          child: _RealSosMarker(beacon: nav.activeSos!),
                        ),

                      // 3. Companion Markers (from real Supabase members)
                      ...nav.members.where((m) => !m.isMe).map((m) {
                        final lat = m.latitude ?? (myLatLng.latitude + (m.id.hashCode % 100 - 50) * 0.0003);
                        final lng = m.longitude ?? (myLatLng.longitude + (m.id.hashCode % 90 - 45) * 0.0003);

                        return Marker(
                          point: LatLng(lat, lng),
                          width: 60,
                          height: 70,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              NavigateToMemberSheet.show(context, m);
                            },
                            child: _RealPeerMarker(member: m),
                          ),
                        );
                      }),

                      // 4. Local User Marker ('Me')
                      Marker(
                        point: myLatLng,
                        width: 70,
                        height: 70,
                        alignment: Alignment.center,
                        child: _RealUserMarker(
                          member: me,
                          isGhost: nav.isGhostActive,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── LIVE & PRIVACY BADGES (Top Left) ─────────────────
              Positioned(
                top: 16,
                left: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MapBadge(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BlinkingDot(),
                          const SizedBox(width: 5),
                          Text(
                            nav.isGhostActive ? 'GHOST MODE' : 'LIVE GPS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: nav.isGhostActive
                                  ? const Color(0xFFEF9F27)
                                  : Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        notifier.toggleGroupView();
                        _fitGroupBounds();
                      },
                      child: _MapBadge(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.group_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 5),
                            Text(
                              'Group view ${nav.isGroupViewOn ? 'ON' : 'OFF'}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (nav.activeMemberRoute != null) ...[
                      const SizedBox(height: 6),
                      _MapBadge(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.navigation_rounded,
                                color: AppColors.amber, size: 12),
                            const SizedBox(width: 5),
                            Text(
                              'Navigating to ${nav.activeMemberRoute!.name}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: notifier.cancelMemberNavigation,
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white70, size: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── MAP CONTROLS (Top Right) ─────────────────────────
              Positioned(
                top: 16,
                right: 12,
                child: Column(
                  children: [
                    // Center My GPS
                    GestureDetector(
                      onTap: _centerOnMe,
                      child: const _MapControl(
                        icon: Icons.my_location_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Fit Group Bounds
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _fitGroupBounds();
                      },
                      child: const _MapControl(
                        icon: Icons.fullscreen_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Zoom In
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
                        );
                      },
                      child: const _MapControl(
                        icon: Icons.add_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Zoom Out
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
                        );
                      },
                      child: const _MapControl(
                        icon: Icons.remove_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Privacy Control Sheet
                    GestureDetector(
                      onTap: () => PrivacyControlSheet.show(context),
                      child: _MapControl(
                        icon: nav.isGhostActive
                            ? Icons.visibility_off_rounded
                            : Icons.shield_outlined,
                        color: nav.isGhostActive
                            ? const Color(0xFFEF9F27)
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // SOS Emergency Modal
                    GestureDetector(
                      onTap: () => SosEmergencyModal.show(context),
                      child: const _MapControl(
                        icon: Icons.sos_rounded,
                        color: Color(0xFFE24A4A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── TURN-BY-TURN CARD ─────────────────────────────────
        if (nav.currentTurn != null)
          _TurnCard(
            turn: nav.currentTurn!,
            destination: nav.destination,
          ),

        // ── BOTTOM STATS STRIP ────────────────────────────────
        _BottomStrip(nav: nav),
      ],
    );
  }
}

// ── Real Destination Marker ───────────────────────────────────────────
class _RealDestinationMarker extends StatelessWidget {
  final String name;
  final String eta;

  const _RealDestinationMarker({
    required this.name,
    required this.eta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.deepEarth,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'ETA $eta',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.sand,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 24),
      ],
    );
  }
}

// ── Real Peer Marker ──────────────────────────────────────────────────
class _RealPeerMarker extends StatelessWidget {
  final NavMember member;

  const _RealPeerMarker({required this.member});

  @override
  Widget build(BuildContext context) {
    final statusColor = member.status == MemberStatus.enRoute
        ? const Color(0xFF10B981)
        : (member.status == MemberStatus.arrived
            ? const Color(0xFF3B82F6)
            : AppColors.warmMuted);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            member.name.split(' ').first,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: member.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                member.initials,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Real Local User Marker ────────────────────────────────────────────
class _RealUserMarker extends StatelessWidget {
  final NavMember member;
  final bool isGhost;

  const _RealUserMarker({
    required this.member,
    required this.isGhost,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Heading Direction Cone
        if (member.heading != null && member.heading! > 0)
          Transform.rotate(
            angle: (member.heading! * math.pi) / 180,
            child: CustomPaint(
              painter: _HeadingConePainter(),
              size: const Size(48, 48),
            ),
          ),
        // Pulse ripple
        _PulseRing(color: isGhost ? AppColors.amber : AppColors.primary),
        // Center Avatar
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: member.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            member.initials,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Real SOS Marker ───────────────────────────────────────────────────
class _RealSosMarker extends StatelessWidget {
  final SosBeacon beacon;

  const _RealSosMarker({required this.beacon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const _PulseRing(color: Color(0xFFDC2626)),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.sos_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

// ── Badges & Buttons ──────────────────────────────────────────────────
class _MapBadge extends StatelessWidget {
  final Widget child;
  const _MapBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: child,
    );
  }
}

class _MapControl extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _MapControl({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

// ── Turn instruction card & Driver Quick Action ─────────────────────────────
class _TurnCard extends StatelessWidget {
  final TurnInstruction turn;
  final NavDestination? destination;

  const _TurnCard({required this.turn, this.destination});

  Future<void> _openExternalTurnByTurn(BuildContext context) async {
    HapticFeedback.heavyImpact();
    if (destination != null &&
        destination!.latitude != null &&
        destination!.longitude != null) {
      final lat = destination!.latitude!;
      final lng = destination!.longitude!;
      final uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
      final webFallback = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');

      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}

      try {
        await launchUrl(webFallback, mode: LaunchMode.externalApplication);
      } catch (_) {
        await launchUrl(webFallback);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.turn_right_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      turn.distanceLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      turn.instruction,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    turn.kmLeft.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'km left',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (destination != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _openExternalTurnByTurn(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.navigation_rounded,
                      color: AppColors.primaryLight,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Launch Google Maps Turn-by-Turn',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom stats strip ────────────────────────────────────────────────
class _BottomStrip extends StatelessWidget {
  final NavigationState nav;
  const _BottomStrip({required this.nav});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatCell(label: 'ETA', value: nav.etaLabel),
          _StatCell(
            label: 'Distance',
            value: '${nav.distanceKm.toStringAsFixed(1)} km',
          ),
          _StatCell(label: 'Duration', value: '${nav.durationMin} min'),
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.deepEarth,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Exit Nav',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF8E8E93),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

// ── Blinking LIVE dot ─────────────────────────────────────────────────
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
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
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
          color: Color(0xFF34A853),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Pulse ring ────────────────────────────────────────────────────────
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
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _scale = Tween(begin: 0.9, end: 1.8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
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
          width: 44,
          height: 44,
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

// ── Heading cone painter ──────────────────────────────────────────────
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
        ..color = const Color(0xFFD85A30).withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
