class Wish {
  String title;
  String price;
  String category;
  String notes;
  String dateAdded;
  bool completed;

  Wish({
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

  // Copy with method for immutability
  Wish copyWith({
    String? title,
    String? price,
    String? category,
    String? notes,
    String? dateAdded,
    bool? completed,
  }) {
    return Wish(
      title: title ?? this.title,
      price: price ?? this.price,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      dateAdded: dateAdded ?? this.dateAdded,
      completed: completed ?? this.completed,
    );
  }
}
