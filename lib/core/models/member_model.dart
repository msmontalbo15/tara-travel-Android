import 'package:flutter/material.dart';

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
    );
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
    final displayName = map['name'] ??
        map['display_name'] ??
        nestedUser?['display_name'] ??
        nestedUser?['email'] ??
        'Member';
    final id = '${map['user_id'] ?? map['id'] ?? nestedUser?['id'] ?? displayName}';
    final initials = map['initials']?.toString() ??
        _initialsFromName(displayName.toString());
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

    return MemberModel(
      id: id,
      name: displayName.toString(),
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
    };
  }
}
