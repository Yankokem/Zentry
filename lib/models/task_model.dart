class Task {
  String title;
  String? description;
  String? assignedTo;
  String time;
  String priority;
  bool isDone;

  Task({
    required this.title,
    this.description,
    this.assignedTo,
    required this.time,
    required this.priority,
    this.isDone = false,
  });

  // Convert to Map for compatibility with existing code
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'time': time,
      'priority': priority,
      'isDone': isDone,
    };
  }

  // Create from Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      title: map['title'] ?? '',
      description: map['description'],
      assignedTo: map['assignedTo'],
      time: map['time'] ?? '',
      priority: map['priority'] ?? 'medium',
      isDone: map['isDone'] ?? false,
    );
  }

  // Copy with method for immutability
  Task copyWith({
    String? title,
    String? description,
    String? assignedTo,
    String? time,
    String? priority,
    bool? isDone,
  }) {
    return Task(
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      time: time ?? this.time,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
    );
  }
}
