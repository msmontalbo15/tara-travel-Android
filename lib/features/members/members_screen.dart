import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/providers/realtime_provider.dart';
import '../../core/providers/friend_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/models/member_model.dart';
import '../../core/models/trip_model.dart';
import '../../core/widgets/buttons/app_back_button.dart';
import '../../core/widgets/shimmer_loading.dart';

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
        
        ref.watch(membersRealtimeProvider(trip.id));

        final allMembers = trip.members;
        final pendingMembers = allMembers.where((m) => m.status == MemberStatus.pending).toList();
        final approvedMembers = allMembers.where((m) => m.status == MemberStatus.approved).toList();

        final currentMember = ref.watch(currentMemberProvider(trip));
        final canManageMembers = currentMember?.canManageMembers ?? true;

        return Scaffold(
          backgroundColor: AppColors.deepEarth,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showHeader)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
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
                            const Text('Members', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text('${approvedMembers.length} travelers · ${trip.name}', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: Colors.white54)),
                          ],
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    children: [
                      // Invite code card
                      _buildInviteCard(context, trip),
                      const SizedBox(height: 20),
                      
                      if (pendingMembers.isNotEmpty) ...[
                        const Text('PENDING APPROVAL', style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.amber, letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        ...pendingMembers.map((m) => _PendingMemberCard(
                          member: m,
                          onApprove: () async {
                            await ref.read(tripRepositoryProvider).approveMember(trip.id, m.id);
                            ref.invalidate(selectedTripProvider);
                            ref.invalidate(allTripsProvider);
                          },
                          onReject: () async {
                            await ref.read(tripRepositoryProvider).rejectMember(trip.id, m.id);
                            ref.invalidate(selectedTripProvider);
                            ref.invalidate(allTripsProvider);
                          },
                        )),
                        const SizedBox(height: 20),
                      ],

                      const Text('TRIP MEMBERS', style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warmMuted, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      ...approvedMembers.map((m) => _MemberCard(
                        member: m,
                        isCreator: m.isTripCreator(trip.ownerId),
                        canEditRoles: canManageMembers,
                        onEditRoles: () => _showRoleEditor(context, trip.id, m),
                        onContact: () => _showContactSheet(context, m),
                      )),
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
                      fontFamily: 'DM Sans',
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
                      fontFamily: 'DM Sans',
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
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: Colors.white70)),
                    const Text('Anyone with this code can join instantly',
                        style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            color: Colors.white38)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _iconBtn(Icons.copy_rounded, () {
                          if (trip.inviteCode.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: trip.inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invite code copied to clipboard!',
                                    style: TextStyle(fontFamily: 'DM Sans')),
                                backgroundColor: AppColors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
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
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Regenerate Invite Code?'),
                              content: const Text(
                                  'This will invalidate the existing invite code. Previous invites will no longer work.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Regenerate',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            final newCode = await ref
                                .read(tripRepositoryProvider)
                                .regenerateInviteCode(trip.id);
                            ref.invalidate(selectedTripProvider);
                            ref.invalidate(allTripsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('New invite code generated: $newCode',
                                      style: const TextStyle(fontFamily: 'DM Sans')),
                                  backgroundColor: AppColors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
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

  void _showRoleEditor(BuildContext context, String tripId, MemberModel member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoleEditorSheet(tripId: tripId, member: member),
    );
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
                Text(member.name, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
                const SizedBox(height: 4),
                const Text('Wants to join', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.muted)),
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
  final VoidCallback onEditRoles;
  final VoidCallback onContact;

  const _MemberCard({
    required this.member,
    required this.isCreator,
    required this.canEditRoles,
    required this.onEditRoles,
    required this.onContact,
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
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(color: member.color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    member.initials,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
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
                          fontFamily: 'DM Sans',
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
                                fontFamily: 'DM Sans',
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
                        fontFamily: 'DM Sans',
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
                  child: const Icon(Icons.call_outlined,
                      size: 16, color: AppColors.blue),
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
                    child: const Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.primary),
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
          fontFamily: 'DM Sans',
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
  const _RoleEditorSheet({required this.tripId, required this.member});

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
                  fontFamily: 'Playfair Display',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepEarth)),
          const SizedBox(height: 6),
          const Text(
              'Members can have multiple roles simultaneously. Permissions update in real-time.',
              style: TextStyle(
                  fontFamily: 'DM Sans', fontSize: 12, color: AppColors.muted)),
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
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Updated roles for ${widget.member.name}!',
                                  style:
                                      const TextStyle(fontFamily: 'DM Sans')),
                              backgroundColor: AppColors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setState(() => _isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update roles: $e',
                                  style:
                                      const TextStyle(fontFamily: 'DM Sans')),
                              backgroundColor: AppColors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
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
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes',
                      style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
            ),
          ),
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
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.deepEarth)),
      subtitle: Text(role.description,
          style: const TextStyle(
              fontFamily: 'DM Sans', fontSize: 11, color: AppColors.muted)),
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
          Text(member.name, style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Friend request sent to ${member.name}!', style: const TextStyle(fontFamily: 'DM Sans')),
                      backgroundColor: AppColors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not send request: $e', style: const TextStyle(fontFamily: 'DM Sans')),
                      backgroundColor: AppColors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
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
                  Text(action, style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                  Text(detail, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.muted)),
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
