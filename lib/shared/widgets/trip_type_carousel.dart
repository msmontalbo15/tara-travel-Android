import 'package:flutter/material.dart';

import '../../core/constants/trip_types.dart';
import '../../core/theme/app_colors.dart';

/// Reusable trip-type carousel used in both Create Trip and Edit Trip flows.
///
/// Renders an infinite-scroll [PageView] of [AppTripTypes.all] cards with
/// gradient backgrounds, emoji watermarks, category badges, and dot indicators.
class TripTypeCarousel extends StatefulWidget {
  final String selectedTripType;
  final ValueChanged<TripTypeOption> onTypeSelected;

  /// Whether to show the dot indicator row beneath the carousel.
  final bool showDots;

  const TripTypeCarousel({
    super.key,
    required this.selectedTripType,
    required this.onTypeSelected,
    this.showDots = true,
  });

  @override
  State<TripTypeCarousel> createState() => _TripTypeCarouselState();
}

class _TripTypeCarouselState extends State<TripTypeCarousel> {
  static const int _kCenter = 1000;
  late PageController _pageController;
  int _currentRealIndex = 0;

  int get _count => AppTripTypes.all.length;

  @override
  void initState() {
    super.initState();
    final activeOpt = AppTripTypes.getOption(widget.selectedTripType);
    final idx = AppTripTypes.all.indexWhere((o) => o.id == activeOpt.id);
    _currentRealIndex = idx >= 0 ? idx : 0;
    _pageController = PageController(
      initialPage: (_kCenter * _count) + _currentRealIndex,
      viewportFraction: 0.76,
    );
  }

  @override
  void didUpdateWidget(TripTypeCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTripType != widget.selectedTripType) {
      final activeOpt = AppTripTypes.getOption(widget.selectedTripType);
      final targetIdx =
          AppTripTypes.all.indexWhere((o) => o.id == activeOpt.id);
      if (targetIdx >= 0 &&
          targetIdx != _currentRealIndex &&
          _pageController.hasClients) {
        final curPage =
            _pageController.page?.round() ?? _pageController.initialPage;
        final curOffset = curPage % _count;
        final diff = targetIdx - curOffset;
        _currentRealIndex = targetIdx;
        _pageController.animateToPage(
          curPage + diff,
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
    final realIdx = index % _count;
    if (realIdx != _currentRealIndex) {
      setState(() => _currentRealIndex = realIdx);
      widget.onTypeSelected(AppTripTypes.all[realIdx]);
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
              final realIndex = index % _count;
              final option = AppTripTypes.all[realIndex];
              final isSelected = realIndex == _currentRealIndex;

              // Derive a lighter accent for the gradient end
              final accentLight = HSLColor.fromColor(option.accentColor)
                  .withLightness(
                    (HSLColor.fromColor(option.accentColor).lightness + 0.18)
                        .clamp(0.0, 1.0),
                  )
                  .toColor();

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
                          final curPage =
                              _pageController.page?.round() ?? index;
                          if (curPage != index) {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOutCubic,
                            );
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            colors: [option.accentColor, accentLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: option.accentColor.withValues(
                                  alpha: isSelected ? 0.38 : 0.15),
                              blurRadius: isSelected ? 16 : 8,
                              spreadRadius: isSelected ? 2 : 0,
                              offset: Offset(0, isSelected ? 8 : 4),
                            ),
                          ],
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: isSelected ? 2.5 : 0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Ambient shine blob
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
                            // Large emoji watermark in card corner
                            Positioned(
                              right: 12,
                              bottom: 6,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: 0.28,
                                  child: Transform.rotate(
                                    angle: -0.12,
                                    child: Text(
                                      option.emoji,
                                      style: const TextStyle(
                                        fontSize: 64,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Glassmorphic category badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.35),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.3),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                option.emoji,
                                                style: const TextStyle(fontSize: 18),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              option.category,
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Check circle
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black
                                                  .withValues(alpha: 0.20),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.15),
                                                    blurRadius: 6,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: isSelected
                                            ? Icon(Icons.check_rounded,
                                                size: 20,
                                                color: option.accentColor)
                                            : null,
                                      ),
                                    ],
                                  ),
                                  // Label & subtitle
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.label,
                                        style: const TextStyle(
                                          fontFamily: 'Playfair Display',
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.1,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black26,
                                              offset: Offset(0, 1),
                                              blurRadius: 3,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        option.subtitle,
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white
                                              .withValues(alpha: 0.90),
                                          letterSpacing: 0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
        if (widget.showDots) ...[
          const SizedBox(height: 10),
          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _count,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentRealIndex ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i == _currentRealIndex
                      ? AppTripTypes.all[i].accentColor
                      : AppColors.cardBorder,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
