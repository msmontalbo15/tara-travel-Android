import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/explore_provider.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destinationsAsync = ref.watch(exploreProvider);

    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
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
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Explore', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Find your next adventure', style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
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
                      style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
                        hintText: 'Search destinations...',
                        hintStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: Colors.white.withValues(alpha: 0.25)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        filled: false,
                      ),
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
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              ),
              child: destinationsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'Unable to load live destinations right now.',
                      style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: AppColors.warmMuted),
                    ),
                  ),
                ),
                data: (all) {
                  final trending = all.where((d) => d.isTrending).toList();
                  final weekend = all.where((d) => d.isWeekendGetaway).toList();
                  final recommended = all.where((d) => d.isRecommended).toList();
                  final searchResults = _query.isNotEmpty
                      ? all.where((d) => d.name.toLowerCase().contains(_query.toLowerCase())).toList()
                      : <ExploreDestination>[];

                  return _query.isNotEmpty
                      ? _buildSearchResults(searchResults)
                      : _buildBrowse(trending, weekend, recommended);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowse(List<ExploreDestination> trending, List<ExploreDestination> weekend, List<ExploreDestination> recommended) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('🔥 Trending Now', onSeeAll: () {}),
        _horizontalList(trending),
        _sectionHeader('🌅 Weekend Getaways', onSeeAll: () {}),
        _horizontalList(weekend),
        _sectionHeader('✨ Recommended For You', onSeeAll: () {}),
        ...recommended.map((d) => _RecommendedCard(dest: d, onTap: () => _showDestinationDetail(context, d))),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSearchResults(List<ExploreDestination> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text('${results.length} results for "$_query"', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warmMuted)),
        ),
        if (results.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: Text('No destinations found 🤔', style: TextStyle(fontFamily: 'DM Sans', fontSize: 15, color: AppColors.warmMuted))),
          ),
        ...results.map((d) => _RecommendedCard(dest: d, onTap: () => _showDestinationDetail(context, d))),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('See all', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _horizontalList(List<ExploreDestination> dests) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: dests.length,
        itemBuilder: (_, i) => _DestinationCard(dest: dests[i], onTap: () => _showDestinationDetail(context, dests[i])),
      ),
    );
  }

  void _showDestinationDetail(BuildContext context, ExploreDestination dest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DestinationDetailSheet(dest: dest),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final ExploreDestination dest;
  final VoidCallback onTap;

  const _DestinationCard({required this.dest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo area
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: SizedBox(
              height: 115,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: dest.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.deepEarth),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.deepEarth,
                      child: Center(child: Text(dest.photoEmoji, style: const TextStyle(fontSize: 46))),
                    ),
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
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                        child: const Text('🔥 Trending', style: TextStyle(fontFamily: 'DM Sans', fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
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
                    Text(dest.name, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Row(
                      children: [
                        Text(dest.avgCostRange, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        const SizedBox(width: 6),
                        Text('· ${dest.bestMode}', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, color: AppColors.textSecondary)),
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
  final ExploreDestination dest;
  final VoidCallback onTap;

  const _RecommendedCard({required this.dest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: dest.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.deepEarth),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.deepEarth,
                    child: Center(child: Text(dest.photoEmoji, style: const TextStyle(fontSize: 24))),
                  ),
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
                      Text(dest.name, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(6)),
                        child: Text(dest.tag, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(dest.distanceFromMetro, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.textSecondary)),
                  if (dest.recommendedReason != null) ...[
                    const SizedBox(height: 3),
                    Text(dest.recommendedReason!, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary)),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(dest.avgCostRange, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
  final ExploreDestination dest;
  const _DestinationDetailSheet({required this.dest});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Hero
          Container(
            height: 180,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                  child: CachedNetworkImage(
                    imageUrl: dest.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.deepEarth),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.deepEarth,
                      child: Center(child: Text(dest.photoEmoji, style: const TextStyle(fontSize: 72))),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.08), Colors.black.withValues(alpha: 0.45)],
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
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20, left: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dest.name, style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text(dest.country, style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dest.description, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                  const SizedBox(height: 20),
                  _infoRow('📍', 'Distance', dest.distanceFromMetro),
                  _infoRow('🚗', 'Best way to get there', dest.bestMode),
                  _infoRow('💰', 'Avg cost', dest.avgCostRange),
                  _infoRow('🗓️', 'Best time to visit', dest.bestTimeToVisit),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                          label: const Text('Save', style: TextStyle(fontFamily: 'DM Sans')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/create-trip');
                          },
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Plan Trip', style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w600)),
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
              Text(label, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.warmMuted)),
              Text(value, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
