enum FriendshipStatus { pending, accepted, rejected }

class FriendshipModel {
  final String id;
  final String requesterId;
  final String receiverId;
  final FriendshipStatus status;
  final DateTime createdAt;

  const FriendshipModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  factory FriendshipModel.fromMap(Map<String, dynamic> map) {
    FriendshipStatus parseStatus(String? s) {
      switch (s) {
        case 'accepted':
          return FriendshipStatus.accepted;
        case 'rejected':
          return FriendshipStatus.rejected;
        default:
          return FriendshipStatus.pending;
      }
    }

    return FriendshipModel(
      id: map['id']?.toString() ?? '',
      requesterId: map['requester_id']?.toString() ?? '',
      receiverId: map['receiver_id']?.toString() ?? '',
      status: parseStatus(map['status']?.toString()),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requester_id': requesterId,
      'receiver_id': receiverId,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  FriendshipModel copyWith({
    String? id,
    String? requesterId,
    String? receiverId,
    FriendshipStatus? status,
    DateTime? createdAt,
  }) {
    return FriendshipModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
