import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/feedback/app_feedback.dart';

/// Reusable masked invite code component with tap-to-reveal, eye toggle,
/// auto-hide security timer (12s), and instant copy/share functionality.
class PrivacyInviteCodeWidget extends StatefulWidget {
  final String inviteCode;
  final String tripName;
  final bool compact;
  final Color? backgroundColor;
  final Color? textColor;

  const PrivacyInviteCodeWidget({
    super.key,
    required this.inviteCode,
    required this.tripName,
    this.compact = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<PrivacyInviteCodeWidget> createState() =>
      _PrivacyInviteCodeWidgetState();
}

class _PrivacyInviteCodeWidgetState extends State<PrivacyInviteCodeWidget> {
  bool _isRevealed = false;
  Timer? _autoHideTimer;

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _toggleReveal() {
    setState(() {
      _isRevealed = !_isRevealed;
    });

    _autoHideTimer?.cancel();
    if (_isRevealed) {
      _autoHideTimer = Timer(const Duration(seconds: 12), () {
        if (mounted) {
          setState(() {
            _isRevealed = false;
          });
        }
      });
    }
  }

  void _copyCode() {
    if (widget.inviteCode.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: widget.inviteCode));
    HapticFeedback.lightImpact();
    AppFeedback.showSuccess(
      context,
      'Invite code copied: ${widget.inviteCode}',
      title: 'Copied to Clipboard 📋',
    );
  }

  void _shareCode() {
    if (widget.inviteCode.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    SharePlus.instance.share(
      ShareParams(
        text:
            'Join my trip "${widget.tripName}" on Tara Travel! Enter invite code: ${widget.inviteCode}',
        subject: 'Trip Invite Code for ${widget.tripName}',
      ),
    );
  }

  String get _displayCode {
    if (widget.inviteCode.trim().isEmpty) return '------';
    if (_isRevealed) return widget.inviteCode;
    return '•' * widget.inviteCode.length;
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? Colors.white.withValues(alpha: 0.12);
    final fg = widget.textColor ?? Colors.white;

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fg.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _toggleReveal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _displayCode,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: _isRevealed ? 2.5 : 3.0,
                      color: fg,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _isRevealed
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 15,
                    color: fg.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _copyCode,
              child: Icon(
                Icons.copy_rounded,
                size: 15,
                color: fg.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggleReveal,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayCode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: _isRevealed ? 3.5 : 4.5,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  _isRevealed
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 18,
                  color: fg.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _copyCode,
            tooltip: 'Copy Invite Code',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            icon: Icon(
              Icons.copy_rounded,
              size: 18,
              color: fg.withValues(alpha: 0.8),
            ),
          ),
          IconButton(
            onPressed: _shareCode,
            tooltip: 'Share Invite Code',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            icon: Icon(
              Icons.share_rounded,
              size: 18,
              color: fg.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
