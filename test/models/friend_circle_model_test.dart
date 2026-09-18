import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/models/friend_circle_model.dart';

void main() {
  group('CircleMember Model Tests', () {
    test('computes initials correctly for multi-word and single-word names', () {
      const member1 = CircleMember(
        userId: 'u-1',
        name: 'Juan Dela Cruz',
        defaultRole: 'driver',
      );
      expect(member1.initials, 'JD');

      const member2 = CircleMember(
        userId: 'u-2',
        name: 'Maria',
        defaultRole: 'treasurer',
      );
      expect(member2.initials, 'M');

      const memberEmpty = CircleMember(
        userId: 'u-3',
        name: '',
      );
      expect(memberEmpty.initials, '?');
    });

    test('serializes CircleMember to and from JSON', () {
      const member = CircleMember(
        userId: 'u-100',
        name: 'Carlos Mendoza',
        profilePhotoUrl: 'https://example.com/avatar.jpg',
        defaultRole: 'driver',
      );

      final json = member.toJson();
      expect(json['userId'], 'u-100');
      expect(json['name'], 'Carlos Mendoza');
      expect(json['profilePhotoUrl'], 'https://example.com/avatar.jpg');
      expect(json['defaultRole'], 'driver');

      final fromJson = CircleMember.fromJson(json);
      expect(fromJson.userId, member.userId);
      expect(fromJson.name, member.name);
      expect(fromJson.profilePhotoUrl, member.profilePhotoUrl);
      expect(fromJson.defaultRole, member.defaultRole);
    });
  });

  group('FriendCircle Model Tests', () {
    test('creates FriendCircle and serializes to/from JSON correctly', () {
      final now = DateTime.parse('2026-09-18T12:00:00.000Z');
      final circle = FriendCircle(
        id: 'c-1',
        ownerId: 'owner-1',
        name: 'Weekend Hikers',
        emoji: '🏕️',
        colorHex: '#2E7D32',
        description: 'Barkada trekking group',
        members: const [
          CircleMember(userId: 'm-1', name: 'Althea Ramos', defaultRole: 'member'),
          CircleMember(userId: 'm-2', name: 'Ben Torres', defaultRole: 'treasurer'),
        ],
        createdAt: now,
      );

      final json = circle.toJson();
      expect(json['id'], 'c-1');
      expect(json['ownerId'], 'owner-1');
      expect(json['name'], 'Weekend Hikers');
      expect(json['emoji'], '🏕️');
      expect(json['colorHex'], '#2E7D32');
      expect(json['description'], 'Barkada trekking group');
      expect((json['members'] as List).length, 2);
      expect(json['createdAt'], now.toIso8601String());

      final fromJson = FriendCircle.fromJson(json);
      expect(fromJson.id, circle.id);
      expect(fromJson.ownerId, circle.ownerId);
      expect(fromJson.name, circle.name);
      expect(fromJson.emoji, circle.emoji);
      expect(fromJson.colorHex, circle.colorHex);
      expect(fromJson.description, circle.description);
      expect(fromJson.members.length, 2);
      expect(fromJson.members[0].name, 'Althea Ramos');
      expect(fromJson.members[1].defaultRole, 'treasurer');
      expect(fromJson.createdAt, now);
    });

    test('color getter parses hex color correctly', () {
      final circle = FriendCircle(
        id: 'c-2',
        ownerId: 'owner-2',
        name: 'Road Warriors',
        colorHex: '#D85A30',
        createdAt: DateTime.now(),
      );

      expect(circle.color, const Color(0xFFD85A30));
    });

    test('copyWith updates fields while retaining unchanged properties', () {
      final circle = FriendCircle(
        id: 'c-3',
        ownerId: 'owner-3',
        name: 'College Friends',
        createdAt: DateTime.now(),
      );

      final updated = circle.copyWith(
        name: 'College Barkada',
        emoji: '🎓',
      );

      expect(updated.id, circle.id);
      expect(updated.name, 'College Barkada');
      expect(updated.emoji, '🎓');
      expect(updated.colorHex, circle.colorHex);
    });
  });
}
