/// auth_gate.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Route guard that observes [authNotifierProvider] (MVI [AuthState]) and
/// wires the Supabase auth stream for session lifecycle events.
///
/// Responsibilities:
/// • Routing: swaps between /home, /onboarding, and / based on auth state.
/// • Session persistence: persists refreshed tokens via [SecureSessionRepository]
///   whenever Supabase fires a [tokenRefreshed] event.
/// • Database isolation: calls [DatabaseService.switchUser] on sign-in/out.
/// • Provider invalidation: clears in-memory caches on sign-out.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show AuthState;

import '../auth/presentation/auth_notifier.dart';
import '../providers/profile_provider.dart';
import '../services/database_service.dart';

class _RouteTrackingObserver extends NavigatorObserver {
  String? currentRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      currentRoute = route.settings.name;
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      currentRoute = newRoute!.settings.name;
    }
  }
}

class AuthGate extends ConsumerStatefulWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final _RouteTrackingObserver _routeObserver = _RouteTrackingObserver();

  @override
  void initState() {
    super.initState();
    // Subscribe to raw Supabase auth stream for lifecycle events that the
    // MVI notifier does not need to expose as state transitions (e.g.,
    // tokenRefreshed — which is an internal housekeeping concern).
    Supabase.instance.client.auth.onAuthStateChange.listen(_onSupabaseAuthEvent);
  }

  // ── Supabase Auth Stream Handler ───────────────────────────────────────────

  Future<void> _onSupabaseAuthEvent(supabase.AuthState supaState) async {
    final event   = supaState.event;
    final session = supaState.session;

    if (event == AuthChangeEvent.tokenRefreshed && session != null) {
      // Persist the refreshed tokens to encrypted storage so the offline
      // session remains valid after the refresh without requiring re-login.
      await ref.read(authNotifierProvider.notifier).onTokenRefreshed(session);
      return;
    }

    if (event == AuthChangeEvent.signedIn && session != null) {
      // Switch the local database to the authenticated user's partition.
      await DatabaseService.instance.switchUser(session.user.id);
      // Refresh profile from remote to detect returning users with completed
      // onboarding so we can skip the onboarding flow.
      await ref.read(profileProvider.notifier).refreshProfile();
      if (!mounted) return;

      final profile = ref.read(profileProvider);
      if (profile.hasCompletedOnboarding) {
        _navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        // Only navigate to /onboarding if not already on the onboarding route.
        // If already on /onboarding, avoid resetting the PageView state.
        if (_routeObserver.currentRoute != '/onboarding') {
          _navigatorKey.currentState
              ?.pushNamedAndRemoveUntil('/onboarding', (route) => false);
        }
      }
      return;
    }

    if (event == AuthChangeEvent.signedOut) {
      // Revert the local database to the default anonymous partition.
      await DatabaseService.instance.switchUser('default');
      // Invalidate all in-memory provider caches.
      ref.invalidate(profileProvider);
      _navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.child is MaterialApp) {
      final materialApp = widget.child as MaterialApp;
      final existingObservers = materialApp.navigatorObservers ?? const <NavigatorObserver>[];

      return MaterialApp(
        key:                      materialApp.key,
        navigatorKey:             _navigatorKey,
        scaffoldMessengerKey:     materialApp.scaffoldMessengerKey,
        home:                     materialApp.home,
        routes:                   materialApp.routes ?? const {},
        initialRoute:             materialApp.initialRoute,
        onGenerateRoute:          materialApp.onGenerateRoute,
        onUnknownRoute:           materialApp.onUnknownRoute,
        navigatorObservers:       [...existingObservers, _routeObserver],
        builder:                  materialApp.builder,
        title:                    materialApp.title,
        onGenerateTitle:          materialApp.onGenerateTitle,
        color:                    materialApp.color,
        theme:                    materialApp.theme,
        darkTheme:                materialApp.darkTheme,
        highContrastTheme:        materialApp.highContrastTheme,
        highContrastDarkTheme:    materialApp.highContrastDarkTheme,
        themeMode:                materialApp.themeMode,
        themeAnimationDuration:   materialApp.themeAnimationDuration,
        themeAnimationCurve:      materialApp.themeAnimationCurve,
        locale:                   materialApp.locale,
        localizationsDelegates:   materialApp.localizationsDelegates,
        localeListResolutionCallback: materialApp.localeListResolutionCallback,
        localeResolutionCallback:     materialApp.localeResolutionCallback,
        supportedLocales:         materialApp.supportedLocales,
        showPerformanceOverlay:   materialApp.showPerformanceOverlay,
        checkerboardRasterCacheImages:  materialApp.checkerboardRasterCacheImages,
        checkerboardOffscreenLayers:    materialApp.checkerboardOffscreenLayers,
        showSemanticsDebugger:    materialApp.showSemanticsDebugger,
        debugShowCheckedModeBanner: materialApp.debugShowCheckedModeBanner,
        shortcuts:                materialApp.shortcuts,
        actions:                  materialApp.actions,
        restorationScopeId:       materialApp.restorationScopeId,
        scrollBehavior:           materialApp.scrollBehavior,
      );
    }
    return widget.child;
  }
}
