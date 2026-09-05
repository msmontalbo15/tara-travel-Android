import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_responsive.dart';
import 'member_avatar_circle.dart';

/// A multi-select bottom sheet for picking one or more [MemberModel]s.
///
/// Usage:
/// ```dart
/// final selected = await MultiMemberPickerSheet.show(
///   context,
///   members: trip.members,
///   initialSelection: stop.assignedMemberIds,
///   title: 'Assign Members',
/// );
/// ```
class MultiMemberPickerSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<MemberModel> members;
  final List<String> initialSelection;
  final void Function(List<MemberModel> selected) onConfirm;
  final bool allowEmpty;

  const MultiMemberPickerSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.members,
    required this.initialSelection,
    required this.onConfirm,
    this.allowEmpty = true,
  });

  static Future<List<MemberModel>?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<MemberModel> members,
    required List<String> initialSelection,
    bool allowEmpty = true,
  }) async {
    List<MemberModel>? result;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MultiMemberPickerSheet(
        title: title,
        subtitle: subtitle,
        members: members,
        initialSelection: initialSelection,
        allowEmpty: allowEmpty,
        onConfirm: (sel) => result = sel,
      ),
    );
    return result;
  }

  @override
  State<MultiMemberPickerSheet> createState() => _MultiMemberPickerSheetState();
}

class _MultiMemberPickerSheetState extends State<MultiMemberPickerSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelection);
  }

  bool get _allSelected => widget.members.every((m) => _selected.contains(m.id));

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected = widget.members.map((m) => m.id).toSet();
      }
    });
  }

  void _toggle(String memberId) {
    setState(() {
      if (_selected.contains(memberId)) {
        _selected.remove(memberId);
      } else {
        _selected.add(memberId);
      }
    });
  }

  void _confirm() {
    final result = widget.members.where((m) => _selected.contains(m.id)).toList();
    Navigator.of(context).pop();
    widget.onConfirm(result);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ─────────────────────────────────────────────────
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

          // ── Header ─────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group_add_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontHeading,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepEarth,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              // Select All / Clear All toggle
              GestureDetector(
                onTap: _toggleAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _allSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _allSelected
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.dividerLight,
                    ),
                  ),
                  child: Text(
                    _allSelected ? 'Clear All' : 'Select All',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _allSelected ? AppColors.primary : AppColors.warmMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.dividerLight, height: 1),
          const SizedBox(height: 8),

          // ── Shared / unassigned option ─────────────────────────────
          _MemberPickerTile(
            title: "Everyone / Shared",
            subtitle: "No specific assignee",
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
            isSelected: _selected.isEmpty,
            onTap: () => setState(() => _selected.clear()),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Text(
              'TRIP MEMBERS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.warmMuted,
              ),
            ),
          ),

          // ── Member list ────────────────────────────────────────────
          if (widget.members.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No members in this trip yet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: context.sheetMaxHeight(0.38),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final m = widget.members[index];
                  final isSelected = _selected.contains(m.id);
                  return _MemberPickerTile(
                    title: m.name,
                    subtitle: m.roles.isNotEmpty
                        ? m.roles.first.displayName
                        : 'Trip Member',
                    roleColor: m.roles.isNotEmpty ? m.roles.first.color : null,
                    leading: MemberAvatarCircle(
                      photoUrl: m.profilePhotoUrl,
                      initials: m.initials,
                      color: m.color,
                      size: 42,
                    ),
                    isSelected: isSelected,
                    isMultiSelect: true,
                    onTap: () => _toggle(m.id),
                  );
                },
              ),
            ),

          const SizedBox(height: 14),

          // ── Confirm button ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _selected.isEmpty
                        ? 'Confirm (Shared)'
                        : 'Confirm (${_selected.length} selected)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Internal tile ─────────────────────────────────────────────────────────────

class _MemberPickerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final bool isSelected;
  final bool isMultiSelect;
  final VoidCallback onTap;
  final Color? roleColor;

  const _MemberPickerTile({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.isSelected,
    required this.onTap,
    this.isMultiSelect = false,
    this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
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
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.deepEarth,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (roleColor != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              effectiveRoleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                effectiveRoleColor.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          subtitle,
                          style: TextStyle(
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
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.8)
                              : AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              // Checkbox (multi) or radio (single)
              if (isMultiSelect)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.dividerLight,
                      width: 1.8,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)
                      : null,
                )
              else if (isSelected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable avatar stack for displaying multiple assignees ───────────────────

class MemberAvatarStack extends StatelessWidget {
  final List<MemberModel> members;
  final List<String> memberIds;
  final double size;
  final int maxVisible;

  const MemberAvatarStack({
    super.key,
    required this.members,
    required this.memberIds,
    this.size = 26,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    final assigned = members
        .where((m) => memberIds.contains(m.id))
        .take(maxVisible)
        .toList();
    final overflow = memberIds.length - assigned.length;

    if (assigned.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: size,
      width: size + (assigned.length - 1) * (size * 0.6) + (overflow > 0 ? size * 0.8 : 0),
      child: Stack(
        children: [
          for (int i = 0; i < assigned.length; i++)
            Positioned(
              left: i * (size * 0.6),
              child: MemberAvatarCircle(
                photoUrl: assigned[i].profilePhotoUrl,
                initials: assigned[i].initials,
                color: assigned[i].color,
                size: size,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: assigned.length * (size * 0.6),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.warmMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '+$overflow',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: size * 0.32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
