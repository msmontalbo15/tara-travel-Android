import 'package:flutter/material.dart';

enum FriendStatus {
  pending,
  accepted,
  rejected,
}

class FriendModel {
  final String id; // The user ID of the friend
  final String name;
  final String initials;
  final Color color;
  final String? profilePhotoUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final FriendStatus status;
  final bool hideSurname;

  const FriendModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    this.profilePhotoUrl,
    this.isOnline = false,
    this.lastSeen,
    this.status = FriendStatus.accepted,
    this.hideSurname = false,
  });

  FriendModel copyWith({
    String? id,
    String? name,
    String? initials,
    Color? color,
    String? profilePhotoUrl,
    bool? isOnline,
    DateTime? lastSeen,
    FriendStatus? status,
    bool? hideSurname,
  }) {
    return FriendModel(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      color: color ?? this.color,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
      hideSurname: hideSurname ?? this.hideSurname,
    );
  }

  static String formatDisplayName(String rawName, {bool hideSurname = false}) {
    final trimmed = rawName.trim();
    if (!hideSurname || trimmed.isEmpty) return trimmed;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length <= 1) return trimmed;
    final firstName = parts.first;
    final lastInitial = parts.last[0].toUpperCase();
    return '$firstName $lastInitial.';
  }

  factory FriendModel.fromMap(Map<String, dynamic> map, String currentUserId) {
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

    final friendData = map['friendData'] as Map<String, dynamic>? ?? map;
    final dietary = (friendData['dietary'] as List?)?.map((e) => '$e').toList() ?? [];
    final hideSurname = friendData['hide_surname'] == true ||
        dietary.contains('privacy:hide_surname');
    
    final rawDisplayName = (friendData['display_name'] ??
        friendData['name'] ??
        friendData['email'] ??
        'User').toString();
    final displayName = formatDisplayName(rawDisplayName, hideSurname: hideSurname);
        
    final id = friendData['id']?.toString() ?? rawDisplayName;
    
    final initialsStr = friendData['initials']?.toString() ?? _initialsFromName(rawDisplayName);
    
    final statusStr = map['status']?.toString().toLowerCase() ?? 'accepted';
    final status = FriendStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => FriendStatus.accepted,
    );

    return FriendModel(
      id: id,
      name: displayName,
      initials: initialsStr,
      color: parseColor(friendData['color'], id),
      profilePhotoUrl: friendData['avatar_url'] ?? friendData['profile_photo_url'],
      isOnline: friendData['is_online'] ?? false,
      lastSeen: friendData['last_seen'] != null ? DateTime.tryParse(friendData['last_seen']) : null,
      status: status,
      hideSurname: hideSurname,
    );
  }

  static String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }
}
