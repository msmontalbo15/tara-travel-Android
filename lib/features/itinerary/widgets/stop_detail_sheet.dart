import 'package:flutter/material.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/member_model.dart';
import '../../../core/theme/app_colors.dart';
import 'navigate_route_button.dart';

/// Full-detail bottom sheet for an itinerary stop, with photo gallery,
/// 1-tap Google Maps navigation, expense logging trigger, roll call sheet trigger,
/// and collaborative group voting.
class StopDetailSheet extends StatelessWidget {
  final ItineraryStop stop;
  final List<MemberModel> members;
  final void Function(StopStatus) onStatusChange;
  final void Function(String memberId, bool upvote) onVote;
  final VoidCallback onEdit;
  final VoidCallback? onLogExpense;
  final VoidCallback? onRollCall;

  const StopDetailSheet({
    super.key,
    required this.stop,
    required this.members,
    required this.onStatusChange,
    required this.onVote,
    required this.onEdit,
    this.onLogExpense,
    this.onRollCall,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhotos = stop.photoUrls.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 14, bottom: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Photo Gallery
          if (hasPhotos)
            SizedBox(
              height: 190,
              child: PageView.builder(
                itemCount: stop.photoUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(stop.photoUrls[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),

          if (hasPhotos) const SizedBox(height: 14),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Type + Edit Row
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: stop.type.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          stop.type.icon,
                          color: stop.type.color,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          stop.title,
                          style: const TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepEarth,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded,
                                  size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Metadata Info rows
                  if (stop.location != null)
                    _infoRow(Icons.place_outlined, stop.location!),
                  if (stop.estimatedCost != null)
                    _infoRow(
                      Icons.attach_money_rounded,
                      '₱${stop.estimatedCost!.toInt()} estimated',
                    ),
                  if (stop.confirmationNumber != null)
                    _infoRow(
                      Icons.confirmation_number_outlined,
                      'Ref: ${stop.confirmationNumber}',
                    ),

                  // 1-Tap Google Maps & Action Buttons
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                openGoogleMapsForStop(context, stop),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon:
                                const Icon(Icons.directions_rounded, size: 18),
                            label: const Text(
                              'Navigate Maps',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (onLogExpense != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: onLogExpense,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.amberText,
                                side: const BorderSide(color: AppColors.amber),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.receipt_long_rounded,
                                  size: 16),
                              label: const Text(
                                'Expense',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (onRollCall != null && members.length > 1) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: onRollCall,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.greenBright,
                              side: const BorderSide(
                                  color: AppColors.greenBright),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon:
                                const Icon(Icons.people_alt_rounded, size: 16),
                            label: Text(
                              'Roll Call (${stop.checkedInMemberIds.length}/${members.length})',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Notes
                  if (stop.notes != null && stop.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stop.notes!,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],

                  // Attachments
                  if (stop.attachmentUrls.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Attachments',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: stop.attachmentUrls.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.dividerLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.attach_file_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Attachment ${index + 1}',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Group Voting
                  const SizedBox(height: 14),
                  const Text(
                    'Group Vote',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _VoteButton(
                        icon: Icons.thumb_up_rounded,
                        count: stop.votes.values.where((v) => v).length,
                        color: const Color(0xFF10B981),
                        onTap: () {
                          if (members.isNotEmpty) {
                            onVote(members.first.id, true);
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      _VoteButton(
                        icon: Icons.thumb_down_rounded,
                        count: stop.votes.values.where((v) => !v).length,
                        color: const Color(0xFFEF4444),
                        onTap: () {
                          if (members.isNotEmpty) {
                            onVote(members.first.id, false);
                          }
                        },
                      ),
                      const Spacer(),
                      if (stop.voteScore != 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: stop.voteScore > 0
                                ? const Color(0xFF10B981)
                                    .withValues(alpha: 0.1)
                                : const Color(0xFFEF4444)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${stop.voteScore > 0 ? '+' : ''}${stop.voteScore} score',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: stop.voteScore > 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),
                  // Approve / Arrived actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            onStatusChange(StopStatus.approved);
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Approve',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.green,
                            side: const BorderSide(color: AppColors.green),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            onStatusChange(StopStatus.arrived);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.location_on_rounded, size: 16),
                          label: const Text(
                            'Arrived',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
