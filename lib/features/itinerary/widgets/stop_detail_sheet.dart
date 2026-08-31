import 'package:flutter/material.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/member_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/multi_member_picker_sheet.dart';
import 'navigate_route_button.dart';

/// Full-detail bottom sheet for an itinerary stop (IDEA-007).
///
/// Features:
/// - Top-right Edit and Dismiss actions in header
/// - Hero "Mark as Arrived" self check-in CTA with arrival time & undo
/// - Dedicated "Members" arrival hub with interactive companion arrival roster & batch check-in
/// - 1-tap Google Maps navigation & expense logging shortcut
/// - Booking reference & attachments
class StopDetailSheet extends StatefulWidget {
  final ItineraryStop stop;
  final List<MemberModel> members;
  final VoidCallback onEdit;
  final VoidCallback? onLogExpense;
  /// Toggles self check-in for the current user.
  final VoidCallback? onCheckIn;
  /// Toggles arrival presence for a specific member.
  final void Function(String memberId)? onMemberToggle;
  /// Marks all group members as arrived in batch.
  final VoidCallback? onMarkAllArrived;
  final String? currentUserId;
  final bool canManage;

  const StopDetailSheet({
    super.key,
    required this.stop,
    required this.members,
    required this.onEdit,
    this.onLogExpense,
    this.onCheckIn,
    this.onMemberToggle,
    this.onMarkAllArrived,
    this.currentUserId,
    this.canManage = false,
  });

  @override
  State<StopDetailSheet> createState() => _StopDetailSheetState();
}

class _StopDetailSheetState extends State<StopDetailSheet> {
  bool _isRosterExpanded = false;

  bool get _isSelfArrived {
    final selfId = widget.currentUserId ??
        (widget.members.isNotEmpty ? widget.members.first.id : 'me');
    return widget.stop.checkedInMemberIds.contains(selfId) ||
        widget.stop.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;
    final members = widget.members;
    final hasPhotos = stop.photoUrls.isNotEmpty;
    final totalMembers = members.length;
    final checkedInCount = stop.checkedInMemberIds.length;
    final allArrived = totalMembers > 0 && checkedInCount >= totalMembers;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
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
          // ── Drag Handle ───────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 14, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header Bar: Category, Title, Edit, Close ───────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.title,
                        style: const TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepEarth,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (stop.startTime != null)
                        Text(
                          '${_formatTime(stop.startTime!)}${stop.duration.isNotEmpty ? ' · ${stop.duration}' : ''}',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                // Top-right Edit button
                GestureDetector(
                  onTap: widget.onEdit,
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
                            size: 13, color: AppColors.primary),
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
                const SizedBox(width: 6),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: AppColors.muted),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Scrollable Body Content ────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Photo Gallery Carousel (if available)
                  if (hasPhotos) ...[
                    SizedBox(
                      height: 180,
                      child: PageView.builder(
                        itemCount: stop.photoUrls.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
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
                    const SizedBox(height: 16),
                  ],

                  // 2. Canonical "Mark as Arrived" Hero CTA (Self Check-In)
                  if (widget.onCheckIn != null) ...[
                    _buildHeroArrivalButton(),
                    const SizedBox(height: 14),
                  ],

                  // 3. Dedicated "Members" Arrival Hub & Roster (for group trips)
                  if (members.length > 1) ...[
                    _buildMembersArrivalHub(totalMembers, checkedInCount, allArrived),
                    const SizedBox(height: 14),
                  ],

                  // 4. Primary Actions (Navigate & Log Expense)
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
                            icon: const Icon(Icons.directions_rounded, size: 18),
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
                      if (widget.onLogExpense != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: widget.onLogExpense,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.amberText,
                                side: const BorderSide(
                                    color: AppColors.amber, width: 1.2),
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
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 5. Metadata Info Rows (Location, Cost, Booking Ref)
                  if (stop.location != null)
                    _infoRow(Icons.place_outlined, stop.location!),
                  if (stop.estimatedCost != null)
                    _infoRow(
                      Icons.attach_money_rounded,
                      '₱${stop.estimatedCost!.toInt()} estimated cost',
                    ),
                  if (stop.confirmationNumber != null)
                    _infoRow(
                      Icons.confirmation_number_outlined,
                      'Booking Reference: ${stop.confirmationNumber}',
                    ),

                  // 6. Notes
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.dividerLight),
                      ),
                      child: Text(
                        stop.notes!,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: AppColors.deepEarth,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],

                  // 7. Booking Attachments
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero "Mark as Arrived" Button ──────────────────────────────────────────

  Widget _buildHeroArrivalButton() {
    final arrived = _isSelfArrived;
    final stop = widget.stop;

    return GestureDetector(
      onTap: widget.onCheckIn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: arrived
              ? AppColors.greenBright.withValues(alpha: 0.12)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          border: arrived
              ? Border.all(
                  color: AppColors.greenBright.withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
          boxShadow: arrived
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              arrived
                  ? Icons.check_circle_rounded
                  : Icons.location_on_rounded,
              size: 18,
              color: arrived ? AppColors.greenBright : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              arrived
                  ? (stop.arrivedAtLabel != null
                      ? '✓ You ${stop.arrivedAtLabel!} · Tap to Undo'
                      : '✓ You Arrived · Tap to Undo')
                  : '📍 Mark as Arrived (You)',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: arrived ? AppColors.greenBright : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Members Arrival Hub & Companion Roster ─────────────────────────────────

  Widget _buildMembersArrivalHub(
      int totalMembers, int checkedInCount, bool allArrived) {
    final stop = widget.stop;
    final members = widget.members;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        children: [
          // Expandable Trigger Header
          InkWell(
            onTap: () => setState(() => _isRosterExpanded = !_isRosterExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: allArrived
                          ? AppColors.greenBright.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_alt_rounded,
                      size: 16,
                      color: allArrived
                          ? AppColors.greenBright
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Members ($checkedInCount/$totalMembers Arrived)',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: allArrived
                                ? AppColors.greenBright
                                : AppColors.deepEarth,
                          ),
                        ),
                        Text(
                          allArrived
                              ? 'All companions present'
                              : '${totalMembers - checkedInCount} companions not yet arrived',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Overlapping avatar stack preview
                  if (stop.checkedInMemberIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: MemberAvatarStack(
                        members: members,
                        memberIds: stop.checkedInMemberIds,
                        size: 22,
                        maxVisible: 3,
                      ),
                    ),
                  Icon(
                    _isRosterExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Companion Roster
          if (_isRosterExpanded) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // List of members with arrival toggles
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final member = members[idx];
                      final isPresent =
                          stop.checkedInMemberIds.contains(member.id);
                      final formattedName = MemberModel.formatDisplayName(
                        member.name,
                        hideSurname: member.hideSurname,
                      );

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isPresent
                              ? AppColors.greenLight.withValues(alpha: 0.4)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPresent
                                ? AppColors.greenBright.withValues(alpha: 0.3)
                                : AppColors.dividerLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Member Avatar
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: member.color,
                                shape: BoxShape.circle,
                                border: isPresent
                                    ? Border.all(
                                        color: AppColors.greenBright,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                member.initials.isNotEmpty
                                    ? member.initials.substring(0, 1)
                                    : '?',
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Member Name & Status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formattedName,
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.deepEarth,
                                    ),
                                  ),
                                  Text(
                                    isPresent
                                        ? '✓ Arrived'
                                        : 'Not yet arrived',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11,
                                      color: isPresent
                                          ? AppColors.greenBright
                                          : AppColors.muted,
                                      fontWeight: isPresent
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 1-Tap Toggle Action Button
                            if (widget.onMemberToggle != null)
                              GestureDetector(
                                onTap: () =>
                                    widget.onMemberToggle!(member.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isPresent
                                        ? AppColors.greenBright
                                            .withValues(alpha: 0.12)
                                        : AppColors.sand,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isPresent
                                          ? AppColors.greenBright
                                              .withValues(alpha: 0.4)
                                          : AppColors.primary
                                              .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPresent
                                            ? Icons.check_rounded
                                            : Icons.add_rounded,
                                        size: 13,
                                        color: isPresent
                                            ? AppColors.greenBright
                                            : AppColors.primary,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        isPresent ? 'Undo' : 'Mark Arrived',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isPresent
                                              ? AppColors.greenBright
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Batch Shortcut: "Mark Everyone as Arrived"
                  if (!allArrived && widget.onMarkAllArrived != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: widget.onMarkAllArrived,
                        icon: const Icon(Icons.done_all_rounded,
                            size: 16, color: AppColors.primary),
                        label: const Text(
                          'Mark Everyone as Arrived',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final min = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }
}
