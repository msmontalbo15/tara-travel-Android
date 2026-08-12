/// connectivity_service.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Singleton network state service backed by [connectivity_plus].
///
/// Provides both a one-shot [isOnline] check (socket probe for accuracy) and
/// a continuous [onlineStream] for reactive UI updates (e.g. [OfflineBanner]).
///
/// Design notes:
/// • Uses a real TCP socket probe to [8.8.8.8:53] to avoid false-positives
///   from connectivity_plus (which only checks interface state, not actual
///   internet reachability).
/// • Caches the last known state synchronously for use in build() calls.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._() {
    _init();
  }

  // ── State ──────────────────────────────────────────────────────────────────
  bool _cachedIsOnline = true;
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  // ── Init ───────────────────────────────────────────────────────────────────

  void _init() {
    Connectivity().onConnectivityChanged.listen((results) async {
      // connectivity_plus v6 returns List<ConnectivityResult>
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) {
        _update(false);
        return;
      }
      // Probe to confirm actual internet access
      final reachable = await _probeInternet();
      _update(reachable);
    });
  }

  void _update(bool online) {
    _cachedIsOnline = online;
    _controller.add(online);
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns `true` if the device currently has internet access.
  /// Performs a lightweight TCP socket probe — always accurate.
  Future<bool> get isOnline async {
    try {
      final results = await Connectivity().checkConnectivity();
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) {
        _update(false);
        return false;
      }
      final reachable = await _probeInternet();
      _update(reachable);
      return reachable;
    } catch (e) {
      debugPrint('[ConnectivityService] isOnline error: $e');
      return _cachedIsOnline;
    }
  }

  /// Stream of connectivity state — `true` = online, `false` = offline.
  /// Emits whenever the network state changes.
  Stream<bool> get onlineStream => _controller.stream;

  /// Last known connectivity state — synchronous, suitable for build().
  bool get cachedIsOnline => _cachedIsOnline;

  // ── TCP Probe ──────────────────────────────────────────────────────────────

  /// Opens a 3-second TCP socket to Google DNS [8.8.8.8:53].
  /// Returns `true` if the connection succeeds (real internet access).
  Future<bool> _probeInternet() async {
    try {
      final socket = await Socket.connect('8.8.8.8', 53,
          timeout: const Duration(seconds: 3));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
