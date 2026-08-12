/// offline_banner.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Animated global offline indicator banner.
///
/// Slides down from the top of the screen when the device goes offline and
/// briefly shows a "Back online" confirmation when connectivity is restored.
///
/// Usage: wrap the root [Scaffold] body with [OfflineBanner.wrap] or place
/// it as the first child of a [Column] inside the navigation shell.
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
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  StreamSubscription<bool>? _connectivitySub;
  bool _isOffline = !ConnectivityService.instance.cachedIsOnline;
  Timer? _onlineConfirmTimer;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    if (_isOffline) _animCtrl.forward();

    _connectivitySub =
        ConnectivityService.instance.onlineStream.listen(_onConnectivityChanged);
  }

  void _onConnectivityChanged(bool isOnline) {
    if (!mounted) return;
    setState(() {
      _isOffline = !isOnline;
    });

    if (!isOnline) {
      _onlineConfirmTimer?.cancel();
      _animCtrl.forward();
    } else {
      // Show "Back online" for 2.5 seconds then slide out
      _onlineConfirmTimer?.cancel();
      _animCtrl.forward();
      _onlineConfirmTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) {
          _animCtrl.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _onlineConfirmTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Animated Banner ────────────────────────────────────────────────
        SlideTransition(
          position: _slideAnim,
          child: _isOffline ? _offlineBanner() : _onlineBanner(),
        ),
        // ── App Content ────────────────────────────────────────────────────
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _offlineBanner() => Container(
        width: double.infinity,
        color: const Color(0xFFF59E0B), // amber-500
        padding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'No internet connection — showing saved data',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );

  Widget _onlineBanner() => Container(
        width: double.infinity,
        color: const Color(0xFF10B981), // emerald-500
        padding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              '✓ Back online — syncing your changes',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}
