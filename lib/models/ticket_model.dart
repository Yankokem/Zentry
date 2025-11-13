import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String ticketNumber;
  final String userId;
  final String title;
  final String description;
  final String priority;
  final String status; // 'todo', 'in_progress', 'in_review', 'done'
  final String assignedTo;
  final String projectId;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ticket({
    required this.ticketNumber,
    required this.userId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.assignedTo,
    required this.projectId,
    this.deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'ticketNumber': ticketNumber,
      'userId': userId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'assignedTo': assignedTo,
      'projectId': projectId,
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      ticketNumber: map['ticketNumber'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      priority: map['priority'],
      status: map['status'],
      assignedTo: map['assignedTo'],
      projectId: map['projectId'],
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt']))
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt']))
          : null,
    );
  }

  Ticket copyWith({
    String? ticketNumber,
    String? userId,
    String? title,
    String? description,
    String? priority,
    String? status,
    String? assignedTo,
    String? projectId,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ticket(
      ticketNumber: ticketNumber ?? this.ticketNumber,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      projectId: projectId ?? this.projectId,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
