import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'profile_card.dart';

class ProfileHealthCard extends ConsumerStatefulWidget {
  const ProfileHealthCard({super.key});

  @override
  ConsumerState<ProfileHealthCard> createState() => _ProfileHealthCardState();
}

class _ProfileHealthCardState extends ConsumerState<ProfileHealthCard> {
  final _healthCtrl = TextEditingController();

  @override
  void dispose() {
    _healthCtrl.dispose();
    super.dispose();
  }

  void _editBloodType(BuildContext context, ProfileState profile) {
    const List<String> bloodTypes = [
      'A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−', 'Unknown',
    ];
    String? selected = profile.bloodType;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setBS) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 18,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Select Blood Type',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontHeading,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose your blood type from the dropdown below.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: (selected != null && bloodTypes.contains(selected))
                    ? selected
                    : null,
                decoration: InputDecoration(
                  hintText: 'Select blood type...',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppColors.warmMuted,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                items: bloodTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setBS(() {
                    selected = val;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(profileProvider.notifier).updateBloodType(null);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Clear',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(profileProvider.notifier).updateBloodType(selected);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addHealthNote(BuildContext context) {
    _healthCtrl.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Health Note',
            style: TextStyle(fontFamily: AppTextStyles.fontHeading)),
        content: TextField(
          controller: _healthCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Shellfish allergy, Asthmatic...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_healthCtrl.text.trim().isNotEmpty) {
                ref.read(profileProvider.notifier).addHealthNote(_healthCtrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionTitle('HEALTH & ALLERGY INFO'),
        ProfileCard(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Private by default. Share with Organizer when needed.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),

                  // Blood Type Row
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _editBloodType(context, profile),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.favorite_border_rounded,
                              size: 14,
                              color: Color(0xFFE53935),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Blood Type',
                                    style: TextStyle(fontSize: 11, color: AppColors.warmMuted)),
                                Text(
                                  profile.bloodType ?? 'Tap to select',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: profile.bloodType != null
                                        ? const Color(0xFFE53935)
                                        : AppColors.warmMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.warmMuted.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const ProfileDivider(),
                  const SizedBox(height: 12),

                  if (profile.healthNotes.isEmpty)
                    const Text('No health notes added',
                        style: TextStyle(fontSize: 13, color: AppColors.warmMuted))
                  else
                    ...profile.healthNotes.map((note) => _HealthTag(
                          label: note,
                          onRemove: () =>
                              ref.read(profileProvider.notifier).removeHealthNote(note),
                        )),
                  const SizedBox(height: 10),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _addHealthNote(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Add health note',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const ProfileDivider(),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share with Organizer',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Organizer can see this per trip',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: profile.shareHealthWithOrganizer,
                        onChanged: (v) =>
                            ref.read(profileProvider.notifier).toggleShareHealth(v),
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primaryLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HealthTag extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _HealthTag({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.health_and_safety_outlined, size: 13, color: AppColors.red),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.red,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 13, color: AppColors.red),
          ),
        ],
      ),
    );
  }
}
