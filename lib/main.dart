import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/create_trip/create_trip_flow.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/budget/budget_screen.dart';
import 'features/itinerary/itinerary_screen.dart';
import 'features/navigation/navigation_screen.dart';
import 'features/packing/packing_screen.dart';
import 'features/members/members_screen.dart';
import 'features/explore/explore_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/trip_detail/trip_detail_screen.dart';
import 'features/activity/activity_log_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/trips/trips_screen.dart';

import 'core/widgets/auth_gate.dart';
import 'core/auth/data/secure_session_repository.dart';
import 'core/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  final restoredUser = await SecureSessionRepository.instance.restoreSession();

  // Pre-route the local database to the restored user's partition so the
  // first frame can read local data without an extra async hop.
  if (restoredUser != null) {
    await DatabaseService.instance.switchUser(restoredUser.id);
  }

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
        title: 'Tara Travel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
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
          '/itinerary':    (_) => const ItineraryScreen(),
          '/navigation':   (_) => const NavigationScreen(),
          '/packing':      (_) => const PackingScreen(),
          '/members':      (_) => const MembersScreen(),
          '/explore':      (_) => const ExploreScreen(),
          '/profile':      (_) => const ProfileScreen(),
          '/trip-detail':  (_) => const TripDetailScreen(),
          '/activity':     (_) => const ActivityLogScreen(),
          '/chat':         (_) => const ChatScreen(),
          '/trips':        (_) => const TripsScreen(),
        },
      ),
    );
  }
}
