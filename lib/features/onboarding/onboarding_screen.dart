import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../core/providers/profile_provider.dart';
import '../../core/services/database_service.dart';
import '../home/home_route_args.dart';
import 'onboarding_route_args.dart';
import 'widgets/choose_mode_step.dart';
import 'widgets/permissions_step.dart';
import 'widgets/profile_photo_step.dart';
import 'widgets/nickname_birthday_step.dart';
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
  bool _didRestoreProgress = false;

  // State carried across steps
  String _selectedMode = 'google'; // 'google' or 'offline'
  String _userName = 'User';
  String? _profilePhotoPath;
  String _nickname = '';
  String _dateOfBirth = '';
  String _homeRegion = '';
  String _homeCity = '';
  String _homeBarangay = '';
  String _homeCountry = 'Philippines';
  String _preferredCurrency = 'PHP';
  List<String> _healthNotes = [];
  String? _bloodType;


  /// Steps in onboarding (page index → name)
  /// 0: ChooseMode, 1: Permissions, 2: ProfilePhoto,
  /// 3: NicknameBirthday, 4: Preferences, 5: HealthSafety, 6: AllSet
  static const int _kTotalSteps = 7;

  void _goToStep(int step) {
    if (step >= _kTotalSteps) return;
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

    // Set cloud/Google flags and seed profile photo from Google metadata
    final isCloud  = mode == 'google' || mode == 'email';
    final isGoogle = mode == 'google';
    final googlePhotoUrl = supaUser?.userMetadata?['avatar_url'] as String? ??
        supaUser?.userMetadata?['picture'] as String?;

    notifier.updateProfile(ref.read(profileProvider).copyWith(
      isGoogleConnected: isGoogle,
      isCloudConnected: isCloud,
      accountEmail: isCloud ? (supaUser?.email) : null,
      profilePhotoUrl: googlePhotoUrl ?? ref.read(profileProvider).profilePhotoUrl,
    ));

    // For cloud modes: if the user has already completed onboarding
    // (returning sign-in), skip straight to home.
    if (isCloud) {
      if (supaUser != null) {
        await DatabaseService.instance.switchUser(supaUser.id);
      }
      await ref.read(profileProvider.notifier).refreshProfile();
      if (!mounted) return;
      final current = ref.read(profileProvider);
      if (current.hasCompletedOnboarding) {
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      }

      // Resume from where they left off based on saved profile data.
      // Only jump ahead if the user actually progressed past step 1 in a
      // previous session — a brand-new user should always see step 1.
      if (!_isTrulyNewUser(current)) {
        final resumeStep = _computeResumeStep(current);
        // Pre-fill local state from saved profile
        setState(() {
          _profilePhotoPath = current.profilePhotoUrl;
          _nickname = current.nickname ?? '';
          _dateOfBirth = current.dateOfBirth ?? '';
          _homeRegion = current.homeRegion;
          _homeCity = current.homeCity;
          _homeBarangay = current.homeBarangay;
          _homeCountry = current.homeCountry.isNotEmpty ? current.homeCountry : 'Philippines';
          _preferredCurrency = current.preferredCurrency.isNotEmpty ? current.preferredCurrency : 'PHP';
          _healthNotes = current.healthNotes;
          _bloodType = current.bloodType;
        });
        _goToStep(resumeStep);
        return;
      }
    }

    _goToStep(1);
  }

  /// Returns true when the profile has no user-entered data yet.
  /// A new Google user has auto-seeded name + avatar but hasn't touched
  /// any onboarding step beyond step 0 (ChooseMode).
  bool _isTrulyNewUser(ProfileState profile) {
    final noNickname  = (profile.nickname ?? '').isEmpty;
    final noCity      = profile.homeCity.isEmpty;
    final noHealth    = profile.healthNotes.isEmpty;
    return noNickname && noCity && noHealth;
  }

  /// Returns the step index to resume from based on what has been saved.
  /// Only call this when [_isTrulyNewUser] returns false.
  int _computeResumeStep(ProfileState profile) {
    // Step 2: Photo — if photo is set, they passed photo step
    if (profile.profilePhotoUrl == null || profile.profilePhotoUrl!.isEmpty) {
      return 2; // Resume at Profile Photo step
    }
    // Step 3: Nickname/Birthday — if nickname is empty, resume here
    if ((profile.nickname ?? '').isEmpty) {
      return 3; // Resume at Nickname & Birthday step
    }
    // Step 4: Preferences — if city is empty, resume here
    if (profile.homeCity.isEmpty) {
      return 4; // Resume at Preferences step
    }
    // Step 5: Health & Safety — if health notes were never saved, resume here
    if (profile.healthNotes.isEmpty) {
      return 5; // Resume at Health & Safety step
    }
    // Step 6: All Set
    return 6;
  }

  void _onPermissionsNext() => _goToStep(2);
  void _onPermissionsSkip() => _goToStep(2);

  void _onPhotoSelected(String? path) {
    setState(() => _profilePhotoPath = path);
    ref.read(profileProvider.notifier).updatePhoto(path);
  }

  void _onNicknameBirthdayNext(String nickname, String dob) {
    setState(() {
      _nickname = nickname;
      _dateOfBirth = dob;
    });
    ref.read(profileProvider.notifier).updateNickname(nickname);
    ref.read(profileProvider.notifier).updateDateOfBirth(dob);
    _goToStep(4);
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
    final notifier = ref.read(profileProvider.notifier);
    final currentState = ref.read(profileProvider);
    notifier.updateProfile(currentState.copyWith(healthNotes: notes));
  }

  void _onBloodTypeSelected(String? type) {
    setState(() => _bloodType = type);
    ref.read(profileProvider.notifier).updateBloodType(type);
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

    // If user is already authenticated when landing on onboarding
    // (e.g. app reopened mid-onboarding), restore partial progress.
    if (!_didRestoreProgress) {
      _didRestoreProgress = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final profile = ref.read(profileProvider);
        final supaUser = supa.Supabase.instance.client.auth.currentUser;
        if (supaUser != null && !profile.hasCompletedOnboarding && profile.isLoaded) {
          // Only restore progress if the user genuinely started onboarding
          // in a prior session. A brand-new user should stay on step 0.
          if (!_isTrulyNewUser(profile)) {
            final resumeStep = _computeResumeStep(profile);
            setState(() {
              _selectedMode = 'google';
              _userName = profile.displayName;
              _profilePhotoPath = profile.profilePhotoUrl;
              _nickname = profile.nickname ?? '';
              _dateOfBirth = profile.dateOfBirth ?? '';
              _homeRegion = profile.homeRegion;
              _homeCity = profile.homeCity;
              _homeBarangay = profile.homeBarangay;
              _homeCountry = profile.homeCountry.isNotEmpty ? profile.homeCountry : 'Philippines';
              _preferredCurrency = profile.preferredCurrency.isNotEmpty ? profile.preferredCurrency : 'PHP';
              _healthNotes = profile.healthNotes;
              _bloodType = profile.bloodType;
            });
            _goToStep(resumeStep);
          }
        }
      });
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
    final displayUserName = profile.effectiveName == 'User' ? _userName : profile.effectiveName;

    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Step 0 — Choose mode
        ChooseModeStep(
          onModeSelected: _onChooseModeSelected,
          autoGoogleSignIn: _autoGoogleSignIn,
        ),

        // Step 1 — Permissions
        PermissionsStep(
          onNext: _onPermissionsNext,
          onSkip: _onPermissionsSkip,
        ),

        // Step 2 — Profile Photo
        ProfilePhotoStep(
          initialPhotoPath: _profilePhotoPath,
          onPhotoSelected: _onPhotoSelected,
          onNext: () => _goToStep(3),
          onSkip: () => _goToStep(3),
        ),

        // Step 3 — Nickname & Birthday (NEW)
        NicknameBirthdayStep(
          initialNickname: _nickname,
          initialDateOfBirth: _dateOfBirth,
          userName: displayUserName,
          onNext: _onNicknameBirthdayNext,
          onSkip: () => _goToStep(4),
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
          onNext: () => _goToStep(5),
        ),

        // Step 5 — Health & Safety
        HealthSafetyStep(
          initialHealthNotes: _healthNotes,
          initialBloodType: _bloodType,
          onNotesChanged: _onHealthNotesChanged,
          onBloodTypeSelected: _onBloodTypeSelected,
          onNext: () => _goToStep(6),
          onSkip: () => _goToStep(6),
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
