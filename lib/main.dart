import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_responsive.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/create_trip/create_trip_flow.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/budget/budget_screen.dart';
import 'features/itinerary/itinerary_screen.dart';
import 'features/navigation/live_navigation_screen.dart';
import 'features/packing/packing_screen.dart';
import 'features/members/members_screen.dart';
import 'features/explore/explore_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/trip_detail/trip_detail_screen.dart';
import 'features/activity/activity_log_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/trips/trips_screen.dart';
import 'features/friends/friends_screen.dart';

import 'core/widgets/auth_gate.dart';
import 'core/auth/data/secure_session_repository.dart';
import 'core/security/three_layer_encryption_service.dart';
import 'core/services/notification_router.dart';
import 'core/widgets/notifications/in_app_notification_overlay.dart';
import 'features/navigation/widgets/in_app_floating_bubble.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // ── 0. Full-screen edge-to-edge ──────────────────────────────────────────
  // Render content behind status bar and system navigation bar.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // ── 1. Load environment variables ────────────────────────────────────────
  // All secrets (Supabase keys, Google client IDs) are loaded from .env at
  // runtime — zero hardcoded credentials in source code.
  await dotenv.load(fileName: '.env');

  // ── 2. Initialise Supabase ───────────────────────────────────────────────
  await Supabase.initialize(
    url:     dotenv.env['EXPO_PUBLIC_SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['EXPO_PUBLIC_SUPABASE_ANON_KEY'] ?? '',
  );

  // ── 3. Restore encrypted session (cold-start optimisation) ───────────────
  // Attempts to rehydrate a persisted Supabase session from the
  // Keystore-backed EncryptedSharedPreferences store before runApp().
  // On success, the user is silently signed in — no login screen shown.
  // On expired or missing session → falls through to unauthenticated state.
  // On Keystore key loss (device wipe / OS upgrade) → graceful clear.
  await SecureSessionRepository.instance.restoreSession();

  // ── 4. Initialise 3-Layer Encryption (generate/load RSA + AES-256 keys) ────────
  // Keys are persisted in platform Keystore/Keychain via flutter_secure_storage.
  // Subsequent calls are instant (keys are cached in memory after first load).
  await ThreeLayerEncryptionService.instance.init();


  runApp(
    const ProviderScope(
      overrides: [],
      child: TaraApp(),
    ),
  );
}

class TaraApp extends StatelessWidget {
  const TaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthGate(
      child: MaterialApp(
        navigatorKey: NotificationRouter.instance.navigatorKey,
        navigatorObservers: [
          _AppRouteObserver(),
        ],
        title: 'Tara Travel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) {
          final scaledChild = AppResponsive.clampedTextScaleBuilder(context, child);
          return InAppNotificationOverlay(
            child: InAppFloatingBubbleContainer(
              child: scaledChild,
            ),
          );
        },
        initialRoute: '/',
        routes: {
          '/':             (context) => SplashScreen(
                onGetStarted: () =>
                    Navigator.pushReplacementNamed(context, '/onboarding'),
              ),
          '/onboarding':   (_) => const OnboardingScreen(),
          '/home':         (_) => const HomeScreen(),
          '/create-trip':  (_) => const CreateTripFlow(),
          '/notifications':(_) => const NotificationsScreen(),
          '/budget':       (_) => const BudgetScreen(),
          '/itinerary':    (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            if (args is Map<String, dynamic>) {
              return ItineraryScreen(
                targetStopId: args['targetStopId'] as String?,
                targetDayNumber: args['targetDayNumber'] as int?,
              );
            }
            return const ItineraryScreen();
          },
          '/navigation':   (_) => const LiveNavigationScreen(),
          '/packing':      (_) => const PackingScreen(),
          '/members':      (_) => const MembersScreen(),
          '/explore':      (_) => const ExploreScreen(),
          '/profile':      (_) => const ProfileScreen(),
          '/trip-detail':  (_) => const TripDetailScreen(),
          '/activity':     (_) => const ActivityLogScreen(),
          '/chat':         (_) => const ChatScreen(),
          '/trips':        (_) => const TripsScreen(),
          '/friends':      (_) => const FriendsScreen(),
        },
      ),
    );
  }
}

class _AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    NotificationRouter.instance.onRouteChange(route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    NotificationRouter.instance.onRouteChange(previousRoute?.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    NotificationRouter.instance.onRouteChange(newRoute?.settings.name);
  }
}
