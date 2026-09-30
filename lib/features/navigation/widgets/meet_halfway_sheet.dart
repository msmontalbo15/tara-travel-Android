import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_broadcast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/feedback/app_feedback.dart';
import '../models/navigation_models.dart';
import '../providers/navigation_provider.dart';
import 'shared/member_avatar.dart';

/// "Meet Halfway" Rendezvous & Centroid Bottom Sheet Modal
/// Computes the geographical centroid among group companions,
/// visualizes intercept distances, and sets mutual meeting points.
class MeetHalfwaySheet extends ConsumerStatefulWidget {
  const MeetHalfwaySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const MeetHalfwaySheet(),
    );
  }

  @override
  ConsumerState<MeetHalfwaySheet> createState() => _MeetHalfwaySheetState();
}

class _MeetHalfwaySheetState extends ConsumerState<MeetHalfwaySheet> {
  final Set<String> _selectedMemberIds = {};

  @override
  void initState() {
    super.initState();
    // Default to all active members with coordinates
    final nav = ref.read(navigationProvider);
    for (final m in nav.members) {
      if (m.latitude != null && m.longitude != null && m.status != MemberStatus.offline) {
        _selectedMemberIds.add(m.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider);
    final notifier = ref.read(navigationProvider.notifier);

    final eligibleMembers = nav.members.where((m) {
      return m.latitude != null && m.longitude != null;
    }).toList();

    final selectedMembers = eligibleMembers.where((m) {
      return _selectedMemberIds.contains(m.id);
    }).toList();

    // Compute centroid
    final points = selectedMembers
        .map((m) => (lat: m.latitude!, lng: m.longitude!))
        .toList();
    final centroid = LocationBroadcastService.calculateCentroid(points);

    // Compute my distance to centroid
    final me = nav.members.firstWhere((m) => m.isMe, orElse: () => nav.members.first);
    double myDistToCentroidKm = 0.0;
    if (centroid != null && me.latitude != null && me.longitude != null) {
      myDistToCentroidKm = Geolocator.distanceBetween(
            me.latitude!,
            me.longitude!,
            centroid.lat,
            centroid.lng,
          ) /
          1000.0;
    }

    final isCentroidActive = nav.meetHalfwayLat != null && nav.meetHalfwayLng != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        context.safeBottomPadding(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handshake_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MEET HALFWAY · RENDEZVOUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Squad Midpoint Centroid',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCentroidActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Midpoint Summary Card
          if (centroid != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOUR DISTANCE TO MIDPOINT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            myDistToCentroidKm < 1.0
                                ? '${(myDistToCentroidKm * 1000).toInt()} meters away'
                                : '${myDistToCentroidKm.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deepEarth,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '~${((myDistToCentroidKm / 0.58).clamp(1, 120)).toInt()} min drive',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFE5E5EA), height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coordinates: ${centroid.lat.toStringAsFixed(4)}, ${centroid.lng.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${selectedMembers.length} travelers included',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEBEB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'At least 2 active companions with shared GPS are needed to compute a mutual midpoint rendezvous.',
                style: TextStyle(fontSize: 12, color: Color(0xFFA32D2D)),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Companion Selection Chips
          const Text(
            'SELECT COMPANIONS FOR MIDPOINT GATHERING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: eligibleMembers.map((m) {
              final isSelected = _selectedMemberIds.contains(m.id);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MemberAvatar(member: m, size: 18),
                    const SizedBox(width: 6),
                    Text(m.isMe ? 'You' : m.name.split(' ').first),
                  ],
                ),
                selected: isSelected,
                selectedColor: AppColors.sand,
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : const Color(0xFFE5E5EA),
                  ),
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedMemberIds.add(m.id);
                    } else if (_selectedMemberIds.length > 2) {
                      _selectedMemberIds.remove(m.id);
                    } else {
                      AppFeedback.showWarning(
                        context,
                        'Need at least 2 members for a midpoint rendezvous',
                      );
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          if (centroid != null) ...[
            if (isCentroidActive) ...[
              ElevatedButton.icon(
                onPressed: () {
                  notifier.cancelRendezvous();
                  Navigator.pop(context);
                  AppFeedback.showInfo(context, 'Midpoint rendezvous cleared');
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancel Midpoint Navigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
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
                  HapticFeedback.mediumImpact();
                  notifier.computeGroupCentroidRendezvous(
                    selectedMemberIds: _selectedMemberIds.toList(),
                  );
                  Navigator.pop(context);
                  AppFeedback.showSuccess(
                    context,
                    '🧭 Mutual centroid rendezvous active (~${myDistToCentroidKm.toStringAsFixed(1)} km away)',
                  );
                },
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text('Set Midpoint as Destination'),
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
            ],
          ],
        ],
      ),
    );
  }
}
