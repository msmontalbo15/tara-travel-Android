import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/packing_provider.dart';
import '../../core/providers/realtime_provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/packing_model.dart';
import '../../core/models/member_model.dart';
import '../../core/widgets/share/share_trip_modal.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'widgets/member_assignment_sheet.dart';
import 'widgets/packing_template_modals.dart';
import 'widgets/ai_packing_dialog.dart';

class PackingScreen extends ConsumerStatefulWidget {
  final bool showHeader;
  const PackingScreen({super.key, this.showHeader = true});

  @override
  ConsumerState<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends ConsumerState<PackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _newCategoryCtrl = TextEditingController();
  bool _allExpanded = false;

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
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return const Scaffold(
            backgroundColor: AppColors.deepEarth,
            body: Center(
              child: Text(
                'No active trip found',
                style: TextStyle(color: Colors.white, fontFamily: 'DM Sans'),
              ),
            ),
          );
        }

        // Realtime stream listener
        ref.watch(packingRealtimeProvider(trip.id));

        final packingNotifier =
            ref.read(ref.read(packingProvider(trip.id)).notifier);
        final packing = ref.watch(ref.watch(packingProvider(trip.id)));

        // Automatically populate contextual AI suggestions on initial empty suggestion load
        if (packing.suggestions.isEmpty && packing.showSuggestions) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            packingNotifier.generateAiSuggestions(
              destination: trip.destination,
              tripType: trip.tripType,
              durationDays: trip.toDate.difference(trip.fromDate).inDays + 1,
            );
          });
        }

        final filteredCategories =
            packing.getFilteredCategories(currentUserId);

        return Scaffold(
          backgroundColor: AppColors.deepEarth,
          body: Column(
            children: [
              // ── Header ─────────────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(
                    20, widget.showHeader ? 52 : 8, 20, 0),
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.15)),
                                    ),
                                    child: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: Colors.white,
                                        size: 16),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Packing List',
                                  style: TextStyle(
                                    fontFamily: 'Playfair Display',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  trip.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Template Actions (Save & Load)
                          GestureDetector(
                            onTap: () => _showTemplateActionsSheet(
                              context,
                              trip.id,
                              trip.name,
                              packing,
                              packingNotifier,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.15)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.style_rounded,
                                          color: AppColors.amber, size: 15),
                                      SizedBox(width: 4),
                                      Text(
                                        'Templates',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Share packing list button
                          GestureDetector(
                            onTap: () => ShareTripModal.show(
                              context,
                              ref,
                              trip,
                              initialScope: ShareScope.packing,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.15)),
                                  ),
                                  child: const Icon(Icons.share_rounded,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Progress Hero
                      _buildProgressHero(packing),

                      const SizedBox(height: 12),
                    ],

                    // Tab Bar
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: TabBar(
                        controller: _tabCtrl,
                        indicator: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white54,
                        labelStyle: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(text: 'Packing Checklist'),
                          Tab(text: 'Reminders & Status'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab Views ───────────────────────────────────────────
              Expanded(
                child: Container(
                  color: AppColors.surfaceLight,
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildPackingListTab(
                        context,
                        trip,
                        packing,
                        packingNotifier,
                        filteredCategories,
                        currentUserId,
                      ),
                      _buildRemindersTab(
                        context,
                        trip,
                        packing,
                        packingNotifier,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const PackingScreenSkeleton(),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.deepEarth,
        body: Center(
          child: Text(
            'Trip Error: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ── Progress Hero ──────────────────────────────────────────────────────────

  Widget _buildProgressHero(PackingState packing) {
    final percent = (packing.overallProgress * 100).round();
    final allPacked = packing.allPacked;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          allPacked ? '🎉 All packed!' : 'Trip Pack Progress',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (allPacked)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Text(
                              'Tara na! Ready to go!',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                color: AppColors.greenBright,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${packing.packedItems} of ${packing.totalItems} items packed across all members',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: packing.overallProgress),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (_, val, __) => LinearProgressIndicator(
                          value: val,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            allPacked ? AppColors.greenBright : AppColors.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '$percent%',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: allPacked ? AppColors.greenBright : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Packing List Tab ───────────────────────────────────────────────────────

  Widget _buildPackingListTab(
    BuildContext context,
    TripModel trip,
    PackingState packing,
    PackingNotifier notifier,
    List<PackingCategory> filteredCategories,
    String? currentUserId,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Smart AI Suggestions Banner (collapsible) ──────────────
          if (packing.showSuggestions && packing.suggestions.isNotEmpty)
            _SmartSuggestionBanner(
              suggestions: packing.suggestions,
              contextLabel: packing.aiContextLabel ??
                  '${trip.tripType.toUpperCase()} • ${trip.destination}',
              isExpanded: packing.suggestionsExpanded,
              onToggleExpand: () => notifier.toggleSuggestionsExpanded(),
              onAdd: (s) => notifier.addSuggestion(s),
              onDismiss: () => notifier.dismissSuggestions(),
              onCustomize: () => AiPackingDialog.show(
                context,
                destination: trip.destination,
                tripType: trip.tripType,
                durationDays: trip.toDate.difference(trip.fromDate).inDays + 1,
                onGenerate: ({
                  required destination,
                  required tripType,
                  required durationDays,
                  weatherCondition,
                  transportMode,
                }) {
                  notifier.generateAiSuggestions(
                    destination: destination,
                    tripType: tripType,
                    durationDays: durationDays,
                    weatherCondition: weatherCondition,
                    transportMode: transportMode,
                  );
                },
              ),
            ),

          // ── Member Filter Chips & AI Suggest Button Bar ─────────────
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All Items (${packing.totalItems})',
                        isSelected: packing.selectedMemberFilter == 'all',
                        onTap: () => notifier.setMemberFilter('all'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'My List (You)',
                        isSelected: packing.selectedMemberFilter == 'my',
                        onTap: () => notifier.setMemberFilter('my'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Shared / Everyone',
                        isSelected: packing.selectedMemberFilter == 'unassigned',
                        onTap: () => notifier.setMemberFilter('unassigned'),
                      ),
                      ...trip.members.map((m) {
                        final stats = packing.getMemberStats(m.id);
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _buildMemberFilterChip(
                            member: m,
                            stats: stats,
                            isSelected: packing.selectedMemberFilter == m.id,
                            onTap: () => notifier.setMemberFilter(m.id),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Header Info: Collapse/Expand All & AI Trigger ──────────
          Row(
            children: [
              Text(
                'CATEGORIES (${filteredCategories.length})',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: AppColors.warmMuted,
                ),
              ),
              const Spacer(),
              // Expand/Collapse All
              GestureDetector(
                onTap: () {
                  setState(() => _allExpanded = !_allExpanded);
                  notifier.toggleCollapseAll(_allExpanded);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        _allExpanded
                            ? Icons.unfold_less_rounded
                            : Icons.unfold_more_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _allExpanded ? 'Collapse All' : 'Expand All',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // AI Suggest packing list button
              GestureDetector(
                onTap: () => AiPackingDialog.show(
                  context,
                  destination: trip.destination,
                  tripType: trip.tripType,
                  durationDays:
                      trip.toDate.difference(trip.fromDate).inDays + 1,
                  onGenerate: ({
                    required destination,
                    required tripType,
                    required durationDays,
                    weatherCondition,
                    transportMode,
                  }) {
                    notifier.generateAiSuggestions(
                      destination: destination,
                      tripType: tripType,
                      durationDays: durationDays,
                      weatherCondition: weatherCondition,
                      transportMode: transportMode,
                    );
                  },
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 12, color: AppColors.purple),
                      SizedBox(width: 4),
                      Text(
                        'Suggest List',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Category Cards ─────────────────────────────────────────
          ...filteredCategories.map((cat) => _PackingCategoryCard(
                category: cat,
                members: trip.members,
                onToggleItem: (itemId) =>
                    notifier.toggleItem(cat.id, itemId),
                onToggleExpand: () => notifier.toggleCategory(cat.id),
                onAssignMember: (item) => MemberAssignmentSheet.show(
                  context,
                  item: item,
                  members: trip.members,
                  onSelectMember: (m) =>
                      notifier.assignMember(cat.id, item.id, m),
                ),
                onDeleteItem: (itemId) => notifier.removeItem(cat.id, itemId),
                onDeleteCategory: () => _confirmDeleteCategory(context, notifier, cat),
                onAddItem: (name) => notifier.addItemToCategory(cat.id, name),
              )),

          const SizedBox(height: 16),

          // ── Add Custom Category Button ─────────────────────────────
          GestureDetector(
            onTap: () => _showAddCategoryDialog(
              context,
              notifier: notifier,
              existingCategories: packing.categories,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                    color: AppColors.dividerLight, width: 1.2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Add Custom Category',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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

  // ── Reminders & Status Tab ─────────────────────────────────────────────────

  Widget _buildRemindersTab(
    BuildContext context,
    TripModel trip,
    PackingState packing,
    PackingNotifier notifier,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 30 + MediaQuery.of(context).padding.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'PACK STATUS BY MEMBER',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.warmMuted,
                ),
              ),
              const Spacer(),
              Text(
                '${trip.members.length} travelers',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (trip.members.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Text(
                  'No members joined yet. Invite friends to assign packing items!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'DM Sans', color: AppColors.muted),
                ),
              ),
            )
          else
            ...trip.members.map((m) {
              final stats = packing.getMemberStats(m.id);
              final unpacked = packing.getMemberUnpackedItems(m.id);
              return _buildMemberPackStatusCard(
                context,
                trip.name,
                m,
                stats.$1,
                stats.$2,
                unpacked,
                notifier,
              );
            }),

          const SizedBox(height: 20),

          // Send Reminder to All Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _sendGroupReminder(
                context,
                trip.name,
                trip.members,
                packing,
                notifier,
              ),
              icon: const Icon(Icons.notifications_active_rounded, size: 18),
              label: const Text(
                'Send Reminder to All Members',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberPackStatusCard(
    BuildContext context,
    String tripName,
    MemberModel member,
    int packed,
    int total,
    List<String> unpackedItems,
    PackingNotifier notifier,
  ) {
    final progress = total == 0 ? 1.0 : (packed / total);
    final allDone = total > 0 && packed == total;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: allDone
                ? AppColors.green.withValues(alpha: 0.3)
                : AppColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: member.color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: member.color.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    member.initials,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepEarth,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total == 0
                          ? 'No items assigned'
                          : '$packed / $total items packed (${(progress * 100).round()}%)',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: allDone ? AppColors.green : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (total > 0 && !allDone)
                GestureDetector(
                  onTap: () => _sendIndividualReminder(
                    context,
                    tripName,
                    member,
                    unpackedItems,
                    notifier,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_active_outlined,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Remind (${total - packed})',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (allDone)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: AppColors.green),
                      SizedBox(width: 4),
                      Text(
                        'Ready!',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.dividerLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  allDone ? AppColors.greenBright : AppColors.amber,
                ),
                minHeight: 6,
              ),
            ),
          ],
          if (unpackedItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REMAINING TO PACK:',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppColors.warmMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unpackedItems.join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: AppColors.deepEarth,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Filter Chips ───────────────────────────────────────────────────────────

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.dividerLight.withValues(alpha: 0.8),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.deepEarth,
          ),
        ),
      ),
    );
  }

  Widget _buildMemberFilterChip({
    required MemberModel member,
    required (int, int) stats,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? member.color.withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? member.color
                : AppColors.dividerLight.withValues(alpha: 0.8),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: member.color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  member.initials.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${member.name} (${stats.$1}/${stats.$2})',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? member.color : AppColors.deepEarth,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Modals & Actions ───────────────────────────────────────────────────────

  void _showTemplateActionsSheet(
    BuildContext context,
    String tripId,
    String tripName,
    PackingState packing,
    PackingNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const Text(
                'Packing List Templates',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepEarth,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bookmark_add_rounded,
                      color: AppColors.primary),
                ),
                title: const Text(
                  'Save packing list as template',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Saves ${packing.totalItems} items from this trip',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted),
                onTap: () {
                  Navigator.pop(context);
                  SaveTemplateModal.show(
                    context,
                    categories: packing.categories,
                    totalItems: packing.totalItems,
                    defaultName: tripName,
                    onSave: (name, icon) async {
                      await notifier.saveCurrentAsTemplate(name, icon: icon);
                    },
                  );
                },
              ),
              const Divider(color: AppColors.dividerLight, height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.style_rounded,
                      color: AppColors.purple),
                ),
                title: const Text(
                  'Load from Ready-made Templates',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'Beach, Mountain, Road Trip, City & saved checklists',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted),
                onTap: () {
                  Navigator.pop(context);
                  LoadTemplateSheet.show(
                    context,
                    templates: packing.templates,
                    onApplyTemplate: (tpl) => notifier.applyTemplate(tpl),
                    onDeleteTemplate: (id) => notifier.deleteTemplate(id),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(
    BuildContext context, {
    required PackingNotifier notifier,
    required List<PackingCategory> existingCategories,
  }) {
    final existingNames = existingCategories.map((c) => c.name.trim().toLowerCase()).toSet();

    // Default categories that can be re-added if deleted
    final defaultPresets = [
      (name: 'Essentials', icon: Icons.backpack_rounded, color: const Color(0xFFD85A30)),
      (name: 'Clothing', icon: Icons.checkroom_rounded, color: const Color(0xFF8B5CF6)),
      (name: 'Toiletries', icon: Icons.clean_hands_rounded, color: const Color(0xFF0D9488)),
      (name: 'Gadgets', icon: Icons.devices_rounded, color: const Color(0xFF3B82F6)),
      (name: 'Documents', icon: Icons.description_rounded, color: const Color(0xFFEF9F27)),
      (name: 'Medicines', icon: Icons.medical_services_rounded, color: const Color(0xFFEF4444)),
      (name: 'Food & Snacks', icon: Icons.restaurant_rounded, color: const Color(0xFF10B981)),
      (name: 'Others', icon: Icons.category_rounded, color: const Color(0xFF6B7280)),
    ];

    // Curated quick category suggestions with relevant icons and brand-aligned colors
    final customPresets = [
      (name: 'Scuba & Snorkel', icon: Icons.scuba_diving_rounded, color: const Color(0xFF0284C7)),
      (name: 'Baby & Kids', icon: Icons.child_friendly_rounded, color: const Color(0xFFEC4899)),
      (name: 'Photography', icon: Icons.camera_alt_rounded, color: const Color(0xFF8B5CF6)),
      (name: 'Beach & Swim', icon: Icons.beach_access_rounded, color: const Color(0xFFF59E0B)),
      (name: 'Hiking & Trek', icon: Icons.hiking_rounded, color: const Color(0xFF10B981)),
      (name: 'Fitness & Gym', icon: Icons.fitness_center_rounded, color: const Color(0xFFEF4444)),
      (name: 'Work & Remote', icon: Icons.laptop_mac_rounded, color: const Color(0xFF6366F1)),
      (name: 'Camping Gear', icon: Icons.cabin_rounded, color: const Color(0xFFD97706)),
    ];

    // Priority: Deleted default categories first, then custom presets
    final missingDefaults = defaultPresets
        .where((p) => !existingNames.contains(p.name.trim().toLowerCase()))
        .toList();
    final remainingCustom = customPresets
        .where((p) => !existingNames.contains(p.name.trim().toLowerCase()))
        .toList();

    final quickPresets = [...missingDefaults, ...remainingCustom];

    IconData selectedIcon = Icons.category_rounded;
    Color selectedColor = const Color(0xFF8B5CF6);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
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

                // Title
                const Text(
                  'Add New Category',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepEarth,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pick a suggested category or create your own.',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 16),

                // Quick suggestions header
                const Text(
                  'QUICK SUGGESTIONS',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),

                // Horizontal list of pre-suggested quick categories
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickPresets.map((preset) {
                    final isSelected = _newCategoryCtrl.text == preset.name;
                    return InkWell(
                      onTap: () {
                        setModalState(() {
                          _newCategoryCtrl.text = preset.name;
                          selectedIcon = preset.icon;
                          selectedColor = preset.color;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? preset.color.withValues(alpha: 0.15)
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? preset.color : AppColors.dividerLight,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(preset.icon, size: 16, color: preset.color),
                            const SizedBox(width: 6),
                            Text(
                              preset.name,
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? preset.color : AppColors.deepEarth,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Custom input field
                TextField(
                  controller: _newCategoryCtrl,
                  decoration: InputDecoration(
                    hintText: 'Category name (e.g. Scuba Gear)',
                    hintStyle: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                    prefixIcon: Icon(selectedIcon, color: selectedColor, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.dividerLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.dividerLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    setModalState(() {});
                  },
                ),

                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final text = _newCategoryCtrl.text.trim();
                      if (text.isNotEmpty) {
                        notifier.addCustomCategory(
                          text,
                          icon: selectedIcon,
                          color: selectedColor,
                        );
                        _newCategoryCtrl.clear();
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Add Category',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteCategory(
    BuildContext context,
    PackingNotifier notifier,
    PackingCategory category,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete "${category.name}"?',
          style: const TextStyle(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          category.totalCount > 0
              ? 'This will remove the "${category.name}" category and its ${category.totalCount} packing item${category.totalCount == 1 ? '' : 's'}. This cannot be undone.'
              : 'Are you sure you want to remove the "${category.name}" category?',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            color: AppColors.muted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'DM Sans', color: AppColors.muted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.removeCategory(category.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${category.name}" category'),
                  backgroundColor: AppColors.deepEarth,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendIndividualReminder(
    BuildContext context,
    String tripName,
    MemberModel member,
    List<String> unpackedItems,
    PackingNotifier notifier,
  ) async {
    // 1. Dispatch in-app notification
    await notifier.sendMemberReminder(member, tripName);

    final reminderText =
        'Hey ${member.name}! 🧳 Reminder for our trip "$tripName":\n'
        'You have ${unpackedItems.length} items left to pack:\n'
        '${unpackedItems.map((e) => '• $e').join('\n')}\n'
        'Tara, let\'s pack!';

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminder Sent to ${member.name}!',
                          style: const TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepEarth,
                          ),
                        ),
                        const Text(
                          'In-app notification delivered',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.dividerLight),
                ),
                child: Text(
                  reminderText,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: AppColors.deepEarth,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: reminderText));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '📋 Copied reminder message to clipboard! Paste into Messenger/Chat.',
                          style: TextStyle(fontFamily: 'DM Sans'),
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text(
                    'Copy Reminder Text for Chat / SMS',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendGroupReminder(
    BuildContext context,
    String tripName,
    List<MemberModel> members,
    PackingState packing,
    PackingNotifier notifier,
  ) async {
    await notifier.sendGroupReminder(members, tripName);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔔 Packing reminder sent to all ${members.length} members for $tripName!',
          style: const TextStyle(fontFamily: 'DM Sans'),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Category Card Component ──────────────────────────────────────────────────

class _PackingCategoryCard extends StatefulWidget {
  final PackingCategory category;
  final List<MemberModel> members;
  final void Function(String itemId) onToggleItem;
  final VoidCallback onToggleExpand;
  final void Function(PackingItem item) onAssignMember;
  final void Function(String itemId) onDeleteItem;
  final VoidCallback onDeleteCategory;
  final void Function(String itemName) onAddItem;

  const _PackingCategoryCard({
    required this.category,
    required this.members,
    required this.onToggleItem,
    required this.onToggleExpand,
    required this.onAssignMember,
    required this.onDeleteItem,
    required this.onDeleteCategory,
    required this.onAddItem,
  });

  @override
  State<_PackingCategoryCard> createState() => _PackingCategoryCardState();
}

class _PackingCategoryCardState extends State<_PackingCategoryCard> {
  bool _isAdding = false;
  final _addCtrl = TextEditingController();

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  void _submitAdd() {
    final text = _addCtrl.text.trim();
    if (text.isNotEmpty) {
      widget.onAddItem(text);
      _addCtrl.clear();
      setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cat.isExpanded
              ? cat.color.withValues(alpha: 0.4)
              : const Color(0xFFE5E5EA),
          width: cat.isExpanded ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Tap
          GestureDetector(
            onTap: widget.onToggleExpand,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              color: Colors.transparent,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat.icon, size: 19, color: cat.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepEarth,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cat.isEmpty
                              ? 'No items'
                              : '${cat.packedCount}/${cat.totalCount} packed',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            color: cat.allPacked
                                ? AppColors.green
                                : AppColors.muted,
                            fontWeight: cat.allPacked
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mini Progress Ring
                  if (!cat.isEmpty) ...[
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: cat.progress,
                            strokeWidth: 3,
                            backgroundColor: AppColors.dividerLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              cat.allPacked ? AppColors.green : cat.color,
                            ),
                          ),
                          Text(
                            '${(cat.progress * 100).round()}%',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepEarth,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Delete Category Button
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    splashRadius: 18,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: 'Delete category',
                    onPressed: widget.onDeleteCategory,
                  ),
                  const SizedBox(width: 4),

                  // Chevron Expand/Collapse
                  AnimatedRotation(
                    turns: cat.isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.muted,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (cat.isExpanded) ...[
            const Divider(height: 1, color: AppColors.dividerLight),

            // Empty state if no items
            if (cat.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    const Text(
                      'No items in this category yet.',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _isAdding = true),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Item'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...cat.items.map((item) => _PackingItemRow(
                    item: item,
                    categoryColor: cat.color,
                    members: widget.members,
                    onToggle: () => widget.onToggleItem(item.id),
                    onAssign: () => widget.onAssignMember(item),
                    onDelete: () => widget.onDeleteItem(item.id),
                  )),

            // Inline Add item bar
            if (_isAdding)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addCtrl,
                        autofocus: true,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Item name (e.g. Rashguard)',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.dividerLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        onSubmitted: (_) => _submitAdd(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.check_rounded,
                          color: AppColors.primary),
                      onPressed: _submitAdd,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.muted),
                      onPressed: () => setState(() => _isAdding = false),
                    ),
                  ],
                ),
              )
            else if (!cat.isEmpty)
              GestureDetector(
                onTap: () => setState(() => _isAdding = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: AppColors.dividerLight, width: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Add item to this category',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Packing Item Row ─────────────────────────────────────────────────────────

class _PackingItemRow extends StatelessWidget {
  final PackingItem item;
  final Color categoryColor;
  final List<MemberModel> members;
  final VoidCallback onToggle;
  final VoidCallback onAssign;
  final VoidCallback onDelete;

  const _PackingItemRow({
    required this.item,
    required this.categoryColor,
    required this.members,
    required this.onToggle,
    required this.onAssign,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color? memberColor;
    String memberInitials = '';

    if (item.isAssigned) {
      if (item.assignedMemberColor != null) {
        memberColor = Color(item.assignedMemberColor!);
      }
      memberInitials = item.assignedMemberInitials ??
          (item.assignedMemberName != null &&
                  item.assignedMemberName!.isNotEmpty
              ? item.assignedMemberName!.substring(0, 1).toUpperCase()
              : 'M');

      // Match with trip members if possible
      final matched = members
          .where((m) => m.id == item.assignedMemberId)
          .firstOrNull;
      if (matched != null) {
        memberColor = matched.color;
        memberInitials = matched.initials;
      }
    }

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.red.withValues(alpha: 0.15),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.red, size: 20),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.dividerLight, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: item.isChecked ? categoryColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.isChecked
                        ? categoryColor
                        : AppColors.dividerLight,
                    width: 1.5,
                  ),
                ),
                child: item.isChecked
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Item Name & Tags
            Expanded(
              child: GestureDetector(
                onTap: onToggle,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: item.isCritical
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: item.isChecked
                              ? AppColors.muted
                              : AppColors.deepEarth,
                          decoration:
                              item.isChecked ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.muted,
                        ),
                      ),
                    ),
                    if (item.isAiSuggested)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '✦ AI',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.purple,
                          ),
                        ),
                      ),
                    if (item.isCritical && !item.isChecked)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Missing!',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Member Assignment Button / Avatar Badge
            GestureDetector(
              onTap: onAssign,
              child: item.isAssigned
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (memberColor ?? AppColors.primary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (memberColor ?? AppColors.primary)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: memberColor ?? AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                memberInitials.substring(0, 1),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.assignedMemberName ?? 'Assigned',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: memberColor ?? AppColors.primary,
                                ),
                              ),
                              if (item.assignedMemberRole != null &&
                                  item.assignedMemberRole!.isNotEmpty)
                                Text(
                                  item.assignedMemberRole!,
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 9,
                                    color: (memberColor ?? AppColors.primary)
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.dividerLight),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add_alt_1_rounded,
                              size: 13, color: AppColors.muted),
                          SizedBox(width: 3),
                          Text(
                            'Assign',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Smart Suggestion Banner ──────────────────────────────────────────────────

class _SmartSuggestionBanner extends StatelessWidget {
  final List<SmartSuggestion> suggestions;
  final String contextLabel;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final void Function(SmartSuggestion) onAdd;
  final VoidCallback onDismiss;
  final VoidCallback onCustomize;

  const _SmartSuggestionBanner({
    required this.suggestions,
    required this.contextLabel,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onAdd,
    required this.onDismiss,
    required this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A04), Color(0xFF2C1A14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Always-visible header row ──────────────────────────────
          GestureDetector(
            onTap: onToggleExpand,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  // ✦ badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '✦ AI SUGGESTIONS',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Color(0xFFC084FC),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Count pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${suggestions.length}',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Tune button (only visible when expanded)
                  if (isExpanded)
                    GestureDetector(
                      onTap: onCustomize,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.tune_rounded,
                            size: 16, color: Colors.white70),
                      ),
                    ),
                  // Dismiss button
                  GestureDetector(
                    onTap: onDismiss,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 2),
                  // Chevron expand/collapse
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Collapsed preview: show first 2 items inline ───────────
          if (!isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  Text(
                    suggestions
                        .take(2)
                        .map((s) => '${s.icon} ${s.text}')
                        .join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                  if (suggestions.length > 2)
                    Text(
                      '  +${suggestions.length - 2} more',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: Color(0xFFC084FC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

          // ── Expanded content ───────────────────────────────────────
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: Text(
                'Based on $contextLabel',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions.map((s) {
                  return GestureDetector(
                    onTap: () => onAdd(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: s.isWeatherAware
                              ? AppColors.amber.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.icon, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 5),
                          Text(
                            s.text,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.add_circle_rounded,
                              size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

