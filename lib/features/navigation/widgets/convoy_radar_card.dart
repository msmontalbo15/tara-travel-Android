import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback/app_feedback.dart';
import '../models/navigation_models.dart';
import '../providers/navigation_provider.dart';
import 'meet_halfway_sheet.dart';
import 'navigate_to_member_sheet.dart';
import 'shared/member_avatar.dart';

/// Convoy Formation Radar & Live Arrival Board Card
/// Visualizes convoy pace roles (Lead, Mid, Tail), distance gaps,
/// straggler warnings, and live ETA to the upcoming stop for every companion.
class ConvoyRadarCard extends ConsumerWidget {
  final bool isDark;

  const ConvoyRadarCard({
    super.key,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    final notifier = ref.read(navigationProvider.notifier);

    final members = nav.members;
    if (members.isEmpty) return const SizedBox.shrink();

    final spreadKm = nav.groupSpreadKm;

    final bgColor = isDark ? const Color(0xFF1E140F) : Colors.white;
    final borderColor = isDark
        ? AppColors.primary.withValues(alpha: 0.25)
        : const Color(0xFFE5E5EA);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header & Spread Pill ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.radar_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONVOY FORMATION RADAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white70 : AppColors.deepEarth,
                        ),
                      ),
                      Text(
                        '${members.length} vehicles / companions on route',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Spread badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _spreadColor(spreadKm).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _spreadColor(spreadKm).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.linear_scale_rounded,
                      size: 12,
                      color: _spreadColor(spreadKm),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${spreadKm.toStringAsFixed(1)} km gap',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _spreadColor(spreadKm),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Proactive Straggler Alert (if lead/convoy detected lag) ──────
          if (nav.convoyPrompt != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFEEBA)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFF856404),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nav.convoyPrompt!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF856404),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      notifier.dismissConvoyPrompt();
                      AppFeedback.showInfo(
                        context,
                        '📢 Pit stop advisory broadcasted to group chat',
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF856404),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Suggest Rest',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Formation Corridor Visualizer Track ──────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CONVOY POSITIONS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                    InkWell(
                      onTap: () => MeetHalfwaySheet.show(context),
                      borderRadius: BorderRadius.circular(6),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.handshake_outlined,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Meet Halfway',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Corridor Role Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: members.map((m) {
                    return _FormationMemberPill(
                      member: m,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        NavigateToMemberSheet.show(context, m);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Live Arrival Board Header ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE ARRIVAL BOARD · ${nav.destination.name.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              if (nav.destination.eta.isNotEmpty)
                Text(
                  'ETA: ${nav.destination.eta}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Companion Arrival Rows ───────────────────────────────────────
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (_, __) => Divider(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFF0F0F0),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final m = members[index];
              return _ArrivalBoardRow(
                member: m,
                isDark: isDark,
                onTap: () => NavigateToMemberSheet.show(context, m),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _spreadColor(double spreadKm) {
    if (spreadKm <= 1.5) return AppColors.greenBright;
    if (spreadKm <= 3.0) return AppColors.amber;
    return const Color(0xFFDC2626);
  }
}

// ── Formation Member Pill ───────────────────────────────────────────────────

class _FormationMemberPill extends StatelessWidget {
  final NavMember member;
  final bool isDark;
  final VoidCallback onTap;

  const _FormationMemberPill({
    required this.member,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(member.convoyRole, member.isStraggler);
    final roleIcon = _getRoleIcon(member.convoyRole, member.isStraggler);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C1A14) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: roleColor.withValues(alpha: 0.6),
            width: member.isMe ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MemberAvatar(member: member, size: 20),
            const SizedBox(width: 6),
            Text(
              member.isMe ? 'You' : member.name.split(' ').first,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(roleIcon, size: 10, color: roleColor),
                  const SizedBox(width: 2),
                  Text(
                    member.isStraggler ? 'TAIL' : member.convoyRole.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: roleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(ConvoyRole role, bool isStraggler) {
    if (isStraggler) return const Color(0xFFDC2626);
    switch (role) {
      case ConvoyRole.lead:
        return AppColors.primary;
      case ConvoyRole.mid:
        return const Color(0xFF2563EB);
      case ConvoyRole.tail:
        return AppColors.amber;
    }
  }

  IconData _getRoleIcon(ConvoyRole role, bool isStraggler) {
    if (isStraggler) return Icons.warning_amber_rounded;
    switch (role) {
      case ConvoyRole.lead:
        return Icons.navigation_rounded;
      case ConvoyRole.mid:
        return Icons.directions_car_rounded;
      case ConvoyRole.tail:
        return Icons.access_time_rounded;
    }
  }
}

// ── Arrival Board Row ───────────────────────────────────────────────────────

class _ArrivalBoardRow extends StatelessWidget {
  final NavMember member;
  final bool isDark;
  final VoidCallback onTap;

  const _ArrivalBoardRow({
    required this.member,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distStop = member.distanceToStopKm ?? member.distanceKm?.abs() ?? 0.0;
    final distStopLabel = distStop < 1.0
        ? '${(distStop * 1000).toInt()} m'
        : '${distStop.toStringAsFixed(1)} km';

    final etaText = member.etaToStop ?? member.eta ?? 'Calculating';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            MemberAvatar(member: member, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (member.isMe) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (member.speedKmh != null && member.speedKmh! > 1.0) ...[
                        Icon(
                          Icons.speed_rounded,
                          size: 11,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${member.speedKmh!.toInt()} km/h • ',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                      Text(
                        member.status == MemberStatus.arrived
                            ? 'Arrived at destination'
                            : '$distStopLabel to stop',
                        style: TextStyle(
                          fontSize: 11,
                          color: member.status == MemberStatus.arrived
                              ? AppColors.greenBright
                              : (isDark ? Colors.white54 : AppColors.textSecondary),
                          fontWeight: member.status == MemberStatus.arrived
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ETA & Status Chip
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  member.status == MemberStatus.arrived
                      ? '✓ ARRIVED'
                      : etaText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: member.status == MemberStatus.arrived
                        ? AppColors.greenBright
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                if (!member.isMe)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.navigation_rounded,
                        size: 10,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Route',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
