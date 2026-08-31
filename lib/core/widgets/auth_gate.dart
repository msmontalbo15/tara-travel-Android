/// auth_gate.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Route guard that observes [authNotifierProvider] (MVI [AuthState]) and
/// wires the Supabase auth stream for session lifecycle events.
///
/// Responsibilities:
/// • Auto-Login: On cold start, if a valid session exists, the login screen
///   is skipped and the user is taken directly to /home (or /onboarding).
/// • Routing: swaps between /home, /onboarding, and / based on auth state.
/// • Session persistence: persists refreshed tokens via [SecureSessionRepository]
///   whenever Supabase fires a [tokenRefreshed] event.
/// • Provider invalidation: clears in-memory profile and stores on sign-out.
/// • Audit flush: flushes the [AuditLogger] buffer to encrypted storage on sign-out.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show AuthState;

import '../auth/data/secure_session_repository.dart';
import '../auth/presentation/auth_notifier.dart';
import '../middleware/audit_logger.dart';
import '../providers/profile_provider.dart';
import '../services/user_presence_service.dart';

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
    // MVI notifier does not need to expose as state transitions.
    Supabase.instance.client.auth.onAuthStateChange.listen(_onSupabaseAuthEvent);

    // ── Auto-Login: Skip login if session exists ────────────────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Check in-memory Supabase user first (hydrated from main() before runApp)
      final inMemoryUser = Supabase.instance.client.auth.currentUser;
      if (inMemoryUser != null) {
        UserPresenceService.instance.start(inMemoryUser.id);
        await _navigateAuthenticatedUser(inMemoryUser);
        return;
      }

      // Fallback: check if a stored session token exists (cold-start restore)
      final hasStored = await SecureSessionRepository.instance.hasStoredSession();
      if (hasStored) {
        await ref.read(authNotifierProvider.notifier).restoreSession();
        if (!mounted) return;
        final authState = ref.read(authNotifierProvider).value;
        if (authState is AuthAuthenticated) {
          UserPresenceService.instance.start(authState.user.id);
          await _navigateAuthenticatedUser(authState.user);
        }
      }
    });
  }

  // ── Navigation Helpers ─────────────────────────────────────────────────────

  Future<void> _navigateAuthenticatedUser(User user) async {
    UserPresenceService.instance.start(user.id);
    await ref.read(profileProvider.notifier).refreshProfile();
    if (!mounted) return;

    final profile = ref.read(profileProvider);
    final destination =
        profile.isAccountFullySet ? '/home' : '/onboarding';
    _navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(destination, (route) => false);
  }

  // ── Supabase Auth Stream Handler ───────────────────────────────────────────

  Future<void> _onSupabaseAuthEvent(supabase.AuthState supaState) async {
    final event = supaState.event;
    final session = supaState.session;

    if (event == AuthChangeEvent.tokenRefreshed && session != null) {
      await ref.read(authNotifierProvider.notifier).onTokenRefreshed(session);
      return;
    }

    if (event == AuthChangeEvent.signedIn && session != null) {
      UserPresenceService.instance.start(session.user.id);
      await ref.read(profileProvider.notifier).refreshProfile();
      if (!mounted) return;

      // Only intercept signedIn events that fire outside of onboarding.
      final currentRoute = _routeObserver.currentRoute;
      final onOnboarding =
          currentRoute == '/onboarding' || currentRoute == null;
      if (onOnboarding) return;

      final profile = ref.read(profileProvider);
      final destination =
          profile.isAccountFullySet ? '/home' : '/onboarding';
      _navigatorKey.currentState
          ?.pushNamedAndRemoveUntil(destination, (route) => false);
      return;
    }

    if (event == AuthChangeEvent.signedOut) {
      await UserPresenceService.instance.stop();
      await AuditLogger.instance.flush();

      // Invalidate in-memory profile provider cache
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
