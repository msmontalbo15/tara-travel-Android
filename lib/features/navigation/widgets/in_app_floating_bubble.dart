import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/floating_bubble_service.dart';
import '../../../core/services/notification_router.dart';

/// Global Draggable Floating Bubble HUD (In-App Mode)
/// Renders an edge-snapping circular bubble that expands into a Mini-HUD.
class InAppFloatingBubbleContainer extends ConsumerStatefulWidget {
  final Widget child;

  const InAppFloatingBubbleContainer({super.key, required this.child});

  @override
  ConsumerState<InAppFloatingBubbleContainer> createState() =>
      _InAppFloatingBubbleContainerState();
}

class _InAppFloatingBubbleContainerState
    extends ConsumerState<InAppFloatingBubbleContainer> {
  Offset? _dragOffset;

  @override
  Widget build(BuildContext context) {
    final bubbleState = ref.watch(floatingBubbleProvider);
    final screenSize = MediaQuery.sizeOf(context);

    if (!bubbleState.isVisible) {
      return widget.child;
    }

    final currentPos = _dragOffset ?? bubbleState.position;

    return Stack(
      children: [
        widget.child,
        // Expanded Mini-HUD backdrop dismiss overlay
        if (bubbleState.isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: () =>
                  ref.read(floatingBubbleProvider.notifier).toggleExpanded(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
          ),

        // Expanded Mini-HUD Card
        if (bubbleState.isExpanded)
          Positioned(
            left: 20,
            right: 20,
            top: (currentPos.dy - 120).clamp(100.0, screenSize.height - 320.0),
            child: _MiniHudCard(
              state: bubbleState,
              onClose: () =>
                  ref.read(floatingBubbleProvider.notifier).toggleExpanded(),
              onOpenNavigation: () {
                ref.read(floatingBubbleProvider.notifier).toggleExpanded();
                NotificationRouter.instance.navigateTo(
                  const NotificationPayload(
                    targetScreen: NotificationTargetScreen.navigation,
                  ),
                );
              },
              onQuickExpense: () {
                ref.read(floatingBubbleProvider.notifier).toggleExpanded();
                NotificationRouter.instance.navigateTo(
                  const NotificationPayload(
                    targetScreen: NotificationTargetScreen.expenses,
                  ),
                );
              },
              onDismissBubble: () {
                HapticFeedback.mediumImpact().catchError((_) {});
                ref.read(floatingBubbleProvider.notifier).hideBubble();
              },
            ),
          ),

        // Draggable Floating Circular Bubble
        Positioned(
          left: currentPos.dx,
          top: currentPos.dy,
          child: GestureDetector(
            onPanStart: (_) {
              _dragOffset = bubbleState.position;
            },
            onPanUpdate: (details) {
              setState(() {
                _dragOffset = Offset(
                  (_dragOffset?.dx ?? currentPos.dx) + details.delta.dx,
                  (_dragOffset?.dy ?? currentPos.dy) + details.delta.dy,
                );
              });
            },
            onPanEnd: (_) {
              if (_dragOffset != null) {
                HapticFeedback.selectionClick().catchError((_) {});
                ref
                    .read(floatingBubbleProvider.notifier)
                    .updatePosition(_dragOffset!, screenSize);
                setState(() => _dragOffset = null);
              }
            },
            onTap: () {
              HapticFeedback.lightImpact().catchError((_) {});
              ref.read(floatingBubbleProvider.notifier).toggleExpanded();
            },
            child: _BubbleWidget(isExpanded: bubbleState.isExpanded),
          ),
        ),
      ],
    );
  }
}

class _BubbleWidget extends StatelessWidget {
  final bool isExpanded;

  const _BubbleWidget({required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.deepEarth,
        shape: BoxShape.circle,
        border: Border.all(
          color: isExpanded ? AppColors.primary : AppColors.primaryLight,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.navigation_rounded,
              color: AppColors.primaryLight,
              size: 26,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.greenBright,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniHudCard extends StatelessWidget {
  final FloatingBubbleState state;
  final VoidCallback onClose;
  final VoidCallback onOpenNavigation;
  final VoidCallback onQuickExpense;
  final VoidCallback onDismissBubble;

  const _MiniHudCard({
    required this.state,
    required this.onClose,
    required this.onOpenNavigation,
    required this.onQuickExpense,
    required this.onDismissBubble,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.deepEarth.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'CONVOY HUD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.nextStopEta ?? 'On Route',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Destination & Next Stop
              Text(
                'NEXT DESTINATION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.pin_drop_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      state.nextStopName ?? 'Next Scheduled Stop',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (state.nextStopDistanceKm != null)
                    Text(
                      '${state.nextStopDistanceKm!.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Convoy companion distance radar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group_rounded,
                        color: AppColors.primaryLight, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.closestCompanionName != null
                            ? 'Tail: ${state.closestCompanionName} (${state.closestCompanionDistanceKm?.toStringAsFixed(1) ?? "0.0"} km away)'
                            : 'Convoy Squad: All within range',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onQuickExpense,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: const Text('Log Toll/Gas',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onOpenNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: const Text('Open Map',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: onDismissBubble,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Hide Floating Bubble',
                      style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
