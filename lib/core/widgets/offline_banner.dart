/// offline_banner.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Discreet connectivity status dot indicator.
///
/// Replaces the intrusive full-width banners with a minimal, floating dot indicator
/// that signals offline state and briefly shows online reconnection status.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';

class OfflineBanner extends StatefulWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  StreamSubscription<bool>? _connectivitySub;
  bool _isOffline = !ConnectivityService.instance.cachedIsOnline;
  bool _showOnlineIndicator = false;
  Timer? _onlineHideTimer;

  @override
  void initState() {
    super.initState();
    _connectivitySub =
        ConnectivityService.instance.onlineStream.listen(_onConnectivityChanged);
  }

  void _onConnectivityChanged(bool isOnline) {
    if (!mounted) return;
    _onlineHideTimer?.cancel();

    if (!isOnline) {
      setState(() {
        _isOffline = true;
        _showOnlineIndicator = false;
      });
    } else {
      // If we were previously offline, briefly show green dot indicator for 2.5 seconds
      if (_isOffline) {
        setState(() {
          _isOffline = false;
          _showOnlineIndicator = true;
        });
        _onlineHideTimer = Timer(const Duration(milliseconds: 2500), () {
          if (mounted) {
            setState(() {
              _showOnlineIndicator = false;
            });
          }
        });
      } else {
        setState(() {
          _isOffline = false;
          _showOnlineIndicator = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _onlineHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showIndicator = _isOffline || _showOnlineIndicator;

    return Stack(
      children: [
        // Main App Content
        widget.child,

        // Floating Minimal Dot Indicator
        if (showIndicator)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 6,
            right: 14,
            child: SafeArea(
              top: false,
              bottom: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: _isOffline
                    ? _buildDot(
                        key: const ValueKey('offline_dot'),
                        color: const Color(0xFFF59E0B), // amber / offline
                        tooltip: 'Offline mode — showing saved data',
                        pulse: true,
                      )
                    : _buildDot(
                        key: const ValueKey('online_dot'),
                        color: const Color(0xFF10B981), // emerald / back online
                        tooltip: 'Back online',
                        pulse: false,
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDot({
    required Key key,
    required Color color,
    required String tooltip,
    required bool pulse,
  }) {
    return Tooltip(
      key: key,
      message: tooltip,
      preferBelow: true,
      verticalOffset: 12,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

