import 'package:flutter/material.dart';
import '../../../../core/widgets/member_avatar_circle.dart';
import '../../models/navigation_models.dart';

// ── Status colour helper (feature-local MemberStatus) ────────────────────────

Color _statusColor(MemberStatus status) {
  switch (status) {
    case MemberStatus.arrived:
    case MemberStatus.enRoute:
      return const Color(0xFF34A853);
    case MemberStatus.offline:
    case MemberStatus.paused:
      return const Color(0xFFC7C7CC);
  }
}

// ── MemberAvatar ──────────────────────────────────────────────────────────────

/// Circular avatar with profile photo / initials and an optional status dot.
class MemberAvatar extends StatelessWidget {
  final NavMember member;
  final double size;
  final bool showStatus;
  final double borderWidth;
  final Color borderColor;

  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 36,
    this.showStatus = true,
    this.borderWidth = 0,
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final isOffline = member.status == MemberStatus.offline ||
        member.status == MemberStatus.paused;

    return SizedBox(
      width: size + (showStatus ? 4 : 0),
      height: size + (showStatus ? 4 : 0),
      child: Stack(
        children: [
          MemberAvatarCircle(
            photoUrl: member.photoUrl,
            initials: member.initials,
            color: isOffline
                ? member.color.withValues(alpha: 0.5)
                : member.color,
            size: size,
            border: borderWidth > 0
                ? Border.all(color: borderColor, width: borderWidth)
                : null,
          ),
          if (showStatus)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: _statusColor(member.status),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── MapMemberPin ──────────────────────────────────────────────────────────────

/// Compact map pin: avatar circle + tail + name label bubble.
class MapMemberPin extends StatelessWidget {
  final NavMember member;
  final String labelText;

  const MapMemberPin({
    super.key,
    required this.member,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MemberAvatarCircle(
          photoUrl: member.photoUrl,
          initials: member.initials,
          color: member.color,
          size: 28,
          border: Border.all(color: Colors.white, width: 2.5),
        ),
        Container(
          width: 2,
          height: 7,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xDD2C1A14),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            labelText,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF0997B),
            ),
          ),
        ),
      ],
    );
  }
}
