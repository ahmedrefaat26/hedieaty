class GiftModel {
  final int? id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String status;
  final int eventId;
  final String? firestoreIdgift; // New field for Firestore ID

  GiftModel({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.status,
    required this.eventId,
    this.firestoreIdgift, // Initialize the new field
  });

  factory GiftModel.fromMap(Map<String, dynamic> map) {
    return GiftModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      price: map['price'],
      status: map['status'],
      eventId: map['event_id'],
      firestoreIdgift: map['firestore_Idgift'], // Extract from map
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'status': status,
      'event_id': eventId,
      'firestore_Idgift': firestoreIdgift, // Add to map for SQL operations
    };
  }

  @override
  String toString() {
    return 'Gift{id: $id, name: $name, description: $description, category: $category, price: $price, status: $status, event_id: $eventId, firestore_Idgift: $firestoreIdgift}';
  }
}
