class FriendModel {
  final int userId;
  final int friendId;

  FriendModel({required this.userId, required this.friendId});

  factory FriendModel.fromMap(Map<String, dynamic> map) {
    return FriendModel(
      userId: map['user_id'],
      friendId: map['friend_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'friend_id': friendId
    };
  }

  @override
  String toString() {
    return 'Friend{user_id: $userId, friend_id: $friendId}';
  }
}
