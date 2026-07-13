import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/packing_provider.dart';
import '../../core/providers/realtime_provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/models/packing_model.dart';

class PackingScreen extends ConsumerStatefulWidget {
  final bool showHeader;
  const PackingScreen({super.key, this.showHeader = true});

  @override
  ConsumerState<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends ConsumerState<PackingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _newCategoryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _newCategoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(activeTripProvider);

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return const Scaffold(body: Center(child: Text('No active trip found')));
        }

        // Listen to live realtime stream for packing items
        ref.watch(packingRealtimeProvider(trip.id));

        final packing = ref.watch(ref.watch(packingProvider(trip.id)));

        return Scaffold(
          backgroundColor: AppColors.deepEarth,
          body: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(24, widget.showHeader ? 56 : 8, 24, 0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showHeader) ...[
                      Row(
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
                          const Expanded(
                            child: Text('Packing List', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ],
                      ),
                      Text(trip.name, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: Colors.white54)),
                      const SizedBox(height: 16),

                      // Progress hero
                      _buildProgressHero(packing),

                      const SizedBox(height: 14),
                    ],
                    TabBar(
                      controller: _tabCtrl,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 2,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600),
                      tabs: const [Tab(text: 'Packing List'), Tab(text: 'Reminders')],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  color: AppColors.surfaceLight,
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildPackingList(packing, trip.id),
                      _buildRemindersTab(trip.members, trip.id),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: Text('Trip Error: $e', style: const TextStyle(color: Colors.white)))),
    );
  }

  Widget _buildProgressHero(PackingState packing) {
    final percent = (packing.overallProgress * 100).round();
    final allPacked = packing.allPacked;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allPacked ? '🎉 All packed!' : 'Pack Progress',
                  style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  allPacked ? 'Tara na! Ready to go!' : '${packing.packedItems} of ${packing.totalItems} items packed',
                  style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Colors.white54),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: packing.overallProgress,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(allPacked ? AppColors.green : AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$percent%',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: allPacked ? AppColors.green : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackingList(PackingState packing, String tripId) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI suggestions banner
          if (packing.showSuggestions && packing.suggestions.isNotEmpty)
            _SmartSuggestionBanner(
              suggestions: packing.suggestions,
              onAdd: (s) => ref.read(ref.read(packingProvider(tripId)).notifier).addSuggestion(s),
              onDismiss: () => ref.read(ref.read(packingProvider(tripId)).notifier).dismissSuggestions(),
            ),

          const SizedBox(height: 4),

          // Categories
          ...packing.categories.map((cat) => _PackingCategoryCard(
            category: cat,
            onToggleItem: (itemId) => ref.read(ref.read(packingProvider(tripId)).notifier).toggleItem(cat.id, itemId),
            onToggleExpand: () => ref.read(ref.read(packingProvider(tripId)).notifier).toggleCategory(cat.id),
          )),

          const SizedBox(height: 16),

          // Add custom category
          GestureDetector(
            onTap: () => _showAddCategoryDialog(context, tripId),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dividerLight, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('Add Custom Category', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersTab(List members, String tripId) {
    final packing = ref.watch(ref.watch(packingProvider(tripId)));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PACK STATUS BY MEMBER', style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warmMuted, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          ...members.map((m) => _buildMemberPackStatus(m, packing)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _sendGroupReminder(context),
              icon: const Icon(Icons.notifications_active_rounded, size: 18),
              label: const Text('Send Reminder to All', style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberPackStatus(member, PackingState packing) {
    // Mock status for each member
    final packed = 12 + member.name.length % 4;
    const total = 18;
    final progress = packed / total;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: member.color, shape: BoxShape.circle),
            child: Center(child: Text(member.initials.substring(0, 1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.dividerLight,
                    valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? AppColors.green : AppColors.amber),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 2),
                Text('$packed / $total packed', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendReminder(context, member.name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.chipBackground, borderRadius: BorderRadius.circular(8)),
              child: const Text('Remind', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, String tripId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Category', style: TextStyle(fontFamily: 'Playfair Display')),
        content: TextField(
          controller: _newCategoryCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category name', hintStyle: TextStyle(fontFamily: 'DM Sans')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_newCategoryCtrl.text.trim().isNotEmpty) {
                ref.read(ref.read(packingProvider(tripId)).notifier).addCustomCategory(_newCategoryCtrl.text.trim());
                _newCategoryCtrl.clear();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _sendReminder(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🔔 Reminder sent to $name!', style: const TextStyle(fontFamily: 'DM Sans')), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating),
    );
  }

  void _sendGroupReminder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔔 Reminder sent to all members!', style: TextStyle(fontFamily: 'DM Sans')), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating),
    );
  }
}

class _PackingCategoryCard extends StatelessWidget {
  final PackingCategory category;
  final void Function(String itemId) onToggleItem;
  final VoidCallback onToggleExpand;

  const _PackingCategoryCard({required this.category, required this.onToggleItem, required this.onToggleExpand});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggleExpand,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: category.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(category.icon, size: 17, color: category.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
                        Text('${category.packedCount}/${category.totalCount} packed', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  // Progress ring mini
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: category.progress,
                          strokeWidth: 3,
                          backgroundColor: AppColors.dividerLight,
                          valueColor: AlwaysStoppedAnimation<Color>(category.allPacked ? AppColors.green : category.color),
                        ),
                        Text('${(category.progress * 100).round()}%', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(category.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.muted),
                ],
              ),
            ),
          ),
          if (category.isExpanded)
            ...category.items.map((item) => _PackingItemRow(item: item, categoryColor: category.color, onToggle: () => onToggleItem(item.id))),
        ],
      ),
    );
  }
}

class _PackingItemRow extends StatelessWidget {
  final PackingItem item;
  final Color categoryColor;
  final VoidCallback onToggle;

  const _PackingItemRow({required this.item, required this.categoryColor, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.dividerLight, width: 0.5))),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: item.isChecked ? categoryColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: item.isChecked ? categoryColor : AppColors.dividerLight, width: 1.5),
              ),
              child: item.isChecked ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: item.isCritical ? FontWeight.w700 : FontWeight.w500,
                        color: item.isChecked ? AppColors.muted : AppColors.deepEarth,
                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.muted,
                      ),
                    ),
                  ),
                  if (item.isAiSuggested)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                      child: const Text('✦ AI', style: TextStyle(fontFamily: 'DM Sans', fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.purple)),
                    ),
                  if (item.isCritical && !item.isChecked)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                      child: const Text('Missing!', style: TextStyle(fontFamily: 'DM Sans', fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.red)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartSuggestionBanner extends StatelessWidget {
  final List<SmartSuggestion> suggestions;
  final void Function(SmartSuggestion) onAdd;
  final VoidCallback onDismiss;

  const _SmartSuggestionBanner({required this.suggestions, required this.onAdd, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A0A04), Color(0xFF2C1A14)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✦ Smart Suggestions', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Based on your beach trip + weather forecast', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.take(5).map((s) => GestureDetector(
              onTap: () => onAdd(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Text(s.text, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Colors.white)),
                    const SizedBox(width: 6),
                    const Icon(Icons.add_circle_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
