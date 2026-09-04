import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/navigation_models.dart';
import '../providers/navigation_provider.dart';
import 'navigate_to_member_sheet.dart';

class ConvoyAlertBanner extends ConsumerWidget {
  const ConvoyAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    if (nav.convoyAlerts.isEmpty) return const SizedBox.shrink();

    final alert = nav.convoyAlerts.first;
    final laggingMember = nav.members.firstWhere(
      (m) => m.id == alert.memberId,
      orElse: () => NavMember(
        id: alert.memberId,
        name: alert.memberName,
        initials: alert.memberName.isNotEmpty ? alert.memberName[0] : 'T',
        color: const Color(0xFFE24A4A),
        status: MemberStatus.enRoute,
        role: 'Traveler',
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF7C5C5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE24A4A).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFE24A4A),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'CONVOY SEPARATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFA32D2D),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA32D2D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${alert.gapKm.toStringAsFixed(1)} km gap',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${alert.memberName} is lagging behind (~${alert.estimatedMinutesBehind} min delay)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF631D1D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action: Navigate to member
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              NavigateToMemberSheet.show(context, laggingMember);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA32D2D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Locate',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Dismiss Icon
          IconButton(
            onPressed: () {
              ref
                  .read(navigationProvider.notifier)
                  .dismissConvoyAlert(alert.memberId);
            },
            icon: const Icon(Icons.close_rounded,
                size: 16, color: Color(0xFFA32D2D)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}
