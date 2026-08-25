import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/member_model.dart';

/// Modal bottom sheet allowing organizers to view and update group presence/roll-call for an itinerary stop.
class RollCallSheet extends StatefulWidget {
  final ItineraryStop stop;
  final List<MemberModel> members;
  final void Function(List<String> checkedInMemberIds) onSave;

  const RollCallSheet({
    super.key,
    required this.stop,
    required this.members,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required ItineraryStop stop,
    required List<MemberModel> members,
    required void Function(List<String> checkedInMemberIds) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RollCallSheet(
        stop: stop,
        members: members,
        onSave: onSave,
      ),
    );
  }

  @override
  State<RollCallSheet> createState() => _RollCallSheetState();
}

class _RollCallSheetState extends State<RollCallSheet> {
  late Set<String> _checkedInIds;

  @override
  void initState() {
    super.initState();
    _checkedInIds = Set<String>.from(widget.stop.checkedInMemberIds);
  }

  void _toggleMember(String memberId) {
    setState(() {
      if (_checkedInIds.contains(memberId)) {
        _checkedInIds.remove(memberId);
      } else {
        _checkedInIds.add(memberId);
      }
    });
  }

  void _checkInAll() {
    setState(() {
      _checkedInIds.addAll(widget.members.map((m) => m.id));
    });
  }

  void _clearAll() {
    setState(() {
      _checkedInIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.members.length;
    final checked = _checkedInIds.length;
    final allChecked = total > 0 && checked == total;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.dividerLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.greenBright.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people_alt_rounded, color: AppColors.greenBright, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Group Roll Call',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      Text(
                        '${widget.stop.title} · $checked of $total present',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: allChecked ? _clearAll : _checkInAll,
                  child: Text(
                    allChecked ? 'Clear All' : 'Select All',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Member presence list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: widget.members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final member = widget.members[index];
                final isPresent = _checkedInIds.contains(member.id);

                return GestureDetector(
                  onTap: () => _toggleMember(member.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isPresent
                          ? AppColors.greenLight.withValues(alpha: 0.4)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isPresent
                            ? AppColors.greenBright.withValues(alpha: 0.4)
                            : AppColors.dividerLight,
                        width: isPresent ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: member.color,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            member.initials.isNotEmpty ? member.initials.substring(0, 1) : '?',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name & Role
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepEarth,
                                  decoration: isPresent ? null : null,
                                ),
                              ),
                              Text(
                                isPresent
                                    ? 'Present · Checked in'
                                    : 'Not yet arrived',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  color: isPresent
                                      ? AppColors.greenBright
                                      : AppColors.muted,
                                  fontWeight: isPresent ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Checkmark
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isPresent ? AppColors.greenBright : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isPresent ? AppColors.greenBright : AppColors.muted,
                              width: 1.5,
                            ),
                          ),
                          child: isPresent
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(_checkedInIds.toList());
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Roll Call ($checked/$total)',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
