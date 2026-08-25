import 'package:flutter/material.dart';
import '../../../core/models/member_model.dart';
import '../../../core/models/packing_model.dart';
import '../../../core/widgets/multi_member_picker_sheet.dart';

/// Multi-select member assignment sheet for a packing item.
///
/// Replaces the old single-select sheet. Calls [onSelectMembers] with the
/// chosen members (empty list = unassigned / shared).
class MemberAssignmentSheet extends StatelessWidget {
  final PackingItem item;
  final List<MemberModel> members;
  final void Function(List<MemberModel>) onSelectMembers;

  // Legacy single-select compat shim.
  // ignore: avoid_init_to_null
  final ValueChanged<MemberModel?>? onSelectMember;

  const MemberAssignmentSheet({
    super.key,
    required this.item,
    required this.members,
    required this.onSelectMembers,
    this.onSelectMember,
  });

  static Future<void> show(
    BuildContext context, {
    required PackingItem item,
    required List<MemberModel> members,
    required void Function(List<MemberModel>) onSelectMembers,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MultiMemberPickerSheet(
        title: 'Assign Packing Item',
        subtitle: item.name,
        members: members,
        initialSelection: item.assignedMemberIds,
        onConfirm: onSelectMembers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiMemberPickerSheet(
      title: 'Assign Packing Item',
      subtitle: item.name,
      members: members,
      initialSelection: item.assignedMemberIds,
      onConfirm: onSelectMembers,
    );
  }
}
