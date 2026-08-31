import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// High-contrast, driver-ready "Slide to Confirm Arrival" slider button.
///
/// Designed specifically for vehicle drivers and navigators:
/// - Generous touch targets and high-visibility contrast.
/// - Requires deliberate horizontal slide to prevent accidental pocket/bumpy-road taps.
/// - Haptic feedback on drag progress and confirmation trigger.
/// - Smooth spring physics with automatic snap-back if released before threshold.
class SlideToArriveButton extends StatefulWidget {
  final VoidCallback onConfirmed;
  final String label;
  final String confirmedLabel;
  final Color activeColor;
  final Color confirmedColor;
  final IconData icon;
  final double height;

  const SlideToArriveButton({
    super.key,
    required this.onConfirmed,
    this.label = 'Slide to Confirm Arrival',
    this.confirmedLabel = '✓ Arrival Confirmed',
    this.activeColor = AppColors.primary,
    this.confirmedColor = AppColors.greenBright,
    this.icon = Icons.directions_car_rounded,
    this.height = 56.0,
  });

  @override
  State<SlideToArriveButton> createState() => _SlideToArriveButtonState();
}

class _SlideToArriveButtonState extends State<SlideToArriveButton>
    with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  bool _isConfirmed = false;
  bool _isDragging = false;

  late final AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (_isConfirmed) return;
    _resetController.stop();
    setState(() => _isDragging = true);
    HapticFeedback.selectionClick();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isConfirmed) return;
    setState(() {
      _dragValue = (_dragValue + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (_isConfirmed) return;
    setState(() => _isDragging = false);

    // 75% threshold required to confirm
    if (_dragValue >= maxDrag * 0.75) {
      _confirm(maxDrag);
    } else {
      _reset();
    }
  }

  void _confirm(double maxDrag) async {
    HapticFeedback.heavyImpact();
    setState(() {
      _dragValue = maxDrag;
      _isConfirmed = true;
    });

    await Future.delayed(const Duration(milliseconds: 220));
    widget.onConfirmed();
  }

  void _reset() {
    _resetAnimation = Tween<double>(
      begin: _dragValue,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() => _dragValue = _resetAnimation.value);
      });

    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    const knobPadding = 4.0;
    final knobSize = widget.height - (knobPadding * 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final maxDrag = totalWidth - knobSize - (knobPadding * 2);
        final progress = maxDrag > 0 ? (_dragValue / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: _isConfirmed
                ? widget.confirmedColor
                : AppColors.deepEarth,
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: [
              BoxShadow(
                color: _isConfirmed
                    ? widget.confirmedColor.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. Highlight Fill Track (expands with drag)
              if (!_isConfirmed)
                Container(
                  width: _dragValue + knobSize + (knobPadding * 2),
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: widget.activeColor.withValues(alpha: 0.35 + (progress * 0.45)),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),

              // 2. Track Prompt Text (Shimmers & fades as user slides)
              Center(
                child: AnimatedOpacity(
                  opacity: _isConfirmed ? 0.0 : (1.0 - (progress * 1.4)).clamp(0.0, 1.0),
                  duration: const Duration(milliseconds: 80),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Confirmed Label (when reached end)
              if (_isConfirmed)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.confirmedLabel,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

              // 4. Sliding Knob
              Positioned(
                left: knobPadding + _dragValue,
                child: GestureDetector(
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: (d) => _onDragUpdate(d, maxDrag),
                  onHorizontalDragEnd: (d) => _onDragEnd(d, maxDrag),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      color: _isConfirmed
                          ? Colors.white
                          : widget.activeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isConfirmed ? Colors.white : widget.activeColor)
                              .withValues(alpha: 0.45),
                          blurRadius: _isDragging ? 12 : 8,
                          spreadRadius: _isDragging ? 2 : 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isConfirmed
                            ? Icons.check_rounded
                            : widget.icon,
                        color: _isConfirmed
                            ? widget.confirmedColor
                            : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
