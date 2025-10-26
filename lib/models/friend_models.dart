class UserSearchResult {
  final String id;
  final String username;
  final String? initials;
  final bool isFriend;
  final bool hasPendingRequest;
  final String? pendingRequestDirection; // "sent" | "received" | null

  UserSearchResult({
    required this.id,
    required this.username,
    this.initials,
    required this.isFriend,
    required this.hasPendingRequest,
    this.pendingRequestDirection,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      initials: json['initials'],
      isFriend: json['isFriend'] ?? false,
      hasPendingRequest: json['hasPendingRequest'] ?? false,
      pendingRequestDirection: json['pendingRequestDirection'],
    );
  }
  
  // Helper để xác định trạng thái hiển thị
  String? get friendshipStatus {
    if (isFriend) return 'friend';
    if (hasPendingRequest) return 'pending';
    return null;
  }
}

class FriendRequest {
  final int id;
  final String senderUsername;
  final String? senderInitials;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.senderUsername,
    this.senderInitials,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] ?? 0,
      senderUsername: json['senderUsername'] ?? '',
      senderInitials: json['senderInitials'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Friend {
  final String username;
  final String? initials;
  final DateTime friendsSince;

  Friend({
    required this.username,
    this.initials,
    required this.friendsSince,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      username: json['username'] ?? '',
      initials: json['initials'],
      friendsSince: DateTime.parse(json['friendsSince'] ?? DateTime.now().toIso8601String()),
    );
  }
}

