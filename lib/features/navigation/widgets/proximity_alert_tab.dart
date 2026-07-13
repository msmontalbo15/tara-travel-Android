import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/navigation_models.dart';
import '../providers/navigation_provider.dart';
import 'shared/mock_map_painter.dart';

class ProximityAlertTab extends ConsumerWidget {
  const ProximityAlertTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);

    return Column(
      children: [
        // ── Proximity map ─────────────────────────────────────
        SizedBox(
          height: 300,
          child: Stack(
            children: [
              // Map background with proximity rings
              const CustomPaint(
                painter: MockMapPainter(
                  showRoute: false,
                  showProximityRings: true,
                ),
                size: Size(double.infinity, 300),
              ),

              // Destination label
              Positioned(
                top: 115,
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(-20, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                       nav.destination.name,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // User avatar (approaching)
              Positioned(
                bottom: 36,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 3),
                        ),
                        alignment: Alignment.center,
                        child: const Text('S',
                            style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),

              // Distance label
              Positioned(
                bottom: 66,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '300 m away',
                      style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Slide-up sheet ─────────────────────────────────────
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // ── Alert header ─────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.place_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Almost there!',
                              style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  letterSpacing: -0.3),
                            ),
                            Text(
                               '300 m from ${nav.destination.name}',
                              style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 12,
                                  color: Color(0xFF8E8E93)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3DE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '2 min',
                          style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3B6D11)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Next stop card ───────────────────────────
                  Container(
                    padding: const EdgeInsets.all(13),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next stop on itinerary',
                          style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              color: Color(0xFF8E8E93)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                           'Check-in at ${nav.destination.name}',
                          style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 2),
                        Text(
                           'Station 1, White Beach · Confirmation #${nav.destination.confirmationCode}',
                          style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              color: Color(0xFF8E8E93)),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            _InfoChip(
                                label: 'Hotel',
                                bg: Color(0xFFDBEAFE),
                                fg: Color(0xFF185FA5)),
                            SizedBox(width: 6),
                             _InfoChip(
                               label: '₱28,000 · Spencer paid',
                               bg: AppColors.sand,
                               fg: AppColors.darkAccent,
                             ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Group status ─────────────────────────────
                  const Text(
                    'GROUP STATUS',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8E8E93),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  ...nav.members
                      .where((m) => !m.isMe)
                      .map((m) => _GroupStatusRow(member: m)),
                  const SizedBox(height: 14),

                  // ── Action buttons ───────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Open in Maps',
                              style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_none_rounded,
                              color: Color(0xFF3C3C43)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Group status row ─────────────────────────────────────────────
class _GroupStatusRow extends StatelessWidget {
  final NavMember member;
  const _GroupStatusRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final isArrived = member.status == MemberStatus.arrived;
    final isOffline = member.status == MemberStatus.offline;

    String statusText;
    Color statusColor;

    if (isArrived) {
      statusText = 'Already arrived';
      statusColor = const Color(0xFF34A853);
    } else if (isOffline) {
      statusText = 'Offline';
      statusColor = const Color(0xFF8E8E93);
    } else if (member.eta != null) {
      statusText = '~${member.eta} away';
      statusColor = const Color(0xFF854F0B);
    } else {
      statusText = 'En route';
      statusColor = const Color(0xFF34A853);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: member.color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(member.initials,
                style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          const SizedBox(width: 7),
          Text(
            member.name.split(' ').first,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: isOffline ? const Color(0xFF8E8E93) : Colors.black,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isArrived
                  ? const Color(0xFF34A853)
                  : isOffline
                      ? const Color(0xFFC7C7CC)
                      : const Color(0xFFEF9F27),
              shape: BoxShape.circle,
            ),
          ),
          const Spacer(),
          Text(statusText,
              style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor)),
        ],
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _InfoChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg)),
    );
  }
}
