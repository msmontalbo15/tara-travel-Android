import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/member_model.dart';
import '../../../core/theme/app_colors.dart';

/// Day progress + squad presence banner shown above the timeline.
class ItineraryFulfillmentBanner extends StatelessWidget {
  final ItineraryDay day;
  final List<MemberModel> allMembers;

  const ItineraryFulfillmentBanner({
    super.key,
    required this.day,
    required this.allMembers,
  });

  @override
  Widget build(BuildContext context) {
    final total = day.stops.length;
    final completed = day.stops.where((s) => s.isCompleted).length;
    final progress = total > 0 ? completed / total : 0.0;
    final pct = (progress * 100).round();

    // Squad presence: for each stop, collect checked-in members
    final Map<String, String> memberCurrentStop = {};
    for (final stop in day.stops) {
      for (final memberId in stop.checkedInMemberIds) {
        memberCurrentStop[memberId] = stop.title;
      }
    }

    final activeMembers = allMembers
        .where((m) => memberCurrentStop.containsKey(m.id))
        .toList();

    // Next uncompleted stop
    final nextStop = day.stops.where((s) => !s.isCompleted).firstOrNull;

    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A04).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Progress ring
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(56, 56),
                      painter: _FulfillmentRingPainter(progress: progress),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pct%',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completed of $total stops visited',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (nextStop != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 10, color: AppColors.amber),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Next: ${nextStop.title}',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                color: AppColors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (activeMembers.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _SquadPresenceRow(
                        members: activeMembers,
                        memberCurrentStop: memberCurrentStop,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SquadPresenceRow extends StatelessWidget {
  final List<MemberModel> members;
  final Map<String, String> memberCurrentStop;

  const _SquadPresenceRow({
    required this.members,
    required this.memberCurrentStop,
  });

  @override
  Widget build(BuildContext context) {
    final visible = members.take(4).toList();
    return Row(
      children: [
        // Avatar stack
        SizedBox(
          width: visible.length * 14.0 + 10,
          height: 22,
          child: Stack(
            children: List.generate(visible.length, (i) {
              final m = visible[i];
              return Positioned(
                left: i * 13.0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: m.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1A0A04),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    m.initials.substring(0, 1),
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            members.length == 1
                ? '${members.first.name.split(' ').first} is out there'
                : '${members.length} members on the move',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FulfillmentRingPainter extends CustomPainter {
  final double progress;
  _FulfillmentRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;
    const stroke = 5.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = const Color(0xFF10B981)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_FulfillmentRingPainter old) => old.progress != progress;
}
