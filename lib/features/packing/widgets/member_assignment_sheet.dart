import 'package:flutter/material.dart';
import '../../../core/models/member_model.dart';
import '../../../core/models/packing_model.dart';
import '../../../core/theme/app_colors.dart';

class MemberAssignmentSheet extends StatelessWidget {
  final PackingItem item;
  final List<MemberModel> members;
  final ValueChanged<MemberModel?> onSelectMember;

  const MemberAssignmentSheet({
    super.key,
    required this.item,
    required this.members,
    required this.onSelectMember,
  });

  static Future<void> show(
    BuildContext context, {
    required PackingItem item,
    required List<MemberModel> members,
    required ValueChanged<MemberModel?> onSelectMember,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MemberAssignmentSheet(
        item: item,
        members: members,
        onSelectMember: onSelectMember,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title & Item Name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign Packing Item',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.dividerLight, height: 1),
            const SizedBox(height: 12),

            // Option 1: Unassigned / Everyone's Responsibility
            _buildOptionTile(
              context: context,
              title: "Everyone's Responsibility",
              subtitle: 'Shared item / anyone can bring this',
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.groups_rounded,
                    color: AppColors.muted, size: 22),
              ),
              isSelected: !item.isAssigned,
              onTap: () {
                Navigator.pop(context);
                onSelectMember(null);
              },
            ),

            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Text(
                'TRIP MEMBERS',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.warmMuted,
                ),
              ),
            ),

            // Member list
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No other members in this trip yet.',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final m = members[index];
                    final isSelected = item.assignedMemberId == m.id;
                    return _buildOptionTile(
                      context: context,
                      title: m.name,
                      subtitle: m.roles.isNotEmpty
                          ? m.roles.first.displayName
                          : 'Trip Member',
                      roleColor: m.roles.isNotEmpty
                          ? m.roles.first.color
                          : AppColors.muted,
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: m.color,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: m.color.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            m.initials,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      isSelected: isSelected,
                      onTap: () {
                        Navigator.pop(context);
                        onSelectMember(m);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget leading,
    required bool isSelected,
    required VoidCallback onTap,
    Color? roleColor, // optional role badge color
  }) {
    final effectiveRoleColor = roleColor ?? AppColors.muted;
    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.08)
          : const Color(0xFFFAFAFA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.dividerLight.withValues(alpha: 0.6),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.deepEarth,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Role badge pill
                    if (roleColor != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: effectiveRoleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: effectiveRoleColor.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : effectiveRoleColor,
                          ),
                        ),
                      )
                    else
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.8)
                              : AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
