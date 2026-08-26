import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages active user presence telemetry in Supabase.
///
/// Features:
/// • Automatically sets `is_online = true` and `last_seen = now()` on foregrounding.
/// • Dispatches periodic heartbeats every 45s to maintain active presence.
/// • Marks `is_online = false` on backgrounding / app pause / logout.
class UserPresenceService with WidgetsBindingObserver {
  UserPresenceService._();
  static final UserPresenceService instance = UserPresenceService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  Timer? _heartbeatTimer;
  bool _isStarted = false;
  String? _activeUserId;

  /// Starts presence tracking for the authenticated user.
  void start([String? userId]) {
    final uid = userId ?? _supabase.auth.currentUser?.id;
    if (uid == null) return;

    if (_isStarted && _activeUserId == uid) return;

    _activeUserId = uid;
    _isStarted = true;

    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);

    // Initial online ping
    setOnline();

    // Periodic heartbeat every 45 seconds
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      setOnline();
    });

    debugPrint('[UserPresenceService] Started presence tracking for $uid');
  }

  /// Stops presence tracking and marks user offline.
  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (_isStarted) {
      WidgetsBinding.instance.removeObserver(this);
      _isStarted = false;
      await setOffline();
    }

    _activeUserId = null;
    debugPrint('[UserPresenceService] Stopped presence tracking.');
  }

  /// Sets user state to online with current timestamp.
  Future<void> setOnline() async {
    final userId = _activeUserId ?? _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('users').update({
        'is_online': true,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('[UserPresenceService] setOnline error: $e');
    }
  }

  /// Sets user state to offline with current timestamp.
  Future<void> setOffline() async {
    final userId = _activeUserId ?? _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('users').update({
        'is_online': false,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('[UserPresenceService] setOffline error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isStarted) return;

    switch (state) {
      case AppLifecycleState.resumed:
        setOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        setOffline();
        break;
    }
  }
}
