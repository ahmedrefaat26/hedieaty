import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'eventsmodel.dart';

class DatabaseHelper {
  static final _databaseName = "hedieaty.db";
  static final _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        preferences TEXT,
        firestore_id TEXT )
    ''');
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        location TEXT NOT NULL,
        description TEXT,
        user_id TEXT,
        event_id TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE gifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        status TEXT NOT NULL,
        event_id INTEGER,
        FOREIGN KEY (event_id) REFERENCES events(id) )
    ''');
    await db.execute('''
      CREATE TABLE friends (
        user_id TEXT NOT NULL,
        friend_id TEXT NOT NULL,
        PRIMARY KEY (user_id, friend_id),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (friend_id) REFERENCES users(id) 
      )
    ''');
  }

  // Insert a new event
  Future<int> insertOrUpdateEvent(EventModel event) async {
    Database db = await instance.database;

    // Check if the event already exists by its eventId
    var existingEvent = await db.query(
      'events',
      where: 'event_id = ?',
      whereArgs: [event.eventId],
    );

    if (existingEvent.isNotEmpty) {
      // If the event exists, update it
      Map<String,dynamic> up = event.toMap();
      up.remove('id');
      return await db.update(
        'events',
        up,
        where: 'event_id = ?',
        whereArgs: [event.eventId],
      );
    } else {
      // If the event doesn't exist, insert a new one
      return await db.insert('events', event.toMap());
    }
  }

  // Update an existing event
  Future<int> updateEvent(EventModel event) async {
    Database db = await instance.database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'event_id = ?',
      whereArgs: [event.eventId], // Using eventId as reference
    );
  }

  // Fetch all events for a specific user
  Future<List<EventModel>> getEvents(String userId) async {
    Database db = await instance.database;
    var result = await db.query(
      'events',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.map((e) => EventModel.fromMap(e)).toList();
  }

  // Delete an event
  Future<int> deleteEvent(String eventId) async {
    Database db = await instance.database;
    return await db.delete(
      'events',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }
}
