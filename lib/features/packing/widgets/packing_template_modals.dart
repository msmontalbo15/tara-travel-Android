import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../../../core/models/packing_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback/app_feedback.dart';

// ── Save Template Dialog / Modal ─────────────────────────────────────────────

class SaveTemplateModal extends StatefulWidget {
  final List<PackingCategory> categories;
  final int totalItems;
  final String defaultName;
  final Future<void> Function(String name, String icon) onSave;

  const SaveTemplateModal({
    super.key,
    required this.categories,
    required this.totalItems,
    required this.defaultName,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required List<PackingCategory> categories,
    required int totalItems,
    required String defaultName,
    required Future<void> Function(String name, String icon) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (_) => SaveTemplateModal(
        categories: categories,
        totalItems: totalItems,
        defaultName: defaultName,
        onSave: onSave,
      ),
    );
  }

  @override
  State<SaveTemplateModal> createState() => _SaveTemplateModalState();
}

class _SaveTemplateModalState extends State<SaveTemplateModal> {
  late final TextEditingController _nameCtrl;
  String _selectedIcon = '🎒';
  bool _isSaving = false;

  final List<String> _icons = ['🎒', '🏖️', '⛰️', '🏙️', '🚗', '✈️', '🏕️', '🌴'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: '${widget.defaultName} Essentials');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await widget.onSave(name, _selectedIcon);
      if (mounted) {
        Navigator.pop(context);
        AppFeedback.showSuccess(
          context,
          '🎉 Template "$name" saved successfully!',
          title: 'Template Saved',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppFeedback.showError(
          context,
          'Failed to save template: $e',
          title: 'Save Failed',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bookmark_add_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Save as Template',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontHeading,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepEarth,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Item count summary pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.sand.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saves ${widget.totalItems} items from this trip.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepEarth,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Template Name Field
            const Text(
              'Template Name',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.warmMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.deepEarth,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Beach Trip Essentials',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.dividerLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Icon Chips
            const Text(
              'Choose Icon',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.warmMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _icons.map((emoji) {
                  final isSel = _selectedIcon == emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = emoji),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Template',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Load Template Bottom Sheet ───────────────────────────────────────────────

class LoadTemplateSheet extends StatefulWidget {
  final List<PackingTemplate> templates;
  final Future<void> Function(PackingTemplate template) onApplyTemplate;
  final Future<void> Function(String templateId)? onDeleteTemplate;

  const LoadTemplateSheet({
    super.key,
    required this.templates,
    required this.onApplyTemplate,
    this.onDeleteTemplate,
  });

  static Future<void> show(
    BuildContext context, {
    required List<PackingTemplate> templates,
    required Future<void> Function(PackingTemplate template) onApplyTemplate,
    Future<void> Function(String templateId)? onDeleteTemplate,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LoadTemplateSheet(
        templates: templates,
        onApplyTemplate: onApplyTemplate,
        onDeleteTemplate: onDeleteTemplate,
      ),
    );
  }

  @override
  State<LoadTemplateSheet> createState() => _LoadTemplateSheetState();
}

class _LoadTemplateSheetState extends State<LoadTemplateSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _expandedTemplateId;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prebuilt = widget.templates.where((t) => t.isPrebuilt).toList();
    final custom = widget.templates.where((t) => !t.isPrebuilt).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
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

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.style_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Packing Templates',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontHeading,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      Text(
                        'Load ready-made or saved checklists into your trip',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tabs
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.deepEarth,
                unselectedLabelColor: AppColors.muted,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                tabs: [
                  Tab(text: 'Pre-built (${prebuilt.length})'),
                  Tab(text: 'My Saved (${custom.length})'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab View Lists
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildTemplateList(prebuilt, isPrebuiltList: true),
                  _buildTemplateList(custom, isPrebuiltList: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateList(
    List<PackingTemplate> list, {
    required bool isPrebuiltList,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border_rounded,
                size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              isPrebuiltList
                  ? 'No pre-built templates available.'
                  : 'No saved templates yet.\nTap "Save Template" to save your trip list!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tpl = list[index];
        final isExpanded = _expandedTemplateId == tpl.id;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isExpanded
                  ? AppColors.primary
                  : AppColors.dividerLight.withValues(alpha: 0.8),
              width: isExpanded ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template Row
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(tpl.icon, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                title: Text(
                  tpl.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepEarth,
                  ),
                ),
                subtitle: Text(
                  '${tpl.totalItemCount} items • ${tpl.itemsByCategory.length} categories',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.deepEarth,
                  ),
                  onPressed: () {
                    setState(() {
                      _expandedTemplateId = isExpanded ? null : tpl.id;
                    });
                  },
                ),
              ),

              if (tpl.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    tpl.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.warmMuted,
                    ),
                  ),
                ),

              // Expanded Item preview
              if (isExpanded) ...[
                const Divider(height: 1, color: AppColors.dividerLight),
                Container(
                  padding: const EdgeInsets.all(14),
                  color: const Color(0xFFFAFAFA),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHECKLIST PREVIEW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.warmMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...tpl.itemsByCategory.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ${_formatCatName(entry.key)}: ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepEarth,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value.join(', '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              // Actions Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.dividerLight, width: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    if (!tpl.isPrebuilt && widget.onDeleteTemplate != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: AppColors.red),
                        onPressed: () async {
                          await widget.onDeleteTemplate!(tpl.id);
                        },
                      ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _isApplying
                          ? null
                          : () async {
                              setState(() => _isApplying = true);
                              try {
                                await widget.onApplyTemplate(tpl);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  AppFeedback.showSuccess(
                                    context,
                                    '✨ Applied "${tpl.name}" to your packing list!',
                                    title: 'Template Applied',
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isApplying = false);
                              }
                            },
                      icon: const Icon(Icons.playlist_add_rounded, size: 18),
                      label: Text(_isApplying ? 'Applying...' : 'Apply to Trip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCatName(String catKey) {
    switch (catKey) {
      case 'essentials':
        return 'Essentials';
      case 'clothing':
        return 'Clothing';
      case 'toiletries':
        return 'Toiletries';
      case 'gadgets':
        return 'Gadgets';
      case 'documents':
        return 'Documents';
      case 'medicines':
        return 'Medicines';
      case 'food':
        return 'Food & Snacks';
      case 'others':
        return 'Others';
      default:
        return catKey.replaceAll('custom_', '').replaceAll('_', ' ');
    }
  }
}
