import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_responsive.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/providers/realtime_provider.dart';
import '../../core/providers/friend_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/models/member_model.dart';
import '../../core/models/trip_model.dart';
import '../../core/services/module_view_tracker_service.dart';
import '../../core/widgets/buttons/app_back_button.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/feedback/app_feedback.dart';
import '../../core/widgets/feedback/app_dialog.dart';
import '../../core/widgets/member_avatar_circle.dart';

class MembersScreen extends ConsumerStatefulWidget {
  final bool showHeader;
  const MembersScreen({super.key, this.showHeader = true});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(activeTripProvider);

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return const Scaffold(body: Center(child: Text('Trip not found')));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ModuleViewTrackerService.instance.markViewed('members', trip.id);
        });

        ref.watch(membersRealtimeProvider(trip.id));

        final allMembers = trip.members;
        final pendingMembers = allMembers.where((m) => m.status == MemberStatus.pending).toList();
        final approvedMembers = allMembers.where((m) => m.status == MemberStatus.approved).toList();

        final currentMember = ref.watch(currentMemberProvider(trip));
        // Non-owners can leave the trip
        final isOwner = currentMember?.isTripCreator(trip.ownerId) ?? false;
        final canManageMembers = (currentMember?.canManageMembers ?? false) || isOwner;
        final canLeave = !isOwner && currentMember != null;

        return Scaffold(
          backgroundColor: AppColors.deepEarth,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showHeader)
                Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    MediaQuery.paddingOf(context).top + 16,
                    24,
                    24,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (Navigator.canPop(context))
                        const AppBackButton(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Members', style: TextStyle(fontFamily: AppTextStyles.fontHeading, fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text('${approvedMembers.length} travelers · ${trip.name}', style: const TextStyle( fontSize: 13, color: Colors.white54)),
                          ],
                        ),
                      ),
                      // Leave Trip button for non-owners
                      if (canLeave)
                        GestureDetector(
                          onTap: () => _confirmLeaveTrip(context, trip.id, trip.name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.red.withValues(alpha: 0.35), width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.logout_rounded, size: 14, color: AppColors.red),
                                SizedBox(width: 5),
                                Text('Leave', style: TextStyle( fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.red)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                  ),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, context.safeBottomPadding(120)),
                    children: [
                      _buildInviteCard(context, trip),
                      const SizedBox(height: 20),

                      if (pendingMembers.isNotEmpty) ...[
                        const Text('PENDING APPROVAL', style: TextStyle( fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.amber, letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        ...pendingMembers.map((m) => _PendingMemberCard(
                          member: m,
                          onApprove: () => _handleApprove(context, trip.id, m),
                          onReject: () => _handleReject(context, trip.id, m),
                        )),
                        const SizedBox(height: 20),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TRIP MEMBERS', style: TextStyle( fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warmMuted, letterSpacing: 1.5)),
                          if (canManageMembers && approvedMembers.length > 1)
                            GestureDetector(
                              onTap: () => _showBatchRoleEditor(context, trip.id, approvedMembers),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tune_rounded, size: 12, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Batch Assign',
                                      style: TextStyle(
                                        fontSize: 11,
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
                      const SizedBox(height: 12),
                      ...approvedMembers.map((m) {
                        final isCreator = m.isTripCreator(trip.ownerId);
                        return _MemberCard(
                          member: m,
                          isCreator: isCreator,
                          canEditRoles: canManageMembers,
                          // Organizers can remove non-creator members
                          canRemove: canManageMembers && !isCreator,
                          onEditRoles: () => _showRoleEditor(context, trip.id, m, canRemove: canManageMembers && !isCreator),
                          onContact: () => _showContactSheet(context, m),
                          onRemove: () => _confirmRemoveMember(context, trip.id, trip.name, m),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const MembersScreenSkeleton(),
      error: (e, _) => Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: Text('Error: $e'))),
    );
  }

  // ── Action Handlers ──────────────────────────────────────────────────────────

  Future<void> _handleApprove(BuildContext context, String tripId, MemberModel member) async {
    try {
      await ref.read(tripRepositoryProvider).approveMember(tripId, member.id);
      ref.invalidate(selectedTripProvider);
      ref.invalidate(allTripsProvider);
      if (context.mounted) {
        AppFeedback.showSuccess(
          context,
          '${member.name} has been added to the trip! 🎉',
          title: 'Member Approved',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(
          context,
          'Failed to approve: $e',
          title: 'Approval Failed',
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, String tripId, MemberModel member) async {
    try {
      await ref.read(tripRepositoryProvider).rejectMember(tripId, member.id);
      ref.invalidate(selectedTripProvider);
      ref.invalidate(allTripsProvider);
      if (context.mounted) {
        AppFeedback.showInfo(
          context,
          'Request from ${member.name} was declined.',
          title: 'Request Declined',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(
          context,
          'Failed to decline request: $e',
          title: 'Decline Failed',
        );
      }
    }
  }

  Future<void> _confirmRemoveMember(BuildContext context, String tripId, String tripName, MemberModel member) async {
    final confirm = await AppDialog.showDestructive(
      context,
      title: 'Remove Member',
      message: 'Remove ${member.name} from "$tripName"?\n\nTheir assigned tasks and expenses will remain recorded.',
      confirmLabel: 'Remove Member',
    );
    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(tripRepositoryProvider).removeMember(tripId, member.id);
      ref.invalidate(selectedTripProvider);
      ref.invalidate(allTripsProvider);
      if (context.mounted) {
        AppFeedback.showInfo(
          context,
          '${member.name} was removed from the trip.',
          title: 'Member Removed',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(
          context,
          'Failed to remove: $e',
          title: 'Action Failed',
        );
      }
    }
  }

  Future<void> _confirmLeaveTrip(BuildContext context, String tripId, String tripName) async {
    final confirm = await AppDialog.showDestructive(
      context,
      title: 'Leave Trip',
      message: 'Are you sure you want to leave "$tripName"? You will need a new invite code to rejoin.',
      confirmLabel: 'Leave Trip',
      icon: Icons.exit_to_app_rounded,
    );
    if (confirm != true || !context.mounted) return;

    try {
      final leftTripName = await ref.read(tripRepositoryProvider).leaveTrip(tripId);
      ref.invalidate(allTripsProvider);
      ref.invalidate(selectedTripProvider);
      if (context.mounted) {
        // Pop back to previous screen since user is no longer in this trip
        if (Navigator.canPop(context)) Navigator.pop(context);
        AppFeedback.showInfo(
          context,
          'You left "$leftTripName".',
          title: 'Trip Exited',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
          title: 'Failed to Leave Trip',
        );
      }
    }
  }

  Widget _buildInviteCard(BuildContext context, TripModel trip) {
    final code = trip.inviteCode.isNotEmpty ? trip.inviteCode : '------';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepEarth, Color(0xFF3D1F12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Trip Invite Code',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Share this code',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70)),
                    const Text('Anyone with this code can join instantly',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white38)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _iconBtn(Icons.copy_rounded, () {
                          if (trip.inviteCode.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: trip.inviteCode));
                            AppFeedback.showSuccess(
                              context,
                              'Invite code copied: ${trip.inviteCode}',
                              title: 'Copied to Clipboard 📋',
                            );
                          }
                        }),
                        const SizedBox(width: 8),
                        _iconBtn(Icons.share_rounded, () {
                          if (trip.inviteCode.isNotEmpty) {
                            SharePlus.instance.share(
                              ShareParams(
                                text: 'Join my trip "${trip.name}" on Tara Travel! Enter invite code: ${trip.inviteCode}',
                                subject: 'Trip Invite Code for ${trip.name}',
                              ),
                            );
                          }
                        }),
                        const SizedBox(width: 8),
                        _iconBtn(Icons.refresh_rounded, () async {
                          final confirm = await AppDialog.showConfirmation(
                            context,
                            title: 'Regenerate Invite Code?',
                            message: 'This will invalidate the existing invite code. Previous invites will no longer work.',
                            confirmLabel: 'Regenerate',
                            icon: Icons.refresh_rounded,
                          );

                          if (confirm == true && context.mounted) {
                            final newCode = await ref
                                .read(tripRepositoryProvider)
                                .regenerateInviteCode(trip.id);
                            ref.invalidate(selectedTripProvider);
                            ref.invalidate(allTripsProvider);
                            if (context.mounted) {
                              AppFeedback.showSuccess(
                                context,
                                'New invite code generated: $newCode',
                                title: 'Code Regenerated ✨',
                              );
                            }
                          }
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  void _showRoleEditor(BuildContext context, String tripId, MemberModel member, {bool canRemove = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoleEditorSheet(tripId: tripId, member: member, canRemove: canRemove),
    ).then((_) {
      // If roles changed or member was removed, refresh lists
      ref.invalidate(selectedTripProvider);
      ref.invalidate(allTripsProvider);
      ref.invalidate(activeTripProvider);
    });
  }

  void _showBatchRoleEditor(BuildContext context, String tripId, List<MemberModel> members) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BatchRoleEditorSheet(tripId: tripId, members: members),
    ).then((_) {
      ref.invalidate(selectedTripProvider);
      ref.invalidate(allTripsProvider);
      ref.invalidate(activeTripProvider);
    });
  }

  void _showContactSheet(BuildContext context, MemberModel member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactSheet(member: member),
    );
  }
}

class _PendingMemberCard extends StatelessWidget {
  final MemberModel member;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingMemberCard({required this.member, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: member.color, shape: BoxShape.circle),
            child: Center(child: Text(member.initials, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle( fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
                const SizedBox(height: 4),
                const Text('Wants to join', style: TextStyle( fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onReject,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 20, color: AppColors.red),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onApprove,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 20, color: AppColors.green),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final MemberModel member;
  final bool isCreator;
  final bool canEditRoles;
  final bool canRemove;
  final VoidCallback onEditRoles;
  final VoidCallback onContact;
  final VoidCallback? onRemove;

  const _MemberCard({
    required this.member,
    required this.isCreator,
    required this.canEditRoles,
    this.canRemove = false,
    required this.onEditRoles,
    required this.onContact,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.7),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5)),
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Stack(
            children: [
              MemberAvatarCircle(
                photoUrl: member.profilePhotoUrl,
                initials: member.initials,
                color: member.color,
                size: 48,
              ),
              // Online dot
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: member.isOnline ? AppColors.green : AppColors.muted,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepEarth,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCreator) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 10, color: AppColors.primary),
                            SizedBox(width: 2),
                            Text(
                              'Creator',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Role badges
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: member.roles.map((r) => _roleBadge(r)).toList(),
                ),
                if (member.gcashNumber != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    member.gcashNumber!,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              GestureDetector(
                onTap: onContact,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.call_outlined, size: 16, color: AppColors.blue),
                ),
              ),
              if (canEditRoles) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onEditRoles,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.chipBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                  ),
                ),
              ],
              // Remove button — only for organizers on non-creator members
              if (canRemove && onRemove != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_remove_outlined, size: 16, color: AppColors.red),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(MemberRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: role.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: role.color,
        ),
      ),
    );
  }
}

class _RoleEditorSheet extends ConsumerStatefulWidget {
  final String tripId;
  final MemberModel member;
  final bool canRemove;
  const _RoleEditorSheet({required this.tripId, required this.member, this.canRemove = false});

  @override
  ConsumerState<_RoleEditorSheet> createState() => _RoleEditorSheetState();
}

class _RoleEditorSheetState extends ConsumerState<_RoleEditorSheet> {
  late Set<MemberRole> _selectedRoles;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedRoles = Set.from(widget.member.roles);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.dividerLight,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Edit Roles — ${widget.member.name}',
              style: const TextStyle(
                  fontFamily: AppTextStyles.fontHeading,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepEarth)),
          const SizedBox(height: 6),
          const Text(
              'Members can have multiple roles simultaneously. Permissions update in real-time.',
              style: TextStyle( fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 20),
          ...MemberRole.values.map((role) => _roleCheckbox(role)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      try {
                        final repo = ref.read(tripRepositoryProvider);
                        final rolesList = _selectedRoles.isEmpty
                            ? [MemberRole.member]
                            : _selectedRoles.toList();
                        await repo.updateMemberRoles(
                            widget.tripId, widget.member.id, rolesList);
                        ref.invalidate(selectedTripProvider);
                        ref.invalidate(allTripsProvider);
                        ref.invalidate(activeTripProvider);
                        if (context.mounted) {
                          Navigator.pop(context);
                          AppFeedback.showSuccess(
                            context,
                            'Updated roles for ${widget.member.name}!',
                            title: 'Roles Updated ✨',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setState(() => _isSaving = false);
                          AppFeedback.showError(
                            context,
                            'Failed to update roles: ${e.toString().replaceAll('Exception: ', '')}',
                            title: 'Update Failed',
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes',
                      style: TextStyle( fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          // Remove Member — destructive, only for organizers on non-creator members
          if (widget.canRemove) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        Navigator.pop(context);
                        // Removal confirmation is handled by _confirmRemoveMember in the parent.
                        // We just pop and let the parent's onRemove callback handle it.
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.person_remove_outlined, size: 18),
                label: const Text('Remove from Trip',
                    style: TextStyle( fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _roleCheckbox(MemberRole role) {
    return CheckboxListTile(
      value: _selectedRoles.contains(role),
      onChanged: (v) {
        setState(() {
          if (v == true) {
            _selectedRoles.add(role);
          } else {
            if (_selectedRoles.length > 1) {
              _selectedRoles.remove(role);
            }
          }
        });
      },
      title: Text(role.displayName,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.deepEarth)),
      subtitle: Text(role.description,
          style: const TextStyle( fontSize: 11, color: AppColors.muted)),
      activeColor: role.color,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }
}

class _ContactSheet extends ConsumerWidget {
  final MemberModel member;
  const _ContactSheet({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.dividerLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: member.color, shape: BoxShape.circle),
            child: Center(child: Text(member.initials, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          const SizedBox(height: 12),
          Text(member.name, style: const TextStyle(fontFamily: AppTextStyles.fontHeading, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
          const SizedBox(height: 20),
          _contactRow(
            icon: Icons.person_add_rounded,
            action: 'Add as Friend',
            detail: 'Send a friend request to stay connected',
            color: AppColors.primary,
            onTap: () async {
              try {
                final friendRepo = ref.read(friendRepositoryProvider);
                await friendRepo.sendRequest(member.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  AppFeedback.showSuccess(
                    context,
                    'Friend request sent to ${member.name}!',
                    title: 'Request Sent',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.showError(
                    context,
                    'Could not send request: $e',
                    title: 'Request Failed',
                  );
                }
              }
            },
          ),
          _contactRow(
            icon: Icons.call_rounded,
            action: 'Call',
            detail: member.gcashNumber ?? '+63 912 000 0000',
            color: AppColors.green,
          ),
          _contactRow(
            icon: Icons.message_rounded,
            action: 'Message',
            detail: 'Open messaging app',
            color: AppColors.blue,
          ),
          if (member.gcashNumber != null)
            _contactRow(
              icon: Icons.account_balance_wallet_rounded,
              action: 'GCash',
              detail: member.gcashNumber!,
              color: const Color(0xFF0066CC),
            ),
        ],
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String action,
    required String detail,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action, style: TextStyle( fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                  Text(detail, style: const TextStyle( fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _BatchRoleEditorSheet extends ConsumerStatefulWidget {
  final String tripId;
  final List<MemberModel> members;
  const _BatchRoleEditorSheet({required this.tripId, required this.members});

  @override
  ConsumerState<_BatchRoleEditorSheet> createState() => _BatchRoleEditorSheetState();
}

class _BatchRoleEditorSheetState extends ConsumerState<_BatchRoleEditorSheet> {
  final Set<String> _selectedMemberIds = {};
  final Set<MemberRole> _selectedRoles = {MemberRole.member};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Batch Assign Roles',
            style: TextStyle(
              fontFamily: AppTextStyles.fontHeading,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.deepEarth,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select multiple members and assign common roles at once.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),

          // Select Members Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TARGET MEMBERS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warmMuted,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedMemberIds.length == widget.members.length) {
                      _selectedMemberIds.clear();
                    } else {
                      _selectedMemberIds.addAll(widget.members.map((m) => m.id));
                    }
                  });
                },
                child: Text(
                  _selectedMemberIds.length == widget.members.length ? 'Clear All' : 'Select All',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.members.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final m = widget.members[index];
                final active = _selectedMemberIds.contains(m.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (active) {
                        _selectedMemberIds.remove(m.id);
                      } else {
                        _selectedMemberIds.add(m.id);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? m.color : m.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? m.color : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (active) ...[
                          const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          m.name.split(' ').first,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : m.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.dividerLight),
          const SizedBox(height: 10),

          // Select Roles Section
          const Text(
            'SELECT ROLES TO APPLY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.warmMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          ...MemberRole.values.map((role) {
            return CheckboxListTile(
              value: _selectedRoles.contains(role),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedRoles.add(role);
                  } else {
                    if (_selectedRoles.length > 1) {
                      _selectedRoles.remove(role);
                    }
                  }
                });
              },
              title: Text(
                role.displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepEarth,
                ),
              ),
              subtitle: Text(
                role.description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
              activeColor: role.color,
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            );
          }),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_selectedMemberIds.isEmpty || _isSaving)
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      try {
                        final repo = ref.read(tripRepositoryProvider);
                        final rolesList = _selectedRoles.toList();
                        for (final memberId in _selectedMemberIds) {
                          await repo.updateMemberRoles(
                            widget.tripId,
                            memberId,
                            rolesList,
                          );
                        }
                        ref.invalidate(selectedTripProvider);
                        ref.invalidate(allTripsProvider);
                        ref.invalidate(activeTripProvider);
                        if (context.mounted) {
                          Navigator.pop(context);
                          AppFeedback.showSuccess(
                            context,
                            'Roles updated for ${_selectedMemberIds.length} members!',
                            title: 'Batch Update Complete ✨',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setState(() => _isSaving = false);
                          AppFeedback.showError(
                            context,
                            'Failed to batch update roles: ${e.toString().replaceAll('Exception: ', '')}',
                            title: 'Update Failed',
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _selectedMemberIds.isEmpty
                          ? 'Select members to apply'
                          : 'Apply Roles to ${_selectedMemberIds.length} Members',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
