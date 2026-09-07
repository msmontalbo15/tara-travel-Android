import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../widgets/feedback/app_feedback.dart';

/// PrivacyInviteCodeWidget
/// ─────────────────────────────────────────────────────────────────────────────
/// Displays a trip or circle invite code with shoulder-surfing protection:
/// • Masked by default (`••••••` / `******`) in equal tracking.
/// • Tap card or eye icon to reveal the plain text code.
/// • Auto-re-masks automatically after [autoMaskDuration] (default 12 seconds).
/// • 1-tap copy action with feedback and haptic vibration.
/// ─────────────────────────────────────────────────────────────────────────────
class PrivacyInviteCodeWidget extends StatefulWidget {
  final String code;
  final TextStyle? codeStyle;
  final Duration autoMaskDuration;
  final VoidCallback? onShare;
  final bool showShareButton;
  final bool compact;

  const PrivacyInviteCodeWidget({
    super.key,
    required this.code,
    this.codeStyle,
    this.autoMaskDuration = const Duration(seconds: 12),
    this.onShare,
    this.showShareButton = true,
    this.compact = false,
  });

  @override
  State<PrivacyInviteCodeWidget> createState() => _PrivacyInviteCodeWidgetState();
}

class _PrivacyInviteCodeWidgetState extends State<PrivacyInviteCodeWidget> {
  bool _isRevealed = false;
  bool _copied = false;
  Timer? _autoMaskTimer;

  @override
  void dispose() {
    _autoMaskTimer?.cancel();
    super.dispose();
  }

  void _toggleReveal() {
    HapticFeedback.selectionClick();
    setState(() {
      _isRevealed = !_isRevealed;
      _autoMaskTimer?.cancel();

      if (_isRevealed) {
        _autoMaskTimer = Timer(widget.autoMaskDuration, () {
          if (mounted) {
            setState(() => _isRevealed = false);
          }
        });
      }
    });
  }

  void _copyToClipboard() {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);

    AppFeedback.showSuccess(
      context,
      'Invite code copied: ${widget.code}',
      title: 'Copied to Clipboard 📋',
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  String _formatMaskedCode() {
    if (widget.code.isEmpty) return '••••••';
    return '•' * widget.code.length;
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _isRevealed ? widget.code : _formatMaskedCode();

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggleReveal,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                displayText,
                key: ValueKey<bool>(_isRevealed),
                style: widget.codeStyle ??
                    const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _toggleReveal,
            child: Icon(
              _isRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _copyToClipboard,
            child: Icon(
              _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
              size: 16,
              color: _copied ? AppColors.greenBright : Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A04), Color(0xFF2C1A14)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'INVITE CODE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.40),
                                letterSpacing: 1.8,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _isRevealed
                                    ? AppColors.primary.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _isRevealed ? 'REVEALED' : 'PROTECTED',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: _isRevealed ? AppColors.primary : Colors.white54,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _toggleReveal,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  displayText,
                                  key: ValueKey<bool>(_isRevealed),
                                  style: widget.codeStyle ??
                                      const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 4.5,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                _isRevealed
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.50),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isRevealed
                            ? 'Tap eye to hide • Auto-hides in ${widget.autoMaskDuration.inSeconds}s'
                            : 'Tap code or eye to reveal • Share with your squad',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      if (widget.showShareButton && widget.onShare != null) ...[
                        _ActionIconBtn(
                          icon: Icons.share_rounded,
                          tooltip: 'Share Invite',
                          onTap: widget.onShare!,
                        ),
                        const SizedBox(height: 8),
                      ],
                      _ActionIconBtn(
                        icon: _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                        tooltip: 'Copy Code',
                        activeColor: _copied ? AppColors.greenBright : null,
                        onTap: _copyToClipboard,
                      ),
                    ],
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

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? activeColor;

  const _ActionIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: activeColor != null
                ? activeColor!.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: activeColor != null
                  ? activeColor!.withValues(alpha: 0.40)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: activeColor ?? Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
