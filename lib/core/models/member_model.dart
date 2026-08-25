import 'package:flutter/material.dart';

enum MemberStatus {
  pending,
  approved,
  rejected,
}

enum MemberRole {
  organizer,
  treasurer,
  navigator,
  buyer,
  documenter,
  member,
}

class MemberModel {
  final String id;
  final String name;
  final String initials;
  final Color color;
  final List<MemberRole> roles;
  final String? profilePhotoUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isLocationSharingPaused;
  final String? gcashNumber;
  final String? gcashQrUrl;
  final MemberStatus status;
  final bool hideSurname;

  const MemberModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    this.roles = const [MemberRole.member],
    this.profilePhotoUrl,
    this.isOnline = false,
    this.lastSeen,
    this.isLocationSharingPaused = false,
    this.gcashNumber,
    this.gcashQrUrl,
    this.status = MemberStatus.approved,
    this.hideSurname = false,
  });

  MemberModel copyWith({
    String? id,
    String? name,
    String? initials,
    Color? color,
    List<MemberRole>? roles,
    String? profilePhotoUrl,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isLocationSharingPaused,
    String? gcashNumber,
    String? gcashQrUrl,
    MemberStatus? status,
    bool? hideSurname,
  }) {
    return MemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      color: color ?? this.color,
      roles: roles ?? this.roles,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isLocationSharingPaused: isLocationSharingPaused ?? this.isLocationSharingPaused,
      gcashNumber: gcashNumber ?? this.gcashNumber,
      gcashQrUrl: gcashQrUrl ?? this.gcashQrUrl,
      status: status ?? this.status,
      hideSurname: hideSurname ?? this.hideSurname,
    );
  }

  /// Formats a user's display name according to their surname privacy preference.
  /// E.g. "Juan Dela Cruz" with hideSurname=true becomes "Juan D."
  static String formatDisplayName(String rawName, {bool hideSurname = false}) {
    final trimmed = rawName.trim();
    if (!hideSurname || trimmed.isEmpty) return trimmed;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length <= 1) return trimmed;
    final firstName = parts.first;
    final lastInitial = parts.last[0].toUpperCase();
    return '$firstName $lastInitial.';
  }

  factory MemberModel.fromMap(Map<String, dynamic> map) {
    Color parseColor(dynamic raw, String seed) {
      if (raw is int) return Color(raw);
      if (raw is String) {
        final cleaned = raw.toLowerCase().replaceFirst('0x', '');
        final parsed = int.tryParse(cleaned, radix: 16);
        if (parsed != null) return Color(parsed);
      }
      final colors = <Color>[
        const Color(0xFFD85A30),
        const Color(0xFF8B5CF6),
        const Color(0xFF0D9488),
        const Color(0xFF3B82F6),
      ];
      return colors[seed.hashCode.abs() % colors.length];
    }

    final nestedUser = (map['users'] as Map?)?.cast<String, dynamic>();
    final rawDisplayName = (map['name'] ??
        map['display_name'] ??
        nestedUser?['display_name'] ??
        nestedUser?['email'] ??
        'Member').toString();

    final dietary = (nestedUser?['dietary'] as List?)?.map((e) => '$e').toList() ?? [];
    final hideSurname = map['hide_surname'] == true ||
        nestedUser?['hide_surname'] == true ||
        dietary.contains('privacy:hide_surname');

    final displayName = formatDisplayName(rawDisplayName, hideSurname: hideSurname);
    final id = '${map['user_id'] ?? map['id'] ?? nestedUser?['id'] ?? rawDisplayName}';
    final initials = map['initials']?.toString() ??
        _initialsFromName(rawDisplayName);
    final rolesRaw = (map['roles'] as List?) ?? const ['member'];
    final parsedRoles = rolesRaw
        .map((r) => '$r'.replaceAll('MemberRole.', '').toLowerCase())
        .map(
          (r) => MemberRole.values.firstWhere(
            (e) => e.name == r,
            orElse: () => MemberRole.member,
          ),
        )
        .toList();

    final statusStr = map['status']?.toString().toLowerCase() ?? 'approved';
    final status = MemberStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => MemberStatus.approved,
    );

    return MemberModel(
      id: id,
      name: displayName,
      initials: initials,
      color: parseColor(map['color'], id),
      roles: parsedRoles,
      profilePhotoUrl: map['profile_photo_url'] ?? nestedUser?['avatar_url'],
      isOnline: map['is_online'] ?? false,
      lastSeen: map['last_seen'] != null ? DateTime.parse(map['last_seen']) : null,
      isLocationSharingPaused:
          map['is_location_sharing_paused'] ?? !(map['location_sharing'] ?? true),
      gcashNumber: map['gcash_number'] ?? nestedUser?['gcash_number'],
      gcashQrUrl: map['gcash_qr_url'] ?? nestedUser?['gcash_qr_url'],
      status: status,
      hideSurname: hideSurname,
    );
  }

  static String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'M';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initials': initials,
      'color': '0x${color.toARGB32().toRadixString(16)}',
      'roles': roles.map((r) => r.toString()).toList(),
      'profile_photo_url': profilePhotoUrl,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'is_location_sharing_paused': isLocationSharingPaused,
      'gcash_number': gcashNumber,
      'gcash_qr_url': gcashQrUrl,
      'status': status.name,
      'hide_surname': hideSurname,
    };
  }
}

extension MemberRoleDetails on MemberRole {
  String get displayName {
    switch (this) {
      case MemberRole.organizer:
        return 'Organizer';
      case MemberRole.treasurer:
        return 'Treasurer';
      case MemberRole.navigator:
        return 'Navigator';
      case MemberRole.buyer:
        return 'Buyer';
      case MemberRole.documenter:
        return 'Documenter';
      case MemberRole.member:
        return 'Member';
    }
  }

  String get description {
    switch (this) {
      case MemberRole.organizer:
        return 'Full control — manages trip settings, invites/removes members, approves all changes';
      case MemberRole.treasurer:
        return 'Approves and rejects expenses, manages GCash QR, confirms payments, views full payment history';
      case MemberRole.navigator:
        return 'Owns the itinerary — adds, edits, and reorders stops. Plans routes';
      case MemberRole.buyer:
        return 'Logs expenses and purchases, submits receipts for Treasurer approval';
      case MemberRole.documenter:
        return 'Uploads photos, receipts, and trip journal entries. Manages media';
      case MemberRole.member:
        return 'Read-only access to all trip data. Can check own packing list and log personal expenses';
    }
  }

  Color get color {
    switch (this) {
      case MemberRole.organizer:
        return const Color(0xFFD85A30);
      case MemberRole.treasurer:
        return const Color(0xFFD97706);
      case MemberRole.navigator:
        return const Color(0xFF2563EB);
      case MemberRole.buyer:
        return const Color(0xFF059669);
      case MemberRole.documenter:
        return const Color(0xFF7C3AED);
      case MemberRole.member:
        return const Color(0xFF6B7280);
    }
  }
}

extension MemberRolePermissions on MemberModel {
  bool get isOrganizer => roles.contains(MemberRole.organizer);
  bool get isTreasurer => roles.contains(MemberRole.treasurer);
  bool get isNavigator => roles.contains(MemberRole.navigator);
  bool get isBuyer => roles.contains(MemberRole.buyer);
  bool get isDocumenter => roles.contains(MemberRole.documenter);
  bool get isStandardMember => roles.contains(MemberRole.member);

  /// Checks if this member is the trip creator/owner
  bool isTripCreator(String? ownerId) {
    if (ownerId == null || ownerId.isEmpty) return isOrganizer;
    return id == ownerId;
  }

  /// Granular Permissions
  bool get canManageTripSettings => isOrganizer;
  bool get canManageMembers => isOrganizer;
  bool get canApproveTripChanges => isOrganizer;

  bool get canApproveExpenses => isOrganizer || isTreasurer;
  bool get canManageGCashQr => isOrganizer || isTreasurer;
  bool get canConfirmPayments => isOrganizer || isTreasurer;
  bool get canViewFullPaymentHistory => isOrganizer || isTreasurer;

  bool get canManageItinerary => isOrganizer || isNavigator;

  bool get canLogExpenses => isOrganizer || isTreasurer || isBuyer;

  bool get canManageMediaAndJournal => isOrganizer || isDocumenter;

  bool get canViewTripData => true;
  bool get canManageOwnPackingList => true;
  bool get canLogPersonalExpense => true;
}

