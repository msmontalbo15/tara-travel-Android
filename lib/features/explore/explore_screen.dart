import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_responsive.dart';
import '../../core/widgets/app_brand_logo.dart';
import '../../core/providers/explore_provider.dart';
import '../../core/models/destination_model.dart';
import '../create_trip/models/new_trip_model.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final Set<String> _bookmarkedIds = {};

  static const List<String> _categories = [
    'All',
    'Beach',
    'Nature',
    'Adventure',
    'Cultural',
    'City',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleBookmark(String id) {
    setState(() {
      if (_bookmarkedIds.contains(id)) {
        _bookmarkedIds.remove(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from saved destinations'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _bookmarkedIds.add(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Destination saved! ⭐'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final destinationsAsync = ref.watch(exploreProvider);
    final selectedCategory = ref.watch(exploreCategoryFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(exploreProvider);
          await ref.read(exploreProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  24,
                  MediaQuery.paddingOf(context).top + 16,
                  24,
                  18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Explore',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontHeading,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Discover the best of the Philippines',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const AppBrandLogo(size: 38, isDark: true),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Search bar
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 20,
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                          hintText: 'Search destinations (e.g. Boracay, Coron, Baguio)...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          filled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Category Filter Pills
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = selectedCategory == cat;
                          return GestureDetector(
                            onTap: () {
                              ref.read(exploreCategoryFilterProvider.notifier).setCategory(cat);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white.withValues(alpha: 0.12),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _categoryLabel(cat),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main content
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: destinationsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 14),
                          Text(
                            'Loading verified destinations from Supabase...',
                            style: TextStyle(fontSize: 13, color: AppColors.warmMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  error: (_, __) => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Unable to load live destinations right now.',
                        style: TextStyle(fontSize: 14, color: AppColors.warmMuted),
                      ),
                    ),
                  ),
                  data: (all) {
                    // Apply Category Filter
                    final filteredByCategory = selectedCategory == 'All'
                        ? all
                        : all.where((d) => d.tag.toLowerCase() == selectedCategory.toLowerCase()).toList();

                    // Apply Search Query
                    final searchResults = _query.isNotEmpty
                        ? filteredByCategory
                            .where((d) =>
                                d.name.toLowerCase().contains(_query.toLowerCase()) ||
                                d.description.toLowerCase().contains(_query.toLowerCase()) ||
                                d.tag.toLowerCase().contains(_query.toLowerCase()))
                            .toList()
                        : <DestinationModel>[];

                    if (_query.isNotEmpty) {
                      return _buildSearchResults(searchResults);
                    }

                    if (selectedCategory != 'All') {
                      return _buildCategoryResults(selectedCategory, filteredByCategory);
                    }

                    final trending = all.where((d) => d.isTrending).toList();
                    final weekend = all.where((d) => d.isWeekendGetaway).toList();
                    final recommended = all.where((d) => d.isRecommended).toList();

                    return _buildBrowse(trending, weekend, recommended);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'Beach':
        return '🏖️ Beach';
      case 'Nature':
        return '🌿 Nature';
      case 'Adventure':
        return '⛰️ Adventure';
      case 'Cultural':
        return '🏛️ Cultural';
      case 'City':
        return '🏙️ City';
      default:
        return '✨ All';
    }
  }

  Widget _buildBrowse(
    List<DestinationModel> trending,
    List<DestinationModel> weekend,
    List<DestinationModel> recommended,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trending.isNotEmpty) ...[
          _sectionHeader('🔥 Trending Now', onSeeAll: () {
            ref.read(exploreCategoryFilterProvider.notifier).setCategory('All');
          }),
          _horizontalList(trending),
        ],
        if (weekend.isNotEmpty) ...[
          _sectionHeader('🌅 Weekend Getaways', onSeeAll: () {
            ref.read(exploreCategoryFilterProvider.notifier).setCategory('All');
          }),
          _horizontalList(weekend),
        ],
        if (recommended.isNotEmpty) ...[
          _sectionHeader('✨ Recommended For You'),
          ...recommended.map(
            (d) => _RecommendedCard(
              dest: d,
              isSaved: _bookmarkedIds.contains(d.id),
              onToggleSave: () => _toggleBookmark(d.id),
              onTap: () => _showDestinationDetail(context, d),
            ),
          ),
        ],
        const SizedBox(height: 130),
      ],
    );
  }

  Widget _buildCategoryResults(String category, List<DestinationModel> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_categoryLabel(category)} (${results.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(exploreCategoryFilterProvider.notifier).setCategory('All');
                },
                child: const Text(
                  'Clear filter',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        if (results.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text('No destinations found in this category.', style: TextStyle(fontSize: 15, color: AppColors.warmMuted)),
            ),
          ),
        ...results.map(
          (d) => _RecommendedCard(
            dest: d,
            isSaved: _bookmarkedIds.contains(d.id),
            onToggleSave: () => _toggleBookmark(d.id),
            onTap: () => _showDestinationDetail(context, d),
          ),
        ),
        const SizedBox(height: 130),
      ],
    );
  }

  Widget _buildSearchResults(List<DestinationModel> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            '${results.length} results for "$_query"',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warmMuted),
          ),
        ),
        if (results.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text('No destinations found 🤔', style: TextStyle(fontSize: 15, color: AppColors.warmMuted)),
            ),
          ),
        ...results.map(
          (d) => _RecommendedCard(
            dest: d,
            isSaved: _bookmarkedIds.contains(d.id),
            onToggleSave: () => _toggleBookmark(d.id),
            onTap: () => _showDestinationDetail(context, d),
          ),
        ),
        const SizedBox(height: 130),
      ],
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('See all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _horizontalList(List<DestinationModel> dests) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: dests.length,
        itemBuilder: (_, i) => _DestinationCard(
          dest: dests[i],
          onTap: () => _showDestinationDetail(context, dests[i]),
        ),
      ),
    );
  }

  void _showDestinationDetail(BuildContext context, DestinationModel dest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DestinationDetailSheet(
        dest: dest,
        isSaved: _bookmarkedIds.contains(dest.id),
        onToggleSave: () => _toggleBookmark(dest.id),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final DestinationModel dest;
  final VoidCallback onTap;

  const _DestinationCard({required this.dest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUri = dest.imageUrl;
    final hasImage = imageUri != null && imageUri.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo area
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: SizedBox(
                height: 115,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      CachedNetworkImage(
                        imageUrl: imageUri,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.deepEarth),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.deepEarth,
                          child: Center(child: Text(dest.photoEmoji, style: const TextStyle(fontSize: 46))),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.deepEarth,
                        child: Center(child: Text(dest.photoEmoji, style: const TextStyle(fontSize: 46))),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: 0.06), Colors.black.withValues(alpha: 0.30)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    if (dest.isTrending)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '🔥 Trending',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dest.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            dest.avgCostRange,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '· ${dest.bestMode}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

class _RecommendedCard extends StatelessWidget {
  final DestinationModel dest;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onTap;

  const _RecommendedCard({
    required this.dest,
    required this.isSaved,
    required this.onToggleSave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUri = dest.imageUrl;
    final hasImage = imageUri != null && imageUri.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: imageUri,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.deepEarth),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.deepEarth,
                          child: Center(child: Text(dest.photoEmoji, style: const TextStyle(fontSize: 24))),
                        ),
                      )
                    : Container(
                        color: AppColors.deepEarth,
                        child: Center(child: Text(dest.photoEmoji, style: const TextStyle(fontSize: 24))),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          dest.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          dest.tag,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dest.distanceFromMetro,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dest.recommendedReason != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      dest.recommendedReason!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dest.avgCostRange,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.warmMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationDetailSheet extends StatelessWidget {
  final DestinationModel dest;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const _DestinationDetailSheet({
    required this.dest,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final imageUri = dest.imageUrl;
    final hasImage = imageUri != null && imageUri.isNotEmpty;

    return Container(
      height: context.sheetMaxHeight(0.80),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Hero Header with Image
          Container(
            height: 200,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: imageUri,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.deepEarth),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.deepEarth,
                            child: Center(child: Text(dest.photoEmoji, style: const TextStyle(fontSize: 72))),
                          ),
                        )
                      : Container(
                          color: AppColors.deepEarth,
                          child: Center(child: Text(dest.photoEmoji, style: const TextStyle(fontSize: 72))),
                        ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Handle bar
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 24,
                  right: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                dest.tag.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                            Text(
                              dest.name,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontHeading,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              dest.country,
                              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: isSaved ? AppColors.amber : Colors.white,
                          size: 28,
                        ),
                        onPressed: onToggleSave,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 20, 24, context.safeBottomPadding(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dest.recommendedReason != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dest.recommendedReason!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deepEarth),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    dest.description,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  _infoRow('📍', 'Distance', dest.distanceFromMetro),
                  _infoRow('🚗', 'Best way to get there', dest.bestMode),
                  _infoRow('💰', 'Estimated budget', dest.avgCostRange),
                  _infoRow('🗓️', 'Best time to visit', dest.bestTimeToVisit),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            onToggleSave();
                          },
                          icon: Icon(
                            isSaved ? Icons.bookmark_remove_rounded : Icons.bookmark_add_outlined,
                            size: 16,
                          ),
                          label: Text(isSaved ? 'Saved' : 'Save', style: const TextStyle(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isSaved ? AppColors.amber : AppColors.primary,
                            side: BorderSide(
                              color: isSaved ? AppColors.amber : AppColors.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            final draft = NewTripModel(
                              destination: dest.name,
                              destinationLat: dest.latitude,
                              destinationLng: dest.longitude,
                              tripType: dest.tripType,
                            );
                            Navigator.pushNamed(
                              context,
                              '/create-trip',
                              arguments: draft,
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Plan Trip with Tara', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.warmMuted)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
