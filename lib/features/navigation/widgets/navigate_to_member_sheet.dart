import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback/app_feedback.dart';
import '../models/navigation_models.dart';
import '../providers/navigation_provider.dart';
import 'shared/member_avatar.dart';

class NavigateToMemberSheet extends ConsumerWidget {
  final NavMember member;

  const NavigateToMemberSheet({super.key, required this.member});

  static Future<void> show(BuildContext context, NavMember member) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NavigateToMemberSheet(member: member),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    final isNavigatingToThisMember = nav.activeMemberRoute?.id == member.id;
    final isHalfwayActive = isNavigatingToThisMember && nav.meetHalfwayPoint != null;

    final distKm = member.distanceKm?.abs() ?? 1.2;
    final distText = distKm < 1.0
        ? '${(distKm * 1000).toInt()} m'
        : '${distKm.toStringAsFixed(1)} km';

    final walkMin = (distKm * 12).round().clamp(1, 180);
    final driveMin = (distKm * 2.5).round().clamp(1, 60);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Member Header Card
          Row(
            children: [
              MemberAvatar(member: member, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (member.isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.sand,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${member.role} · ${member.status == MemberStatus.enRoute ? "Moving" : "Stationary"}',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (member.batteryLevel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        member.batteryLevel! > 20
                            ? Icons.battery_charging_full_rounded
                            : Icons.battery_alert_rounded,
                        size: 14,
                        color: member.batteryLevel! > 20
                            ? const Color(0xFF34A853)
                            : const Color(0xFFE24A4A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${member.batteryLevel}%',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Distance & Telemetry Matrix
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFECE5DE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TelemetryMetric(
                  icon: Icons.straighten_rounded,
                  label: 'Distance',
                  value: distText,
                  color: AppColors.primary,
                ),
                Container(width: 1, height: 32, color: const Color(0xFFE5E5EA)),
                _TelemetryMetric(
                  icon: Icons.directions_walk_rounded,
                  label: 'Walking',
                  value: '$walkMin min',
                  color: AppColors.amber,
                ),
                Container(width: 1, height: 32, color: const Color(0xFFE5E5EA)),
                _TelemetryMetric(
                  icon: Icons.directions_car_rounded,
                  label: 'Driving',
                  value: '$driveMin min',
                  color: const Color(0xFF2563EB),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Navigation Primary Actions
          if (!member.isMe) ...[
            if (isNavigatingToThisMember) ...[
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(navigationProvider.notifier)
                      .cancelMemberNavigation();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancel Direct Route'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE24A4A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(navigationProvider.notifier)
                      .navigateToMember(member);
                  Navigator.pop(context);
                  AppFeedback.showSuccess(
                    context,
                    '🧭 Routing directly to ${member.name}',
                  );
                },
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: Text('Navigate to ${member.name}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 10),

              // Meet Halfway Button
              OutlinedButton.icon(
                onPressed: () {
                  ref
                      .read(navigationProvider.notifier)
                      .computeMeetHalfway(member);
                  Navigator.pop(context);
                  AppFeedback.showInfo(
                    context,
                    '📍 Meet Halfway active — Routing to midpoint with ${member.name}',
                  );
                },
                icon: const Icon(Icons.handshake_outlined,
                    size: 18, color: AppColors.amber),
                label: Text(
                  isHalfwayActive
                      ? 'Meet Halfway Active'
                      : 'Meet Halfway (${(distKm / 2).toStringAsFixed(1)} km midpoint)',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepEarth,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Color(0xFFE5E5EA), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // External Navigation Apps Launch Section
            const Text(
              'OPEN IN EXTERNAL GPS',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8E8E93),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _ExternalNavButton(
                    icon: Icons.map_rounded,
                    label: 'Google Maps',
                    color: const Color(0xFF1A73E8),
                    onTap: () => _launchExternalGps(
                      'https://www.google.com/maps/dir/?api=1&destination=${member.latitude ?? 14.5995},${member.longitude ?? 120.9842}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ExternalNavButton(
                    icon: Icons.navigation_outlined,
                    label: 'Waze',
                    color: const Color(0xFF33CCFF),
                    textColor: const Color(0xFF0F4C5C),
                    onTap: () => _launchExternalGps(
                      'https://waze.com/ul?ll=${member.latitude ?? 14.5995},${member.longitude ?? 120.9842}&navigate=yes',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ExternalNavButton(
                    icon: Icons.apple_rounded,
                    label: 'Apple Maps',
                    color: const Color(0xFF2C1A14),
                    onTap: () => _launchExternalGps(
                      'https://maps.apple.com/?daddr=${member.latitude ?? 14.5995},${member.longitude ?? 120.9842}',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _launchExternalGps(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Fallback
    }
  }
}

class _TelemetryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TelemetryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            color: Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }
}

class _ExternalNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _ExternalNavButton({
    required this.icon,
    required this.label,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor ?? color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
