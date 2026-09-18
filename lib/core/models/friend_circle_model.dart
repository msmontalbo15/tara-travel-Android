import 'package:flutter/material.dart';

class CircleMember {
  final String userId;
  final String name;
  final String? profilePhotoUrl;
  final String defaultRole; // 'member', 'driver', 'treasurer'

  const CircleMember({
    required this.userId,
    required this.name,
    this.profilePhotoUrl,
    this.defaultRole = 'member',
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'profilePhotoUrl': profilePhotoUrl,
      'defaultRole': defaultRole,
    };
  }

  factory CircleMember.fromJson(Map<String, dynamic> json) {
    return CircleMember(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? 'Friend',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      defaultRole: json['defaultRole'] as String? ?? 'member',
    );
  }
}

class FriendCircle {
  final String id;
  final String ownerId;
  final String name;
  final String emoji;
  final String colorHex;
  final String? description;
  final List<CircleMember> members;
  final DateTime createdAt;

  const FriendCircle({
    required this.id,
    required this.ownerId,
    required this.name,
    this.emoji = '👥',
    this.colorHex = '#D85A30',
    this.description,
    this.members = const [],
    required this.createdAt,
  });

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    return Color(int.tryParse('FF$hex', radix: 16) ?? 0xFFD85A30);
  }

  FriendCircle copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? emoji,
    String? colorHex,
    String? description,
    List<CircleMember>? members,
    DateTime? createdAt,
  }) {
    return FriendCircle(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      description: description ?? this.description,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'emoji': emoji,
      'colorHex': colorHex,
      'description': description,
      'members': members.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FriendCircle.fromJson(Map<String, dynamic> json) {
    return FriendCircle(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String? ?? '',
      name: json['name'] as String? ?? 'My Squad',
      emoji: json['emoji'] as String? ?? '👥',
      colorHex: json['colorHex'] as String? ?? '#D85A30',
      description: json['description'] as String?,
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => CircleMember.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
