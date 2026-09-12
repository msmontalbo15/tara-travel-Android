import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../core/providers/profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_route_args.dart';
import 'onboarding_route_args.dart';
import 'widgets/choose_mode_step.dart';
import 'widgets/permissions_step.dart';
import 'widgets/personal_profile_step.dart';
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
  int _currentStepIndex = 0;

  // State carried across steps
  String _userName = '';
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
  /// 0: ChooseMode (Google Auth + Terms)
  /// 1: Permissions (Step 1 of 5)
  /// 2: PersonalProfile (Step 2 of 5: Photo + Nickname + DOB)
  /// 3: Preferences (Step 3 of 5: Location & Currency)
  /// 4: HealthSafety (Step 4 of 5: Blood Type & Health Notes)
  /// 5: AllSet (Step 5 of 5: Summary & Final Confirmation)
  static const int _kTotalPages = 6;

  void _goToStep(int step, {bool animate = true}) {
    if (step >= _kTotalPages) return;
    setState(() => _currentStepIndex = step);
    if (animate && _pageController.hasClients) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else if (_pageController.hasClients) {
      _pageController.jumpToPage(step);
    }
  }

  void _goBack() {
    if (_currentStepIndex > 1) {
      _goToStep(_currentStepIndex - 1);
    }
  }

  void _onChooseModeSelected(String mode, String? name) async {
    setState(() {
      if (name != null && name.isNotEmpty) _userName = name;
    });

    final notifier = ref.read(profileProvider.notifier);
    final supaUser = supa.Supabase.instance.client.auth.currentUser;

    // Update name immediately so it's visible in subsequent steps
    notifier.updateDisplayName(_userName);

    // All sign-in modes are cloud-connected (Google only)
    final googlePhotoUrl = supaUser?.userMetadata?['avatar_url'] as String? ??
        supaUser?.userMetadata?['picture'] as String?;

    notifier.updateProfile(ref.read(profileProvider).copyWith(
      isGoogleConnected: true,
      isCloudConnected: true,
      accountEmail: supaUser?.email,
      profilePhotoUrl:
          googlePhotoUrl ?? ref.read(profileProvider).profilePhotoUrl,
    ));

    await ref.read(profileProvider.notifier).refreshProfile();
    if (!mounted) return;

    final current = ref.read(profileProvider);
    // Returning user who already finished onboarding → skip straight to home
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

    _goToStep(1);
  }

  /// Returns true when the profile has no user-entered data yet.
  /// A new Google user has auto-seeded name + avatar but hasn't touched
  /// any onboarding step beyond step 0 (ChooseMode).
  bool _isTrulyNewUser(ProfileState profile) {
    final noNickname = (profile.nickname ?? '').isEmpty;
    final noCity = profile.homeCity.isEmpty;
    final noHealth = profile.healthNotes.isEmpty;
    return noNickname && noCity && noHealth;
  }

  /// Returns the step index to resume from based on what has been saved.
  /// Only call this when [_isTrulyNewUser] returns false.
  int _computeResumeStep(ProfileState profile) {
    // Step 2: Personal Profile — if nickname is empty and local photo unset, resume here
    if ((profile.nickname ?? '').isEmpty) {
      return 2; // Resume at Your Profile step
    }
    // Step 3: Preferences — if city is empty, resume here
    if (profile.homeCity.isEmpty) {
      return 3; // Resume at Preferences step
    }
    // Step 4: Health & Safety — if health notes were never saved, resume here
    if (profile.healthNotes.isEmpty) {
      return 4; // Resume at Health & Safety step
    }
    // Step 5: All Set
    return 5;
  }

  void _onPermissionsNext() => _goToStep(2);
  void _onPermissionsSkip() => _goToStep(2);

  void _onPersonalProfileNext(String? photoPath, String nickname, String dob) {
    setState(() {
      _profilePhotoPath = photoPath;
      _nickname = nickname;
      _dateOfBirth = dob;
    });
    if (photoPath != null) {
      ref.read(profileProvider.notifier).updatePhoto(photoPath);
    }
    ref.read(profileProvider.notifier).updateNickname(nickname);
    ref.read(profileProvider.notifier).updateDateOfBirth(dob);
    _goToStep(3);
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
    // (e.g. finishing setup post-login), skip step 0 (Google sign-in) and proceed.
    if (!_didRestoreProgress) {
      _didRestoreProgress = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final profile = ref.read(profileProvider);
        final supaUser = supa.Supabase.instance.client.auth.currentUser;

        // If user already has an established account/profile, skip onboarding entirely
        if (supaUser != null && profile.isAccountFullySet) {
          Navigator.of(context).pushReplacementNamed('/home');
          return;
        }

        if (supaUser != null &&
            !profile.hasCompletedOnboarding &&
            profile.isLoaded) {
          final startStep =
              _isTrulyNewUser(profile) ? 1 : _computeResumeStep(profile);
          setState(() {
            _userName = profile.displayName;
            _profilePhotoPath = profile.profilePhotoUrl;
            _nickname = profile.nickname ?? '';
            _dateOfBirth = profile.dateOfBirth ?? '';
            _homeRegion = profile.homeRegion;
            _homeCity = profile.homeCity;
            _homeBarangay = profile.homeBarangay;
            _homeCountry = profile.homeCountry.isNotEmpty
                ? profile.homeCountry
                : 'Philippines';
            _preferredCurrency = profile.preferredCurrency.isNotEmpty
                ? profile.preferredCurrency
                : 'PHP';
            _healthNotes = profile.healthNotes;
            _bloodType = profile.bloodType;
          });
          _goToStep(startStep, animate: false);
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
    final displayUserName =
        profile.effectiveName.isNotEmpty ? profile.effectiveName : _userName;

    return Scaffold(
      backgroundColor: _currentStepIndex == 5
          ? AppColors.deepEarth
          : AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Step Progress Bar (Only visible during Steps 1 to 5)
            if (_currentStepIndex >= 1 && _currentStepIndex <= 5)
              _buildTopStepProgressHeader(),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 0 — Choose mode (Google sign-in & Terms)
                  ChooseModeStep(
                    onModeSelected: _onChooseModeSelected,
                    autoGoogleSignIn: _autoGoogleSignIn,
                  ),

                  // Step 1 — Permissions
                  PermissionsStep(
                    onNext: _onPermissionsNext,
                    onSkip: _onPermissionsSkip,
                  ),

                  // Step 2 — Personal Profile (Photo + Nickname + Birthday)
                  PersonalProfileStep(
                    initialPhotoPath: _profilePhotoPath,
                    initialNickname: _nickname,
                    initialDateOfBirth: _dateOfBirth,
                    userName: displayUserName,
                    onNext: _onPersonalProfileNext,
                    onSkip: () => _goToStep(3),
                  ),

                  // Step 3 — Preferences (City, Region, Barangay)
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

                  // Step 4 — Health & Safety
                  HealthSafetyStep(
                    initialHealthNotes: _healthNotes,
                    initialBloodType: _bloodType,
                    onNotesChanged: _onHealthNotesChanged,
                    onBloodTypeSelected: _onBloodTypeSelected,
                    onNext: () => _goToStep(5),
                    onSkip: () => _goToStep(5),
                  ),

                  // Step 5 — All Set
                  AllSetStep(
                    userName: displayUserName,
                    accountEmail: profile.accountEmail ?? '',
                    homeCity: _homeBarangay.isNotEmpty
                        ? '$_homeBarangay, $_homeCity'
                        : _homeCity,
                    homeCountry:
                        _homeCountry.isNotEmpty ? _homeCountry : 'Philippines',
                    currency:
                        _preferredCurrency.isNotEmpty ? _preferredCurrency : 'PHP',
                    onLetsGo: _onLetsGo,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStepProgressHeader() {
    final isDarkStep = _currentStepIndex == 5;
    const totalSteps = 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDarkStep ? AppColors.deepEarth : AppColors.surfaceLight,
      child: Row(
        children: [
          // Back button (visible when step > 1)
          if (_currentStepIndex > 1)
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: isDarkStep ? Colors.white70 : AppColors.textPrimary,
              ),
              onPressed: _goBack,
              tooltip: 'Previous step',
            )
          else
            const SizedBox(width: 48),

          // 5-Segment Animated Progress Bar
          Expanded(
            child: Row(
              children: List.generate(totalSteps, (index) {
                final stepNum = index + 1;
                final isPassed = stepNum < _currentStepIndex;
                final isCurrent = stepNum == _currentStepIndex;

                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: isPassed || isCurrent
                          ? AppColors.primary
                          : (isDarkStep
                              ? Colors.white.withValues(alpha: 0.15)
                              : AppColors.sand),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
