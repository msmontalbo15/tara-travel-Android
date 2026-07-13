import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/realtime_provider.dart';
import '../../core/models/member_model.dart';
import '../../core/models/trip_model.dart';

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
        
        // Listen to live realtime stream for trip members
        ref.watch(membersRealtimeProvider(trip.id));

        final members = trip.members;
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
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Members', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text('${members.length} travelers · ${trip.name}', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: Colors.white54)),
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
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    children: [
                      // Invite code card
                      _buildInviteCard(context, trip),
                      const SizedBox(height: 20),
                      const Text('TRIP MEMBERS', style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warmMuted, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      ...members.map((m) => _MemberCard(
                        member: m,
                        onEditRoles: () => _showRoleEditor(context, m, members),
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
      loading: () => const Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildInviteCard(BuildContext context, TripModel trip) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.deepEarth, Color(0xFF3D1F12)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Trip Invite Code', style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(trip.inviteCode, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Share this code', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Colors.white70)),
                    const Text('Anyone with this code can join instantly', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: Colors.white38)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _iconBtn(Icons.copy_rounded, () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!', style: TextStyle(fontFamily: 'DM Sans')), backgroundColor: AppColors.green, behavior: SnackBarBehavior.floating));
                        }),
                        const SizedBox(width: 8),
                        _iconBtn(Icons.share_rounded, () {}),
                        const SizedBox(width: 8),
                        _iconBtn(Icons.refresh_rounded, () {}),
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
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  void _showRoleEditor(BuildContext context, MemberModel member, List<MemberModel> allMembers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoleEditorSheet(member: member),
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

class _MemberCard extends StatelessWidget {
  final MemberModel member;
  final VoidCallback onEditRoles;
  final VoidCallback onContact;

  const _MemberCard({required this.member, required this.onEditRoles, required this.onContact});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
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
                decoration: BoxDecoration(color: member.color, shape: BoxShape.circle),
                child: Center(child: Text(member.initials, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
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
                Text(member.name, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
                const SizedBox(height: 4),
                // Role badges
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: member.roles.map((r) => _roleBadge(r)).toList(),
                ),
                if (member.gcashNumber != null) ...[
                  const SizedBox(height: 6),
                  Text(member.gcashNumber!, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.muted)),
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
                  decoration: BoxDecoration(color: AppColors.blueLight, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.call_outlined, size: 16, color: AppColors.blue),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onEditRoles,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: AppColors.chipBackground, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(MemberRole role) {
    Color color;
    String label;
    switch (role) {
      case MemberRole.organizer: color = AppColors.primary; label = 'Organizer'; break;
      case MemberRole.treasurer: color = AppColors.amber; label = 'Treasurer'; break;
      case MemberRole.navigator: color = AppColors.blue; label = 'Navigator'; break;
      case MemberRole.buyer: color = AppColors.green; label = 'Buyer'; break;
      case MemberRole.documenter: color = AppColors.purple; label = 'Documenter'; break;
      case MemberRole.member: color = AppColors.muted; label = 'Member'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _RoleEditorSheet extends StatefulWidget {
  final MemberModel member;
  const _RoleEditorSheet({required this.member});

  @override
  State<_RoleEditorSheet> createState() => _RoleEditorSheetState();
}

class _RoleEditorSheetState extends State<_RoleEditorSheet> {
  late Set<MemberRole> _selectedRoles;

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
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.dividerLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Edit Roles — ${widget.member.name}', style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
          const SizedBox(height: 6),
          const Text('Members can have multiple roles. Changes take effect immediately.', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 20),
          ...MemberRole.values.map((role) => _roleCheckbox(role)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Save Changes', style: TextStyle(fontFamily: 'DM Sans', fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleCheckbox(MemberRole role) {
    final descriptions = {
      MemberRole.organizer: 'Full control — manages trip, invites, approvals',
      MemberRole.treasurer: 'Approves expenses, manages GCash QR, confirms payments',
      MemberRole.navigator: 'Owns itinerary — adds, edits stops, plans routes',
      MemberRole.buyer: 'Logs expenses and purchases, submits receipts',
      MemberRole.documenter: 'Uploads photos, receipts, journal entries',
      MemberRole.member: 'Read-only access. Can check own packing list',
    };
    return CheckboxListTile(
      value: _selectedRoles.contains(role),
      onChanged: (v) => setState(() => v == true ? _selectedRoles.add(role) : _selectedRoles.remove(role)),
      title: Text(role.name[0].toUpperCase() + role.name.substring(1), style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.deepEarth)),
      subtitle: Text(descriptions[role] ?? '', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.muted)),
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }
}

class _ContactSheet extends StatelessWidget {
  final MemberModel member;
  const _ContactSheet({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
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
          _contactRow(Icons.call_rounded, 'Call', member.gcashNumber ?? '+63 912 000 0000', AppColors.green),
          _contactRow(Icons.message_rounded, 'Message', 'Open messaging app', AppColors.blue),
          if (member.gcashNumber != null)
            _contactRow(Icons.account_balance_wallet_rounded, 'GCash', member.gcashNumber!, const Color(0xFF0066CC)),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String action, String detail, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(action, style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600, color: color)),
              Text(detail, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}
