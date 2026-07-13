import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/navigation_models.dart';
import '../providers/navigation_provider.dart';
import 'shared/member_avatar.dart';
import 'shared/mock_map_painter.dart';

class GroupTrackerTab extends ConsumerWidget {
  const GroupTrackerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Mini map ────────────────────────────────────────
          _MiniMap(members: nav.members),
          const SizedBox(height: 12),

          // ── Section label ───────────────────────────────────
          const Text(
            'MEMBERS · 4 TRAVELERS',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          // ── Member cards ─────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E5EA), width: 0.5),
            ),
            child: Column(
              children: nav.members
                  .asMap()
                  .entries
                  .map((e) => _MemberRow(
                        member: e.value,
                        isLast: e.key == nav.members.length - 1,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          // ── Group spread warning ─────────────────────────────
          _GroupSpreadBanner(spreadKm: nav.groupSpreadKm),
        ],
      ),
    );
  }
}

// ── Mini map thumbnail ───────────────────────────────────────────
class _MiniMap extends StatelessWidget {
  final List<NavMember> members;
  const _MiniMap({required this.members});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFF35404F),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        ),
        child: Stack(
          children: [
            // Map roads (mini version)
            CustomPaint(
              painter: const MockMapPainter(showRoute: true),
              size: Size(MediaQuery.of(context).size.width - 32, 150),
            ),

            // Member pins (simplified for mini map)
            ...members.map((m) {
              final x = m.mapPosition.dx *
                      (MediaQuery.of(context).size.width - 32) -
                  11;
              final y = m.mapPosition.dy * 150 - 11;
              return Positioned(
                left: x.clamp(0.0, MediaQuery.of(context).size.width - 55),
                top: y.clamp(0.0, 128.0),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: m.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(m.initials,
                      style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              );
            }),

            // Destination dot
            Positioned(
              top: 6,
              left: MediaQuery.of(context).size.width * 0.44,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),

            // "View full map" pill
            Positioned(
              bottom: 8,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('View full map',
                    style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Individual member row ─────────────────────────────────────────
class _MemberRow extends StatelessWidget {
  final NavMember member;
  final bool isLast;
  const _MemberRow({required this.member, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isOffline = member.status == MemberStatus.offline;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF5F5F5), width: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Opacity(
                opacity: isOffline ? 0.6 : 1.0,
                child: MemberAvatar(member: member, size: 36),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.name,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isOffline
                                ? const Color(0xFF8E8E93)
                                : Colors.black,
                          ),
                        ),
                        if (member.isMe) ...[
                          const SizedBox(width: 4),
                          const Text(' (you)',
                              style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 10,
                                  color: Color(0xFF8E8E93))),
                        ]
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusText(),
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _statusColor(),
                      ),
                    ),
                  ],
                ),
              ),
              if (member.speedKmh != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${member.speedKmh!.toInt()} km/h',
                      style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black),
                    ),
                    const Text('speed',
                        style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10,
                            color: Color(0xFF8E8E93))),
                  ],
                ),
            ],
          ),

          // Chips row
          if (!isOffline) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 45),
              child: Row(
                children: [
                  _RoleChip(role: member.role),
                  const SizedBox(width: 6),
                  if (member.eta != null)
                    _EtaChip(
                      label: 'ETA ${member.eta!}',
                      isLate: member.status == MemberStatus.offline ||
                          member.id == 'carlo',
                    ),
                ],
              ),
            ),
          ],

          // Offline / location paused banner
          if (isOffline && member.isLocationSharingPaused) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 45),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 12, color: Color(0xFF854F0B)),
                    const SizedBox(width: 5),
                    Text(
                      member.lastSeenLabel ?? 'Location sharing paused',
                      style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF854F0B)),
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

  String _statusText() {
    if (member.isMe) return 'En route · ${(member.distanceKm ?? 0).abs().toStringAsFixed(1)} km from destination';
    if (member.status == MemberStatus.offline) {
      return member.lastSeenLabel ?? 'Offline';
    }
    if (member.status == MemberStatus.arrived) {
      return '${(member.distanceKm ?? 0).toStringAsFixed(1)} km ahead of you';
    }
    if ((member.distanceKm ?? 0) < 0) {
      return '${(member.distanceKm ?? 0).abs().toStringAsFixed(1)} km behind you';
    }
    return '${(member.distanceKm ?? 0).toStringAsFixed(1)} km ahead of you';
  }

  Color _statusColor() {
    if (member.status == MemberStatus.offline) return const Color(0xFFC7C7CC);
    if (member.status == MemberStatus.arrived || (member.distanceKm ?? 0) > 0) {
      return const Color(0xFF34A853);
    }
    return const Color(0xFF8E8E93);
  }
}

// ── Role chip ─────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  Color get _bgColor {
    switch (role) {
      case 'Organizer': return const Color(0xFFEAF3DE);
      case 'Navigator': return const Color(0xFFE8F0FE);
      case 'Documenter': return const Color(0xFFFAECE7);
      default: return const Color(0xFFF2F2F7);
    }
  }

  Color get _textColor {
    switch (role) {
      case 'Organizer': return const Color(0xFF3B6D11);
      case 'Navigator': return const Color(0xFF1A56C9);
      case 'Documenter': return const Color(0xFFD85A30);
      default: return const Color(0xFF8E8E93);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _textColor),
      ),
    );
  }
}

// ── ETA chip ──────────────────────────────────────────────────────
class _EtaChip extends StatelessWidget {
  final String label;
  final bool isLate;
  const _EtaChip({required this.label, this.isLate = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isLate
            ? const Color(0xFFFAEEDA)
            : const Color(0xFFEAF3DE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isLate ? const Color(0xFF854F0B) : const Color(0xFF3B6D11),
        ),
      ),
    );
  }
}

// ── Group spread warning banner ───────────────────────────────────
class _GroupSpreadBanner extends StatelessWidget {
  final double spreadKm;
  const _GroupSpreadBanner({required this.spreadKm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, size: 14, color: Color(0xFFA32D2D)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group spread: ${spreadKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA32D2D)),
                ),
                const Text(
                  'Carlo is falling behind · 6 min gap',
                  style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      color: Color(0xFFA32D2D)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Alert',
              style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
