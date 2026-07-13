import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../core/providers/profile_provider.dart';
import '../home/home_route_args.dart';
import 'onboarding_route_args.dart';
import 'widgets/choose_mode_step.dart';
import 'widgets/permissions_step.dart';
import 'widgets/profile_photo_step.dart';
import 'widgets/preferences_step.dart';
import 'widgets/health_safety_step.dart';
import 'widgets/all_set_step.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _didReadRouteArgs = false;
  bool _autoGoogleSignIn = false;

  // State carried across steps
  String _selectedMode = 'google'; // 'google' or 'offline'
  String _userName = 'User';
  String? _profilePhotoPath;
  String _homeRegion = '';
  String _homeCity = '';
  String _homeBarangay = '';
  String _homeCountry = 'Philippines';
  String _preferredCurrency = 'PHP';
  List<String> _healthNotes = [];

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _onChooseModeSelected(String mode, String? name) async {
    setState(() {
      _selectedMode = mode;
      if (name != null && name.isNotEmpty) _userName = name;
    });

    final notifier = ref.read(profileProvider.notifier);
    final supaUser = supa.Supabase.instance.client.auth.currentUser;

    // Update name immediately so it's visible in subsequent steps
    notifier.updateDisplayName(_userName);

    // Set cloud/Google flags based on chosen mode
    final isCloud  = mode == 'google' || mode == 'email';
    final isGoogle = mode == 'google';
    notifier.updateProfile(ref.read(profileProvider).copyWith(
      isGoogleConnected: isGoogle,
      isCloudConnected: isCloud,
      accountEmail: isCloud ? (supaUser?.email) : null,
    ));

    // For cloud modes: if the user has already completed onboarding
    // (returning sign-in), skip straight to home.
    if (isCloud) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      // Re-load profile from remote in case this is a returning user
      await ref.read(profileProvider.notifier).refreshProfile();
      if (!mounted) return;
      final current = ref.read(profileProvider);
      if (current.hasCompletedOnboarding) {
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      }
    }

    _goToStep(1);
  }

  void _onPermissionsNext() => _goToStep(2);
  void _onPermissionsSkip() => _goToStep(2);

  void _onPhotoSelected(String? path) {
    setState(() => _profilePhotoPath = path);
    ref.read(profileProvider.notifier).updatePhoto(path);
  }

  void _onPreferencesChanged(String city, String country, String currency) {
    setState(() {
      _homeCity = city;
      _homeCountry = country;
      _preferredCurrency = currency;
    });
    ref.read(profileProvider.notifier).updateLocation(city, country);
    ref.read(profileProvider.notifier).updateCurrency(currency);
  }

  void _onPhPreferencesChanged(
      String region, String city, String barangay, String currency) {
    setState(() {
      _homeRegion = region;
      _homeCity = city;
      _homeBarangay = barangay;
      _homeCountry = 'Philippines';
      _preferredCurrency = currency;
    });
    ref.read(profileProvider.notifier).updatePhLocation(
      region: region,
      city: city,
      barangay: barangay,
    );
    ref.read(profileProvider.notifier).updateCurrency(currency);
  }

  void _onHealthNotesChanged(List<String> notes) {
    setState(() => _healthNotes = notes);
    // Directly update state to avoid repetitive persistence if needed, but repository handles it
    final notifier = ref.read(profileProvider.notifier);
    final currentState = ref.read(profileProvider);
    notifier.updateProfile(currentState.copyWith(healthNotes: notes));
  }

  void _onLetsGo() {
    ref.read(profileProvider.notifier).completeOnboarding();
    Navigator.of(context).pushReplacementNamed(
      '/home',
      arguments: const HomeRouteArgs(startTour: true),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadRouteArgs) return;
    _didReadRouteArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is OnboardingRouteArgs) {
      _autoGoogleSignIn = args.autoGoogleSignIn;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final displayUserName = profile.displayName == 'User' ? _userName : profile.displayName;

    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Step 1 — Choose mode
        ChooseModeStep(
          onModeSelected: _onChooseModeSelected,
          autoGoogleSignIn: _autoGoogleSignIn,
        ),

        // Step 2 — Permissions
        PermissionsStep(
          onNext: _onPermissionsNext,
          onSkip: _onPermissionsSkip,
        ),

        // Step 3 — Profile Photo
        ProfilePhotoStep(
          initialPhotoPath: _profilePhotoPath,
          onPhotoSelected: _onPhotoSelected,
          onNext: () => _goToStep(3),
          onSkip: () => _goToStep(3),
        ),

        // Step 4 — Preferences (City, Region, Barangay)
        PreferencesStep(
          initialRegion: _homeRegion,
          initialCity: _homeCity,
          initialBarangay: _homeBarangay,
          initialCountry: _homeCountry,
          initialCurrency: _preferredCurrency,
          onPreferencesChanged: _onPreferencesChanged,
          onPhPreferencesChanged: _onPhPreferencesChanged,
          onNext: () => _goToStep(4),
        ),

        // Step 5 — Health & Safety
        HealthSafetyStep(
          initialHealthNotes: _healthNotes,
          onNotesChanged: _onHealthNotesChanged,
          onNext: () => _goToStep(5),
          onSkip: () => _goToStep(5),
        ),

        // Step 6 — All Set
        AllSetStep(
          userName: displayUserName,
          accountEmail: _selectedMode == 'google'
              ? (profile.accountEmail ?? '')
              : 'Not connected',
          isGoogleConnected: _selectedMode == 'google',
          homeCity: _homeBarangay.isNotEmpty
              ? '$_homeBarangay, $_homeCity'
              : _homeCity,
          homeCountry: _homeCountry.isNotEmpty ? _homeCountry : 'Philippines',
          currency: _preferredCurrency.isNotEmpty ? _preferredCurrency : 'PHP',
          onLetsGo: _onLetsGo,
        ),
      ],
    );
  }
}
