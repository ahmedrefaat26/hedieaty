import 'package:hedieaty/database/sqldb.dart';
import 'package:hedieaty/database/usersmodel.dart';
import 'package:sqflite/sqflite.dart';

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
Future<void> addFriendToLocalDatabase(Map<String, dynamic> userData) async {
  Database db = await DatabaseHelper.instance.database;

  // Assuming `currentUserId` is the logged-in user's ID and `userData['uid']` is the friend's ID from Firestore.
  String currentUserId = getCurrentUserId(); // You need to implement this method to get the current user's ID.
  String friendId = userData['uid']; // Ensure that 'uid' is being fetched and passed here.

  await db.insert('friends', {
    'user_id': currentUserId,
    'friend_id': friendId,
  });

  print("Friend added to local database.");
  // Optionally, refresh the state of your home screen or handle updates here
}


