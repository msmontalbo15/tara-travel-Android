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
  final String? profilePhotoUrl;
  final String? contactNumber;
  final String? gcashNumber;
  final String? gcashQrUrl;
  final List<String> healthNotes;
  final bool shareHealthWithOrganizer;
  final Map<String, bool> notificationPrefs;
  final bool isCloudConnected;
  final String? accountEmail;
  final bool hasCompletedOnboarding;
  final bool isLoaded;
  final bool isFirstRun;

  const ProfileState({
    this.displayName = 'User',
    this.firstName = 'User',
    this.homeRegion = '',
    this.homeCity = '',
    this.homeBarangay = '',
    this.homeCountry = 'Philippines',
    this.preferredCurrency = 'PHP',
    this.profilePhotoUrl,
    this.contactNumber,
    this.gcashNumber,
    this.gcashQrUrl,
    this.healthNotes = const [],
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
    this.isLoaded = false,
    this.isFirstRun = true,
  });

  /// Backwards-compatible alias used across the UI.
  bool get isGoogleConnected => isCloudConnected;

  String get initials {
    if (displayName.isEmpty) return 'U';
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  }

  Color get avatarColor => const Color(0xFFD85A30);

  ProfileState copyWith({
    String? displayName,
    String? firstName,
    String? homeRegion,
    String? homeCity,
    String? homeBarangay,
    String? homeCountry,
    String? preferredCurrency,
    String? profilePhotoUrl,
    String? contactNumber,
    String? gcashNumber,
    String? gcashQrUrl,
    List<String>? healthNotes,
    bool? shareHealthWithOrganizer,
    Map<String, bool>? notificationPrefs,
    bool? isCloudConnected,
    bool? isGoogleConnected,
    String? accountEmail,
    bool? hasCompletedOnboarding,
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
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      contactNumber: contactNumber ?? this.contactNumber,
      gcashNumber: gcashNumber ?? this.gcashNumber,
      gcashQrUrl: gcashQrUrl ?? this.gcashQrUrl,
      healthNotes: healthNotes ?? this.healthNotes,
      shareHealthWithOrganizer:
          shareHealthWithOrganizer ?? this.shareHealthWithOrganizer,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      isCloudConnected:
          isGoogleConnected ?? isCloudConnected ?? this.isCloudConnected,
      accountEmail: accountEmail ?? this.accountEmail,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
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
      'profilePhotoUrl': profilePhotoUrl,
      'contactNumber': contactNumber,
      'gcashNumber': gcashNumber,
      'gcashQrUrl': gcashQrUrl,
      'healthNotes': healthNotes,
      'shareHealthWithOrganizer': shareHealthWithOrganizer,
      'notificationPrefs': notificationPrefs,
      'isCloudConnected': isCloudConnected,
      'accountEmail': accountEmail,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      // Note: isLoaded and isFirstRun are intentionally omitted from JSON
      // because they are transient client-only fields.
    };
  }

  factory ProfileState.fromJson(Map<String, dynamic> json) {
    return ProfileState(
      displayName: json['displayName'] as String? ?? 'User',
      firstName: json['firstName'] as String? ?? 'User',
      homeRegion: json['homeRegion'] as String? ?? '',
      homeCity: json['homeCity'] as String? ?? '',
      homeBarangay: json['homeBarangay'] as String? ?? '',
      homeCountry: json['homeCountry'] as String? ?? 'Philippines',
      preferredCurrency: json['preferredCurrency'] as String? ?? 'PHP',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      contactNumber: json['contactNumber'] as String?,
      gcashNumber: json['gcashNumber'] as String?,
      gcashQrUrl: json['gcashQrUrl'] as String?,
      healthNotes: (json['healthNotes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      shareHealthWithOrganizer:
          json['shareHealthWithOrganizer'] as bool? ?? false,
      notificationPrefs: (json['notificationPrefs'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as bool)) ??
          const {
            'expenses': true,
            'payments': true,
            'itinerary': true,
            'group_location': true,
            'weather': true,
            'reminders': true,
            'system': true,
          },
      isCloudConnected: json['isCloudConnected'] as bool? ?? json['isGoogleConnected'] as bool? ?? false,
      accountEmail: json['accountEmail'] as String?,
      hasCompletedOnboarding:
          json['hasCompletedOnboarding'] as bool? ?? false,
      isLoaded: true,
      isFirstRun: false,
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
      // 1. Load local data first for fast startup
      final localData = await repo.getProfile();
      current = localData != null
          ? ProfileState.fromJson(localData)
          : const ProfileState();

      // 2. Merge with remote if user is authenticated
      final supaUser =
          Supabase.instance.client.auth.currentUser;
      if (supaUser != null) {
        final remoteData = await repo.getRemoteProfile(supaUser.id);
        if (remoteData != null) {
          final remote = ProfileState.fromJson(remoteData);
          // Remote wins when it has completed onboarding or local is default.
          // But: if the remote name is blank/placeholder AND the local name was
          // explicitly set (e.g. typed during offline onboarding), keep local name.
          final remoteName = remote.displayName;
          final localName = current.displayName;
          final resolvedName = (remoteName.isNotEmpty && remoteName != 'User')
              ? remoteName
              : (localName.isNotEmpty && localName != 'User')
                  ? localName
                  : remoteName;

          if (remote.hasCompletedOnboarding || !current.hasCompletedOnboarding) {
            current = remote.copyWith(
              displayName: resolvedName,
              firstName: resolvedName.split(' ').first,
              isCloudConnected: true,
              accountEmail: supaUser.email,
            );
          }
        } else {
          // Authenticated but no remote profile yet — also try to seed name
          // from Google/OAuth metadata so it is already set on first load.
          final metadata = supaUser.userMetadata;
          final metaName = metadata?['full_name'] as String? ??
              metadata?['name'] as String?;
          final resolvedName = (metaName != null && metaName.isNotEmpty)
              ? metaName
              : current.displayName;
          current = current.copyWith(
            displayName: resolvedName,
            firstName: resolvedName.split(' ').first,
            isCloudConnected: true,
            accountEmail: supaUser.email,
          );
        }
      }
    } catch (e) {
      debugPrint('[ProfileNotifier] Error loading profile: $e');
      // On error, let it fall back to default or what was loaded locally
    } finally {
      state = current.copyWith(isLoaded: true);
    }
  }

  // ── Persistence ────────────────────────────────────────────────

  /// Forces a reload from remote (Supabase) + local storage.
  /// Useful after a fresh sign-in to detect already-completed onboarding.
  Future<void> refreshProfile() => _loadProfile();


  Future<void> _persist() async {
    final repo = ref.read(profileRepositoryProvider);
    final json = state.toJson();

    await repo.saveProfile(json);

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
    // isFirstRun is transient — no need to persist
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

  void updateProfile(ProfileState newState) {
    state = newState;
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

  void updateGCash(String number, String? qrUrl) {
    state = state.copyWith(gcashNumber: number, gcashQrUrl: qrUrl);
    _persist();
  }

  /// Signs the user out: clears remote auth, local DB, and resets state.
  Future<void> signOut() async {
    try {
      // 1. Sign out from Supabase
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('[ProfileProvider] signOut error: $e');
    }

    // 2. Clear local profile from Sembast
    final repo = ref.read(profileRepositoryProvider);
    await repo.clearProfile();

    // 3. Reset in-memory state to defaults
    state = const ProfileState(isLoaded: true);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final profileProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
