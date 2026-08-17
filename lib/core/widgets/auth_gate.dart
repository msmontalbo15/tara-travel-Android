/// auth_gate.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Route guard that observes [authNotifierProvider] (MVI [AuthState]) and
/// wires the Supabase auth stream for session lifecycle events.
///
/// Responsibilities:
/// • Auto-Login: On cold start, if a valid session exists (online OR offline),
///   the login screen is skipped and the user is taken directly to /home.
/// • Routing: swaps between /home, /onboarding, and / based on auth state.
/// • Session persistence: persists refreshed tokens via [SecureSessionRepository]
///   whenever Supabase fires a [tokenRefreshed] event.
/// • Database isolation: calls [DatabaseService.switchUser] on sign-in/out.
/// • Provider invalidation: clears in-memory caches on sign-out.
/// • Offline banner: wraps the app in [OfflineBanner] for global connectivity UI.
/// • SyncManager: starts background sync when connectivity is restored.
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
import '../offline/sync_manager.dart';
import '../providers/profile_provider.dart';

import '../services/database_service.dart';
import 'offline_banner.dart';

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

    // Start the background sync manager — listens to connectivity changes
    // and drains the OfflineSyncQueue when the device comes back online.
    syncManagerInstance.start();

    // Subscribe to raw Supabase auth stream for lifecycle events that the
    // MVI notifier does not need to expose as state transitions.
    Supabase.instance.client.auth.onAuthStateChange.listen(_onSupabaseAuthEvent);

    // ── Auto-Login: Skip login if session exists ────────────────────────────
    // Runs after first frame so the navigator is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Check in-memory Supabase user first (hydrated from main() before runApp)
      final inMemoryUser = Supabase.instance.client.auth.currentUser;
      if (inMemoryUser != null) {
        await _navigateAuthenticatedUser(inMemoryUser);
        return;
      }

      // Fallback: check if a stored session token exists (for offline cold-start)
      final hasStored = await SecureSessionRepository.instance.hasStoredSession();
      if (hasStored) {
        // Attempt full session restore online; if offline, still go home so
        // the user can access locally-cached trip data via the offline banner.
        await ref.read(authNotifierProvider.notifier).restoreSession();
        if (!mounted) return;
        final authState = ref.read(authNotifierProvider).value;
        if (authState is AuthAuthenticated) {
          await _navigateAuthenticatedUser(authState.user);
        }
        // If restoreSession failed but hasStored is true, the user stays on
        // the login screen to re-authenticate with Google.
      }
    });
  }

  // ── Navigation Helpers ─────────────────────────────────────────────────────

  Future<void> _navigateAuthenticatedUser(User user) async {
    await DatabaseService.instance.switchUser(user.id);
    await ref.read(profileProvider.notifier).refreshProfile();
    if (!mounted) return;

    final profile = ref.read(profileProvider);
    final destination =
        profile.hasCompletedOnboarding ? '/home' : '/onboarding';
    _navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(destination, (route) => false);
  }

  // ── Supabase Auth Stream Handler ───────────────────────────────────────────

  Future<void> _onSupabaseAuthEvent(supabase.AuthState supaState) async {
    final event = supaState.event;
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
      // Refresh profile from remote.
      await ref.read(profileProvider.notifier).refreshProfile();
      if (!mounted) return;

      // Only intercept signedIn events that fire outside of onboarding.
      // When the user is already on /onboarding (step 0 ChooseModeStep),
      // let onboarding's own AuthAuthenticated listener drive navigation
      // so the full multi-step setup flow is preserved.
      final currentRoute = _routeObserver.currentRoute;
      final onOnboarding =
          currentRoute == '/onboarding' || currentRoute == null;
      if (onOnboarding) return;

      // Returning user (outside onboarding) — route based on completion flag.
      final profile = ref.read(profileProvider);
      final destination =
          profile.hasCompletedOnboarding ? '/home' : '/onboarding';
      _navigatorKey.currentState
          ?.pushNamedAndRemoveUntil(destination, (route) => false);
      return;
    }

    if (event == AuthChangeEvent.signedOut) {
      // Flush audit log to encrypted storage before wiping session.
      await AuditLogger.instance.flush();

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
        // Wrap the navigator's output in OfflineBanner so it appears globally
        // across all routes without needing to modify individual screens.
        builder: (context, child) {
          final appChild = materialApp.builder?.call(context, child) ?? child;
          return OfflineBanner(child: appChild ?? const SizedBox.shrink());
        },
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
