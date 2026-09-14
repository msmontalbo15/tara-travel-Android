import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Semantic styling variant for [QuickActionTile].
enum QuickActionVariant {
  primary,
  surface,
  accent,
}

/// Quick action tile for home screen grid — brand-aligned with smooth micro-interactions,
/// accessibility semantics, and dark-mode & tablet scaling resilience.
class QuickActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final bool orange;
  final QuickActionVariant? variant;
  final VoidCallback onTap;

  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.sublabel,
    this.orange = false,
    this.variant,
    required this.onTap,
  });

  @override
  State<QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<QuickActionTile> {
  bool _isPressed = false;

  QuickActionVariant get _effectiveVariant {
    if (widget.variant != null) return widget.variant!;
    return widget.orange ? QuickActionVariant.primary : QuickActionVariant.surface;
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final variant = _effectiveVariant;
    final isPrimary = variant == QuickActionVariant.primary;

    // Theme and variant color resolutions
    final Color cardBackground;
    final Gradient? cardGradient;
    final Color borderColor;
    final List<BoxShadow> shadows;
    final Color iconBoxColor;
    final Color iconColor;
    final Color labelColor;
    final Color sublabelColor;

    if (isPrimary) {
      cardBackground = AppColors.primary;
      cardGradient = const LinearGradient(
        colors: [AppColors.primary, Color(0xFFEA7A52)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderColor = const Color(0xFFE87040).withValues(alpha: 0.5);
      shadows = [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: isDark ? 0.40 : 0.28),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
      iconBoxColor = Colors.white.withValues(alpha: 0.22);
      iconColor = Colors.white;
      labelColor = Colors.white;
      sublabelColor = Colors.white.withValues(alpha: 0.85);
    } else if (variant == QuickActionVariant.accent) {
      cardBackground = isDark ? const Color(0xFF281E15) : AppColors.sand;
      cardGradient = null;
      borderColor = AppColors.amber.withValues(alpha: 0.35);
      shadows = [
        BoxShadow(
          color: AppColors.amber.withValues(alpha: isDark ? 0.2 : 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
      iconBoxColor = AppColors.amber.withValues(alpha: 0.2);
      iconColor = AppColors.amberText;
      labelColor = isDark ? Colors.white : AppColors.textPrimary;
      sublabelColor = isDark ? Colors.white70 : AppColors.textSecondary;
    } else {
      // Surface
      cardBackground = isDark ? const Color(0xFF221612) : Colors.white;
      cardGradient = isDark
          ? const LinearGradient(
              colors: [Color(0xFF251813), Color(0xFF1E130E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : const LinearGradient(
              colors: [Colors.white, Color(0xFFFDFDFD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : AppColors.cardBorder;
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
      iconBoxColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : AppColors.sand;
      iconColor = AppColors.primary;
      labelColor = isDark ? Colors.white : AppColors.textPrimary;
      sublabelColor = isDark ? Colors.white60 : AppColors.textSecondary;
    }

    return Semantics(
      button: true,
      label: widget.sublabel != null
          ? '${widget.label}, ${widget.sublabel}'
          : widget.label,
      child: Tooltip(
        message: widget.label,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              color: cardBackground,
              gradient: cardGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 0.8),
              boxShadow: shadows,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onHighlightChanged: (highlighted) {
                  setState(() => _isPressed = highlighted);
                },
                onTap: _handleTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: iconBoxColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 17,
                          color: iconColor,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.label,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontBody,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ).copyWith(color: labelColor),
                            ),
                          ),
                          if (widget.sublabel != null) ...[
                            const SizedBox(height: 1.5),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.sublabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontBody,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ).copyWith(color: sublabelColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

