class Ticket {
  final String ticketNumber;
  final String title;
  final String description;
  final String priority;
  final String status; // 'todo', 'in_progress', 'in_review', 'done'
  final String assignedTo;
  final String projectId;

  Ticket({
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.assignedTo,
    required this.projectId,
  });

  Map<String, dynamic> toMap() {
    return {
      'ticketNumber': ticketNumber,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'assignedTo': assignedTo,
      'projectId': projectId,
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      ticketNumber: map['ticketNumber'],
      title: map['title'],
      description: map['description'],
      priority: map['priority'],
      status: map['status'],
      assignedTo: map['assignedTo'],
      projectId: map['projectId'],
    );
  }

  Ticket copyWith({
    String? ticketNumber,
    String? title,
    String? description,
    String? priority,
    String? status,
    String? assignedTo,
    String? projectId,
  }) {
    return Ticket(
      ticketNumber: ticketNumber ?? this.ticketNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      projectId: projectId ?? this.projectId,
    );
  }
}