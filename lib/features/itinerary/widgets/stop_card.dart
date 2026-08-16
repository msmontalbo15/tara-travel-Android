import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/member_model.dart';
import 'navigate_route_button.dart';

class StopCard extends StatelessWidget {
  final ItineraryStop stop;
  final List<MemberModel> members;
  final bool isLast;
  final VoidCallback? onTap;
  final void Function(StopStatus)? onStatusChange;
  final VoidCallback? onEdit;
  /// Called when the user taps "Mark Arrived" / check-in button.
  final VoidCallback? onCheckIn;

  const StopCard({
    super.key,
    required this.stop,
    required this.members,
    this.isLast = false,
    this.onTap,
    this.onStatusChange,
    this.onEdit,
    this.onCheckIn,
  });

  MemberModel? get _assignedMember {
    if (stop.assignedMemberId == null) return null;
    try {
      return members.firstWhere((m) => m.id == stop.assignedMemberId);
    } catch (_) {
      return null;
    }
  }

  List<MemberModel> get _checkedInMembers => members
      .where((m) => stop.checkedInMemberIds.contains(m.id))
      .toList();

  @override
  Widget build(BuildContext context) {
    final type = stop.type;
    final completed = stop.isCompleted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Journey Rail ───────────────────────────────────────────
          SizedBox(
            width: 36,
            child: Column(
              children: [
                // Node dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: completed
                        ? AppColors.greenBright
                        : type.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: completed ? AppColors.greenBright : type.color,
                      width: 2,
                    ),
                    boxShadow: completed
                        ? [
                            BoxShadow(
                              color: AppColors.greenBright.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: completed
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : Icon(type.icon, color: type.color, size: 14),
                ),
                // Vertical connector
                if (!isLast)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: completed
                            ? AppColors.greenBright.withValues(alpha: 0.5)
                            : AppColors.dividerLight,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Card ───────────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                decoration: BoxDecoration(
                  color: completed
                      ? AppColors.greenLight.withValues(alpha: 0.35)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: completed
                      ? Border.all(
                          color: AppColors.greenBright.withValues(alpha: 0.4),
                          width: 1.5,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: completed
                          ? AppColors.greenBright.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time + Status Row
                      Row(
                        children: [
                          if (stop.startTime != null)
                            Text(
                              _formatTime(stop.startTime!),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: completed
                                    ? AppColors.greenBright
                                    : AppColors.muted,
                              ),
                            ),
                          if (stop.duration.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '· ${stop.duration}',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                color: completed
                                    ? AppColors.greenBright.withValues(alpha: 0.7)
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                          const Spacer(),
                          // Arrived timestamp or status badge
                          if (completed && stop.arrivedAtLabel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.greenBright.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                stop.arrivedAtLabel!,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.greenBright,
                                ),
                              ),
                            )
                          else
                            _buildStatusBadge(),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title (strike-through when completed)
                                Text(
                                  stop.title,
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: completed
                                        ? AppColors.deepEarth.withValues(alpha: 0.55)
                                        : AppColors.deepEarth,
                                    decoration: completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: AppColors.greenBright,
                                  ),
                                ),
                                // Location
                                if (stop.location != null) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Text('📍',
                                          style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          stop.location!,
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 11,
                                            color: AppColors.muted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                // Notes
                                if (stop.notes != null &&
                                    stop.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    stop.notes!,
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Photo thumbnail
                          if (stop.photoUrls.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(stop.photoUrls.first),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // ── Checked-in members ────────────────────────────────
                      if (_checkedInMembers.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _CheckedInMemberRow(members: _checkedInMembers),
                      ],

                      // Footer
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Type chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: type.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              type.label,
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: type.color,
                              ),
                            ),
                          ),
                          // Transport badge
                          if (stop.transportMode != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD85A30).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(stop.transportMode!.emoji,
                                      style: const TextStyle(fontSize: 10)),
                                  const SizedBox(width: 3),
                                  Text(
                                    stop.transportMode!.label,
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFD85A30),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (stop.estimatedCost != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '₱${stop.estimatedCost!.toInt()}',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepEarth,
                              ),
                            ),
                          ],
                          const Spacer(),
                          // Maps btn
                          GestureDetector(
                            onTap: () => openGoogleMapsForStop(context, stop),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.directions_rounded,
                                      size: 13, color: AppColors.primary),
                                  SizedBox(width: 3),
                                  Text(
                                    'Maps',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (onEdit != null) ...[
                            GestureDetector(
                              onTap: onEdit,
                              child: const Icon(Icons.edit_rounded,
                                  size: 15, color: AppColors.muted),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (_assignedMember != null && _checkedInMembers.isEmpty)
                            Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: _assignedMember!.color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _assignedMember!.initials.substring(0, 1),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _assignedMember!.name.split(' ').first,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (stop.confirmationNumber != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number_outlined,
                                size: 12, color: AppColors.muted),
                            const SizedBox(width: 4),
                            Text(
                              'Ref: ${stop.confirmationNumber}',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // ── Check-In / Undo button ─────────────────────────────
                      if (onCheckIn != null) ...[
                        const SizedBox(height: 10),
                        _CheckInButton(
                          completed: completed,
                          onTap: onCheckIn!,
                        ),
                      ],
                    ],
                  ),
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
      child: Text(
        stop.status.label,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: stop.status.color,
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final min = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Checked-in member row
// ─────────────────────────────────────────────────────────────────────────────

class _CheckedInMemberRow extends StatelessWidget {
  final List<MemberModel> members;
  const _CheckedInMemberRow({required this.members});

  @override
  Widget build(BuildContext context) {
    final visible = members.take(4).toList();
    return Row(
      children: [
        // Avatar stack
        SizedBox(
          width: visible.length * 14.0 + 8,
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
                      color: AppColors.greenLight.withValues(alpha: 0.8),
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
        const SizedBox(width: 8),
        Text(
          members.length == 1
              ? '${members.first.name.split(' ').first} is here'
              : '${members.map((m) => m.name.split(' ').first).take(2).join(', ')} ${members.length > 2 ? '+${members.length - 2} here' : 'are here'}',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.greenBright,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated check-in / undo button
// ─────────────────────────────────────────────────────────────────────────────

class _CheckInButton extends StatelessWidget {
  final bool completed;
  final VoidCallback onTap;

  const _CheckInButton({required this.completed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: completed
              ? AppColors.greenBright.withValues(alpha: 0.12)
              : AppColors.greenBright,
          borderRadius: BorderRadius.circular(12),
          border: completed
              ? Border.all(
                  color: AppColors.greenBright.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              completed
                  ? Icons.undo_rounded
                  : Icons.check_circle_outline_rounded,
              size: 16,
              color: completed ? AppColors.greenBright : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              completed ? 'Undo Check-In' : '✓ Mark Arrived',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: completed ? AppColors.greenBright : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
