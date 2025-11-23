class JournalEntry {
  String? id; // Firestore document ID
  String title;
  String content;
  String date;
  String time;
  String mood;

  JournalEntry({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.time,
    this.mood = 'calm',
  });

  // Convert to Map for compatibility with existing code
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'date': date,
      'time': time,
      'mood': mood,
    };
  }

  // Convert to Firestore format (excludes id)
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'date': date,
      'time': time,
      'mood': mood,
    };
  }

  // Create from Map
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      mood: map['mood'] ?? 'calm',
    );
  }

  // Create from Firestore document
  factory JournalEntry.fromFirestore(String id, Map<String, dynamic> data) {
    return JournalEntry(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      mood: data['mood'] ?? 'calm',
    );
  }

  // Copy with method for immutability
  JournalEntry copyWith({
    String? id,
    String? title,
    String? content,
    String? date,
    String? time,
    String? mood,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      time: time ?? this.time,
      mood: mood ?? this.mood,
    );
  }
}
