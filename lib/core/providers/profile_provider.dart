import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';
import 'repository_providers.dart';

// ── Profile State ─────────────────────────────────────────────────────────────

class ProfileState {
  final String displayName;
  final String firstName;
  final String homeRegion;
  final String homeCity;
  final String homeBarangay;
  final String homeCountry;
  final String preferredCurrency;
  final String? nickname;
  final String? dateOfBirth;
  final String? profilePhotoUrl;
  final String? contactNumber;
  final String? gcashNumber;
  final String? gcashQrUrl;
  final List<String> healthNotes;
  final String? bloodType;
  final bool shareHealthWithOrganizer;
  final Map<String, bool> notificationPrefs;
  final bool isCloudConnected;
  final String? accountEmail;
  final bool hasCompletedOnboarding;
  final bool hideSurname;
  final bool isLoaded;
  final bool isFirstRun;

  const ProfileState({
    this.displayName = '',
    this.firstName = '',
    this.homeRegion = '',
    this.homeCity = '',
    this.homeBarangay = '',
    this.homeCountry = 'Philippines',
    this.preferredCurrency = 'PHP',
    this.nickname,
    this.dateOfBirth,
    this.profilePhotoUrl,
    this.contactNumber,
    this.gcashNumber,
    this.gcashQrUrl,
    this.healthNotes = const [],
    this.bloodType,
    this.shareHealthWithOrganizer = false,
    this.notificationPrefs = const {
      'expenses': true,
      'payments': true,
      'itinerary': true,
      'group_location': true,
      'weather': true,
      'reminders': true,
      'system': true,
    },
    this.isCloudConnected = false,
    this.accountEmail,
    this.hasCompletedOnboarding = false,
    this.hideSurname = false,
    this.isLoaded = false,
    this.isFirstRun = true,
  });

  /// Backwards-compatible alias used across the UI.
  bool get isGoogleConnected => isCloudConnected;

  /// Returns the preferred display name: nickname if available, else displayName/firstName.
  String get effectiveName {
    if (nickname != null && nickname!.trim().isNotEmpty) {
      return nickname!.trim();
    }
    if (displayName.isNotEmpty && displayName != 'User') return displayName;
    if (firstName.isNotEmpty && firstName != 'User') return firstName;
    return '';
  }

  /// Returns the display name formatted for peers/other members based on surname privacy.
  String get effectiveNameForPeers {
    final base = effectiveName;
    if (!hideSurname || base.isEmpty) return base;
    final parts = base.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return base;
    final first = parts.first;
    final lastInitial = parts.last[0].toUpperCase();
    return '$first $lastInitial.';
  }

  /// Returns the nickname for homepage display (falls back to effectiveName if nickname is not set).
  String get displayNameForHome {
    if (nickname != null && nickname!.trim().isNotEmpty) {
      return nickname!.trim();
    }
    return effectiveName;
  }

  String get initials {
    final nameToUse = effectiveName.trim();
    if (nameToUse.isEmpty) return '';
    final parts = nameToUse.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nameToUse.isNotEmpty ? nameToUse[0].toUpperCase() : '';
  }

  /// Evaluates whether the account is sufficiently initialized to bypass onboarding.
  bool get isAccountFullySet =>
      hasCompletedOnboarding ||
      homeCity.isNotEmpty ||
      (displayName.isNotEmpty && displayName != 'User') ||
      (firstName.isNotEmpty && firstName != 'User');

  Color get avatarColor => const Color(0xFFD85A30);

  ProfileState copyWith({
    String? displayName,
    String? firstName,
    String? homeRegion,
    String? homeCity,
    String? homeBarangay,
    String? homeCountry,
    String? preferredCurrency,
    String? nickname,
    String? dateOfBirth,
    String? profilePhotoUrl,
    String? contactNumber,
    String? gcashNumber,
    String? gcashQrUrl,
    List<String>? healthNotes,
    String? bloodType,
    bool? shareHealthWithOrganizer,
    Map<String, bool>? notificationPrefs,
    bool? isCloudConnected,
    bool? isGoogleConnected,
    String? accountEmail,
    bool? hasCompletedOnboarding,
    bool? hideSurname,
    bool? isLoaded,
    bool? isFirstRun,
  }) {
    return ProfileState(
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      homeRegion: homeRegion ?? this.homeRegion,
      homeCity: homeCity ?? this.homeCity,
      homeBarangay: homeBarangay ?? this.homeBarangay,
      homeCountry: homeCountry ?? this.homeCountry,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      nickname: nickname ?? this.nickname,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      contactNumber: contactNumber ?? this.contactNumber,
      gcashNumber: gcashNumber ?? this.gcashNumber,
      gcashQrUrl: gcashQrUrl ?? this.gcashQrUrl,
      healthNotes: healthNotes ?? this.healthNotes,
      bloodType: bloodType ?? this.bloodType,
      shareHealthWithOrganizer:
          shareHealthWithOrganizer ?? this.shareHealthWithOrganizer,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      isCloudConnected:
          isGoogleConnected ?? isCloudConnected ?? this.isCloudConnected,
      accountEmail: accountEmail ?? this.accountEmail,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hideSurname: hideSurname ?? this.hideSurname,
      isLoaded: isLoaded ?? this.isLoaded,
      isFirstRun: isFirstRun ?? this.isFirstRun,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'firstName': firstName,
      'homeRegion': homeRegion,
      'homeCity': homeCity,
      'homeBarangay': homeBarangay,
      'homeCountry': homeCountry,
      'preferredCurrency': preferredCurrency,
      'nickname': nickname,
      'dateOfBirth': dateOfBirth,
      'profilePhotoUrl': profilePhotoUrl,
      'contactNumber': contactNumber,
      'gcashNumber': gcashNumber,
      'gcashQrUrl': gcashQrUrl,
      'healthNotes': healthNotes,
      'bloodType': bloodType,
      'shareHealthWithOrganizer': shareHealthWithOrganizer,
      'notificationPrefs': notificationPrefs,
      'isCloudConnected': isCloudConnected,
      'accountEmail': accountEmail,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'hideSurname': hideSurname,
      'isFirstRun': isFirstRun,
    };
  }

  factory ProfileState.fromJson(Map<String, dynamic> json) {
    return ProfileState(
      displayName: json['displayName'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      homeRegion: json['homeRegion'] as String? ?? '',
      homeCity: json['homeCity'] as String? ?? '',
      homeBarangay: json['homeBarangay'] as String? ?? '',
      homeCountry: json['homeCountry'] as String? ?? 'Philippines',
      preferredCurrency: json['preferredCurrency'] as String? ?? 'PHP',
      nickname: json['nickname'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      contactNumber: json['contactNumber'] as String?,
      gcashNumber: json['gcashNumber'] as String?,
      gcashQrUrl: json['gcashQrUrl'] as String?,
      healthNotes: (json['healthNotes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      bloodType: json['bloodType'] as String?,
      shareHealthWithOrganizer:
          json['shareHealthWithOrganizer'] as bool? ?? false,
      notificationPrefs: json['notificationPrefs'] != null
          ? Map<String, bool>.from(json['notificationPrefs'] as Map)
          : const {
              'expenses': true,
              'payments': true,
              'itinerary': true,
              'group_location': true,
              'weather': true,
              'reminders': true,
              'system': true,
            },
      isCloudConnected: json['isCloudConnected'] as bool? ?? false,
      accountEmail: json['accountEmail'] as String?,
      hasCompletedOnboarding:
          json['hasCompletedOnboarding'] as bool? ?? false,
      hideSurname: json['hideSurname'] as bool? ?? false,
      isLoaded: true,
      isFirstRun: json['isFirstRun'] as bool? ?? true,
    );
  }
}

// ── Profile Notifier ──────────────────────────────────────────────────────────

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    // Re-eval/load profile whenever the auth state changes
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (prev, next) {
      next.whenOrNull(data: (_) => _loadProfile());
    });
    // Initial load of profile
    _loadProfile();
    return const ProfileState();
  }

  // ── Loaders ────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    final repo = ref.read(profileRepositoryProvider);
    ProfileState current = const ProfileState();

    try {
      final supaUser = Supabase.instance.client.auth.currentUser;
      if (supaUser != null) {
        final remoteData = await repo.getRemoteProfile(supaUser.id);
        if (remoteData != null) {
          final remote = ProfileState.fromJson(remoteData);
          // If remote account has city or valid name, treat onboarding as completed
          final hasOnboarded = remote.hasCompletedOnboarding ||
              remote.homeCity.isNotEmpty ||
              ((remote.displayName.isNotEmpty) && remote.displayName != 'User');

          current = remote.copyWith(
            accountEmail: supaUser.email,
            isCloudConnected: true,
            hasCompletedOnboarding: hasOnboarded,
          );
        } else {
          // Seed initial name & photo from auth metadata if available
          final metadata = supaUser.userMetadata;
          final metaName = metadata?['full_name'] as String? ??
              metadata?['name'] as String?;
          final metaPhoto = metadata?['avatar_url'] as String? ??
              metadata?['picture'] as String?;
          final resolvedName = metaName ?? '';
          current = current.copyWith(
            displayName: resolvedName,
            firstName: resolvedName.isNotEmpty
                ? resolvedName.split(' ').first
                : '',
            profilePhotoUrl: metaPhoto,
            isCloudConnected: true,
            accountEmail: supaUser.email,
          );
        }
      }
    } catch (e) {
      debugPrint('[ProfileNotifier] Error loading profile: $e');
    } finally {
      state = current.copyWith(isLoaded: true);
    }
  }

  // ── Persistence ────────────────────────────────────────────────

  /// Forces a reload from remote (Supabase).
  Future<void> refreshProfile() => _loadProfile();

  Future<void> _persist() async {
    if (!state.hasCompletedOnboarding &&
        (state.homeCity.isNotEmpty || state.displayName.isNotEmpty)) {
      state = state.copyWith(hasCompletedOnboarding: true);
    }

    final repo = ref.read(profileRepositoryProvider);
    final json = state.toJson();

    final supaUser = Supabase.instance.client.auth.currentUser;
    if (supaUser != null) {
      await repo.saveRemoteProfile(supaUser.id, json);
    }
  }

  // ── Public Mutation Methods ────────────────────────────────────

  void completeOnboarding() {
    state = state.copyWith(hasCompletedOnboarding: true);
    _persist();
  }

  void setFirstRunCompleted() {
    state = state.copyWith(isFirstRun: false);
  }

  void updateDisplayName(String name) {
    final parts = name.trim().split(' ');
    state = state.copyWith(
      displayName: name.trim(),
      firstName: parts.isNotEmpty ? parts[0] : name,
    );
    _persist();
  }

  void updateLocation(String city, String country) {
    state = state.copyWith(homeCity: city, homeCountry: country);
    _persist();
  }

  void updatePhLocation({
    required String region,
    required String city,
    required String barangay,
  }) {
    state = state.copyWith(
      homeRegion: region,
      homeCity: city,
      homeBarangay: barangay,
      homeCountry: 'Philippines',
    );
    _persist();
  }

  void updateCurrency(String currency) {
    state = state.copyWith(preferredCurrency: currency);
    _persist();
  }

  void updatePhoto(String? url) {
    state = state.copyWith(profilePhotoUrl: url);
    _persist();
  }

  void updateContactNumber(String number) {
    state = state.copyWith(contactNumber: number);
    _persist();
  }

  void updateNickname(String nickname) {
    state = state.copyWith(nickname: nickname.trim());
    _persist();
  }

  void updateDateOfBirth(String dob) {
    state = state.copyWith(dateOfBirth: dob);
    _persist();
  }

  void updateProfile(ProfileState newState) {
    state = newState;
    _persist();
  }

  void updateBloodType(String? type) {
    state = state.copyWith(bloodType: type);
    _persist();
  }

  void addHealthNote(String note) {
    if (note.trim().isEmpty) return;
    state = state.copyWith(
      healthNotes: [...state.healthNotes, note.trim()],
    );
    _persist();
  }

  void removeHealthNote(String note) {
    state = state.copyWith(
      healthNotes: state.healthNotes.where((n) => n != note).toList(),
    );
    _persist();
  }

  void toggleShareHealth(bool val) {
    state = state.copyWith(shareHealthWithOrganizer: val);
    _persist();
  }

  void toggleNotif(String key, bool val) {
    final prefs = Map<String, bool>.from(state.notificationPrefs);
    prefs[key] = val;
    state = state.copyWith(notificationPrefs: prefs);
    _persist();
  }

  void toggleHideSurname(bool val) {
    state = state.copyWith(hideSurname: val);
    _persist();
  }

  void updateGCash(String number, String? qrUrl) {
    state = state.copyWith(gcashNumber: number, gcashQrUrl: qrUrl);
    _persist();
  }

  /// Signs the user out from Supabase and resets in-memory profile state.
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('[ProfileProvider] signOut error: $e');
    }

    state = const ProfileState(isLoaded: true);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final profileProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
