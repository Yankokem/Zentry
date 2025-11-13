class Wish {
  final String? id; // Firestore document ID
  final String title;
  final String price;
  final String category;
  final String notes;
  final String dateAdded;
  final bool completed;

  Wish({
    this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.notes,
    required this.dateAdded,
    this.completed = false,
  });

  // Convert to Map for compatibility with existing code
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'category': category,
      'notes': notes,
      'dateAdded': dateAdded,
      'completed': completed,
    };
  }

  // Convert to Firestore document (excludes id)
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'price': price,
      'category': category,
      'notes': notes,
      'dateAdded': dateAdded,
      'completed': completed,
      'createdAt': dateAdded, // Keep original dateAdded for display
    };
  }

  // Create from Map
  factory Wish.fromMap(Map<String, dynamic> map) {
    return Wish(
      title: map['title'] ?? '',
      price: map['price'] ?? '0',
      category: map['category'] ?? 'other',
      notes: map['notes'] ?? '',
      dateAdded: map['dateAdded'] ?? '',
      completed: map['completed'] ?? false,
    );
  }

  // Create from Firestore document
  factory Wish.fromFirestore(String id, Map<String, dynamic> data) {
    return Wish(
      id: id,
      title: data['title'] ?? '',
      price: data['price'] ?? '0',
      category: data['category'] ?? 'other',
      notes: data['notes'] ?? '',
      dateAdded: data['dateAdded'] ?? '',
      completed: data['completed'] ?? false,
    );
  }

  // Copy with method for immutability
  Wish copyWith({
    String? id,
    String? title,
    String? price,
    String? category,
    String? notes,
    String? dateAdded,
    bool? completed,
  }) {
    return Wish(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      dateAdded: dateAdded ?? this.dateAdded,
      completed: completed ?? this.completed,
    );
  }
}
