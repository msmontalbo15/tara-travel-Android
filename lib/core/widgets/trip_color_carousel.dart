import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TripColorTheme {
  final int colorValue;
  final int secondaryColorValue;
  final String name;
  final String tag;
  final String emoji;

  const TripColorTheme({
    required this.colorValue,
    required this.secondaryColorValue,
    required this.name,
    required this.tag,
    required this.emoji,
  });

  Color get color => Color(colorValue);
  Color get secondaryColor => Color(secondaryColorValue);
}

class TripColorCarousel extends StatefulWidget {
  final int selectedColor;
  final ValueChanged<int> onColorSelected;

  static const List<TripColorTheme> themes = [
    TripColorTheme(
      colorValue: 0xFFD85A30,
      secondaryColorValue: 0xFFFF8E53,
      name: 'Sunset Coral',
      tag: 'Warm & Adventurous',
      emoji: '🌅',
    ),
    TripColorTheme(
      colorValue: 0xFF0072FF,
      secondaryColorValue: 0xFF00C6FF,
      name: 'Ocean Azure',
      tag: 'Beach & Island Vibes',
      emoji: '🌊',
    ),
    TripColorTheme(
      colorValue: 0xFF10B981,
      secondaryColorValue: 0xFF38EF7D,
      name: 'Emerald Lagoon',
      tag: 'Nature & Eco Travels',
      emoji: '🌿',
    ),
    TripColorTheme(
      colorValue: 0xFF8B5CF6,
      secondaryColorValue: 0xFFC084FC,
      name: 'Twilight Neon',
      tag: 'City Lights & Nightlife',
      emoji: '💜',
    ),
    TripColorTheme(
      colorValue: 0xFFF59E0B,
      secondaryColorValue: 0xFFFBBF24,
      name: 'Golden Hour',
      tag: 'Sunshine & Warm Haven',
      emoji: '🌋',
    ),
    TripColorTheme(
      colorValue: 0xFFE91E63,
      secondaryColorValue: 0xFFFF6090,
      name: 'Rose Dusk',
      tag: 'Romantic & Cultural',
      emoji: '🌸',
    ),
    TripColorTheme(
      colorValue: 0xFF2C1A14,
      secondaryColorValue: 0xFF4A3E3D,
      name: 'Cosmic Night',
      tag: 'Sleek Obsidian Glow',
      emoji: '🌌',
    ),
    TripColorTheme(
      colorValue: 0xFF009688,
      secondaryColorValue: 0xFF4DB6AC,
      name: 'Pacific Teal',
      tag: 'Marine Excursions',
      emoji: '🏝️',
    ),
  ];

  const TripColorCarousel({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  State<TripColorCarousel> createState() => _TripColorCarouselState();
}

class _TripColorCarouselState extends State<TripColorCarousel> {
  static const int _kInfiniteCenterMultiplier = 1000;
  late PageController _pageController;
  int _currentRealIndex = 0;

  int get _themeCount => TripColorCarousel.themes.length;

  @override
  void initState() {
    super.initState();
    final realIdx = TripColorCarousel.themes.indexWhere(
      (t) => t.colorValue == widget.selectedColor,
    );
    _currentRealIndex = realIdx >= 0 ? realIdx : 0;
    final initialPage = (_kInfiniteCenterMultiplier * _themeCount) + _currentRealIndex;

    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: 0.76,
    );
  }

  @override
  void didUpdateWidget(TripColorCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedColor != widget.selectedColor) {
      final targetRealIdx = TripColorCarousel.themes.indexWhere(
        (t) => t.colorValue == widget.selectedColor,
      );
      if (targetRealIdx >= 0 &&
          targetRealIdx != _currentRealIndex &&
          _pageController.hasClients) {
        final currentCombinedPage = _pageController.page?.round() ?? _pageController.initialPage;
        final currentOffset = currentCombinedPage % _themeCount;
        final diff = targetRealIdx - currentOffset;
        final targetCombinedPage = currentCombinedPage + diff;

        _currentRealIndex = targetRealIdx;
        _pageController.animateToPage(
          targetCombinedPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final realIdx = index % _themeCount;
    if (realIdx != _currentRealIndex) {
      setState(() => _currentRealIndex = realIdx);
      widget.onColorSelected(TripColorCarousel.themes[realIdx].colorValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 175,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final realIndex = index % _themeCount;
              final theme = TripColorCarousel.themes[realIndex];
              final isSelected = realIndex == _currentRealIndex;

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page! - index).abs();
                    value = (1 - (value * 0.15)).clamp(0.85, 1.0);
                  } else {
                    value = isSelected ? 1.0 : 0.88;
                  }

                  return Transform.scale(
                    scale: value,
                    child: GestureDetector(
                      onTap: () {
                        if (_pageController.hasClients) {
                          final currentPage = _pageController.page?.round() ?? index;
                          if (currentPage != index) {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOutCubic,
                            );
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            colors: [theme.color, theme.secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.color.withValues(alpha: isSelected ? 0.38 : 0.15),
                              blurRadius: isSelected ? 16 : 8,
                              spreadRadius: isSelected ? 2 : 0,
                              offset: Offset(0, isSelected ? 8 : 4),
                            ),
                          ],
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: isSelected ? 2.5 : 0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Ambient shine circle
                            Positioned(
                              top: -20,
                              right: -20,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.22),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(theme.emoji, style: const TextStyle(fontSize: 13)),
                                            const SizedBox(width: 5),
                                            Text(
                                              theme.tag,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black.withValues(alpha: 0.20),
                                        ),
                                        child: isSelected
                                            ? Icon(Icons.check_rounded,
                                                size: 18, color: theme.color)
                                            : null,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        theme.name,
                                        style: const TextStyle(
                                          fontFamily: AppTextStyles.fontHeading,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '#${theme.colorValue.toRadixString(16).substring(2).toUpperCase()}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(alpha: 0.75),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _themeCount,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentRealIndex ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i == _currentRealIndex
                    ? TripColorCarousel.themes[i].color
                    : AppColors.cardBorder,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
