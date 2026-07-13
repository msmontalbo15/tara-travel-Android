import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/member_model.dart';

class StopCard extends StatelessWidget {
  final ItineraryStop stop;
  final List<MemberModel> members;
  final bool isLast;
  final VoidCallback? onTap;
  final void Function(StopStatus)? onStatusChange;

  const StopCard({
    super.key,
    required this.stop,
    required this.members,
    this.isLast = false,
    this.onTap,
    this.onStatusChange,
  });

  MemberModel? get _assignedMember {
    if (stop.assignedMemberId == null) return null;
    try {
      return members.firstWhere((m) => m.id == stop.assignedMemberId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = stop.type;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: type.color, width: 2),
                  ),
                  child: Icon(type.icon, color: type.color, size: 14),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.dividerLight,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Card content
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time + Status Row
                    Row(
                      children: [
                        if (stop.startTime != null)
                          Text(
                            _formatTime(stop.startTime!),
                            style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                          ),
                        if (stop.duration.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text('· ${stop.duration}', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.muted)),
                        ],
                        const Spacer(),
                        _buildStatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Title
                    Text(stop.title, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
                    // Location
                    if (stop.location != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 13, color: AppColors.muted),
                          const SizedBox(width: 3),
                          Text(stop.location!, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ],
                    // Notes
                    if (stop.notes != null && stop.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(stop.notes!, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    // Footer: cost + assigned member
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Type chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: type.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(type.label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600, color: type.color)),
                        ),
                        // Transport mode badge
                        if (stop.transportMode != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD85A30).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(stop.transportMode!.emoji, style: const TextStyle(fontSize: 10)),
                                const SizedBox(width: 3),
                                Text(stop.transportMode!.label, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFD85A30))),
                              ],
                            ),
                          ),
                        ],
                        if (stop.estimatedCost != null) ...[
                          const SizedBox(width: 6),
                          Text('₱${stop.estimatedCost!.toInt()}', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deepEarth)),
                        ],
                        const Spacer(),
                        if (_assignedMember != null)
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(color: _assignedMember!.color, shape: BoxShape.circle),
                                child: Center(child: Text(_assignedMember!.initials.substring(0, 1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                              ),
                              const SizedBox(width: 4),
                              Text(_assignedMember!.name.split(' ').first, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.muted)),
                            ],
                          ),
                      ],
                    ),
                    if (stop.confirmationNumber != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.confirmation_number_outlined, size: 12, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text('Ref: ${stop.confirmationNumber}', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (stop.status == StopStatus.pending) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: stop.status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(stop.status.label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w700, color: stop.status.color)),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final min = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }
}
