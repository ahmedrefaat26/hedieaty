import 'package:hedieaty/database/sqldb.dart';
import 'package:sqflite/sqflite.dart';

class UserModel {
  final int? id;
  final String name;
  final String email;
  final String? preferences;
  final String? firestoreId;

  UserModel({this.id, required this.name, required this.email, this.preferences, this.firestoreId});

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      id: map['id'] as int?, // Cast as int, handle potential nulls
      name: map['name'] as String,
      email: map['email'] as String,
      preferences: map['preferences'] as String?,
      firestoreId: map[' firestore_id '] as String?,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'preferences': preferences,
      ' firestore_id ': firestoreId
    };
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, preferences: $preferences, firestore_Id: $firestoreId}';
  }

  // CRUD operations

  static Future<int> insert(UserModel user) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<UserModel?> getUser(int id) async {
    Database db = await DatabaseHelper.instance.database;
    try {
      List<Map> maps = await db.query('users',
          columns: ['id', 'name', 'email', 'preferences', ' firestore_id '],
          where: 'id = ?',
          whereArgs: [id]);
      if (maps.isNotEmpty) {
        return UserModel.fromMap(maps.first);
      }
    } catch (e) {
      // Print or log the error for debugging
      print('Error fetching user: $e');
    }
    return null;
  }


  static Future<int> update(UserModel user) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  static Future<int> delete(int id) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
