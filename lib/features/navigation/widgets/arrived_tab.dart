import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/navigation_models.dart';
import '../providers/navigation_provider.dart';

class ArrivedTab extends ConsumerWidget {
  const ArrivedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 32),
      child: Column(
        children: [
          // ── Check-in notification ─────────────────────────
          _CheckInNotification(destinationName: nav.destination.name),
          const SizedBox(height: 8),

          // ── Lia message ───────────────────────────────────
          if (nav.members.length > 1) ...[
            _MessageNotification(
              member: nav.members[1],
              timeLabel: '2 min ago',
              message: 'Checked in successfully.',
            ),
            const SizedBox(height: 8),
          ],
          if (nav.members.length > 2) ...[
            _MessageNotification(
              member: nav.members[2],
              timeLabel: '5 min ago',
              message: 'On the way to destination.',
              subtitle: nav.members[2].role,
            ),
            const SizedBox(height: 14),
          ],

          // ── Arrival summary ───────────────────────────────
          _ArrivalSummary(members: nav.members),
          const SizedBox(height: 12),

          // ── Next itinerary pill ───────────────────────────
          _NextItineraryPill(
            label: nav.nextItineraryLabel,
            time: nav.nextItineraryTime,
          ),
        // no change
        ],
      ),
    );
  }
}

// ── Check-in notification banner ─────────────────────────────────
class _CheckInNotification extends StatelessWidget {
  final String destinationName;
  const _CheckInNotification({required this.destinationName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tara Travel',
                        style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    Text('now',
                        style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10,
                            color: Colors.white38)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Message
          Text(
            "You've arrived at $destinationName!",
            style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
          const SizedBox(height: 3),
          const Text(
            'See live arrival updates from your trip group.',
            style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                color: Colors.white60),
          ),
          const SizedBox(height: 10),

          // Actions
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Check in',
                        style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Later',
                        style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: Colors.white38)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Message notification card ─────────────────────────────────────
class _MessageNotification extends StatelessWidget {
  final NavMember member;
  final String timeLabel;
  final String message;
  final String? subtitle;
  const _MessageNotification({
    required this.member,
    required this.timeLabel,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: member.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(member.initials,
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle != null
                        ? '${member.name} · $subtitle'
                        : member.name,
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  Text(timeLabel,
                      style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          color: Colors.white38)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(message,
              style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: Colors.white70)),
        ],
      ),
    );
  }
}

// ── Arrival summary card ──────────────────────────────────────────
class _ArrivalSummary extends StatelessWidget {
  final List<NavMember> members;
  const _ArrivalSummary({required this.members});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ARRIVAL SUMMARY',
            style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white30,
                letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          ...members.map((m) => _ArrivalRow(member: m)),
        ],
      ),
    );
  }
}

class _ArrivalRow extends StatelessWidget {
  final NavMember member;
  const _ArrivalRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final isOffline = member.status == MemberStatus.offline;
    final isEnRoute = member.status == MemberStatus.enRoute && !member.isMe;

    String statusText;
    Color statusColor;

    if (isOffline) {
      statusText = 'Offline';
      statusColor = const Color(0xFF8E8E93);
    } else if (member.isMe || member.id == 'spencer') {
      statusText = 'Arrived · 4:18 PM';
      statusColor = const Color(0xFF34A853);
    } else if (member.id == 'lia') {
      statusText = 'Arrived · 4:12 PM';
      statusColor = const Color(0xFF34A853);
    } else if (isEnRoute) {
      statusText = 'En route · ${member.eta ?? ""}';
      statusColor = const Color(0xFFEF9F27);
    } else {
      statusText = 'Arrived';
      statusColor = const Color(0xFF34A853);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isOffline ? member.color.withValues(alpha: 0.5) : member.color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(member.initials,
                style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          const SizedBox(width: 7),
          Text(
            member.name.split(' ').first,
            style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: isOffline ? const Color(0xFF8E8E93) : Colors.white),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(statusText,
                  style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Next itinerary pill ───────────────────────────────────────────
class _NextItineraryPill extends StatelessWidget {
  final String label;
  final String time;
  const _NextItineraryPill({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next on itinerary',
                    style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: Colors.white60)),
                Text(
                  '$label · $time',
                  style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Colors.white, size: 18),
        ],
      ),
    );
  }
}
