class JournalEntry {
  String title;
  String content;
  String date;
  String time;
  String mood;

  JournalEntry({
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

  // Create from Map
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      mood: map['mood'] ?? 'calm',
    );
  }

  // Copy with method for immutability
  JournalEntry copyWith({
    String? title,
    String? content,
    String? date,
    String? time,
    String? mood,
  }) {
    return JournalEntry(
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      time: time ?? this.time,
      mood: mood ?? this.mood,
    );
  }
}
