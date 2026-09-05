import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/models/trip_poll_model.dart';

/// Modal bottom sheet for creating interactive travel polls.
///
/// Features:
/// - Quick-start travel presets (🍽️ Dinner Spot, ⏰ Departure Time, 🏄 Next Activity, 💰 Budget Cap)
/// - Custom question input
/// - Dynamic options list (+ Add option, Remove option)
/// - Multi-select toggle
/// - Category selector
class CreatePollSheet extends StatefulWidget {
  final Future<void> Function({
    required String question,
    required List<String> options,
    required String category,
    required bool allowMultiple,
  }) onSubmit;

  const CreatePollSheet({super.key, required this.onSubmit});

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function({
      required String question,
      required List<String> options,
      required String category,
      required bool allowMultiple,
    }) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePollSheet(onSubmit: onSubmit),
    );
  }

  @override
  State<CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<CreatePollSheet> {
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  PollCategory _category = PollCategory.food;
  bool _allowMultiple = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyPreset(PollCategory cat, String question, List<String> defaults) {
    HapticFeedback.selectionClick();
    setState(() {
      _category = cat;
      _questionCtrl.text = question;
      // Dispose old option controllers
      for (final c in _optionCtrls) {
        c.dispose();
      }
      _optionCtrls.clear();
      for (final opt in defaults) {
        _optionCtrls.add(TextEditingController(text: opt));
      }
    });
  }

  void _addOption() {
    if (_optionCtrls.length >= 6) return;
    HapticFeedback.lightImpact();
    setState(() {
      _optionCtrls.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionCtrls.length <= 2) return;
    HapticFeedback.lightImpact();
    setState(() {
      _optionCtrls[index].dispose();
      _optionCtrls.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final question = _questionCtrl.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a poll question')),
      );
      return;
    }

    final options = _optionCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide at least 2 options')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        question: question,
        options: options,
        category: _category.dbValue,
        allowMultiple: _allowMultiple,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create poll: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: context.sheetMaxHeight(0.88),
      ),
      padding: EdgeInsets.only(bottom: context.keyboardHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Title Bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.how_to_vote_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Create Travel Poll',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepEarth,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.muted, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.dividerLight),

          // ── Content Form ────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Presets horizontal list
                  const Text(
                    'QUICK TRAVEL PRESETS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warmMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _PresetChip(
                          emoji: '🍽️',
                          label: 'Dinner Spot',
                          isSelected: _category == PollCategory.food,
                          onTap: () => _applyPreset(
                            PollCategory.food,
                            'Where should we eat for dinner tonight?',
                            ['Local Seafood Grill', 'Night Market Stalls', 'Cafe by the Beach'],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PresetChip(
                          emoji: '⏰',
                          label: 'Departure Time',
                          isSelected: _category == PollCategory.departure,
                          onTap: () => _applyPreset(
                            PollCategory.departure,
                            'What time should we meet at the lobby?',
                            ['6:30 AM (Early bird)', '8:00 AM (Standard)', '9:30 AM (Relaxed)'],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PresetChip(
                          emoji: '🏄',
                          label: 'Afternoon Activity',
                          isSelected: _category == PollCategory.activity,
                          onTap: () => _applyPreset(
                            PollCategory.activity,
                            'Which excursion should we book for tomorrow?',
                            ['Island Hopping Tour A', 'Scuba Diving Session', 'Sunset Paddleboarding'],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PresetChip(
                          emoji: '💰',
                          label: 'Shared Boat Rental',
                          isSelected: _category == PollCategory.budget,
                          onTap: () => _applyPreset(
                            PollCategory.budget,
                            'Private speedboat rental budget consensus:',
                            ['₱1,200 per head (Standard)', '₱1,800 per head (VIP fastcraft)'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Question input
                  const Text(
                    'QUESTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warmMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _questionCtrl,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.deepEarth,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Where should we eat dinner tonight?',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Options input list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'OPTIONS (2 TO 6)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warmMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (_optionCtrls.length < 6)
                        GestureDetector(
                          onTap: _addOption,
                          child: const Row(
                            children: [
                              Icon(Icons.add_circle_outline_rounded,
                                  size: 16, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Add Option',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._optionCtrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ctrl = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: TextField(
                                controller: ctrl,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.deepEarth,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Option ${index + 1}',
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.muted,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          if (_optionCtrls.length > 2) ...[
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded,
                                  color: AppColors.muted, size: 20),
                              onPressed: () => _removeOption(index),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  // Multi-select toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.checklist_rounded,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Allow multiple choices',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepEarth,
                                ),
                              ),
                              Text(
                                'Travelers can vote for more than one option',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _allowMultiple,
                          activeColor: AppColors.primary, // ignore: deprecated_member_use
                          onChanged: (v) => setState(() => _allowMultiple = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create Poll CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.how_to_vote_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Post Poll to Group Chat',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
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

class _PresetChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sand : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.deepEarth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
