class EventModel {
  final int? id;
  final String name;
  final String date;
  final String location;
  final String? description;
  final String userId;  // Changed to String for Firebase user ID
  final String eventId; // Added eventId for Firebase event ID

  EventModel({
    this.id,
    required this.name,
    required this.date,
    required this.location,
    this.description,
    required this.userId,
    required this.eventId, // Initialize eventId
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'],
      name: map['name'],
      date: map['date'],
      location: map['location'],
      description: map['description'],
      userId: map['user_id'],
      eventId: map['event_id'], // Fetch eventId from database
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'location': location,
      'description': description,
      'user_id': userId, // Store the userId as a string
      'event_id': eventId, // Store the eventId as a string
    };
  }

  @override
  String toString() {
    return 'Event{id: $id, name: $name, date: $date, location: $location, description: $description, user_id: $userId, event_id: $eventId}';
  }
}
