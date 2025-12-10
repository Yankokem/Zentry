import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String ticketNumber;
  final String userId;
  final String title;
  final String description;
  final String priority;
  final String status; // 'todo', 'in_progress', 'in_review', 'done'
  final List<String> assignedTo;
  final List<String> membersDone; // Track which assigned members have marked as done
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
    this.membersDone = const [],
    required this.projectId,
    required this.deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
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
      'membersDone': membersDone,
      'projectId': projectId,
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map) {
    List<String> assignedTo = [];
    if (map['assignedTo'] != null) {
      if (map['assignedTo'] is List) {
        assignedTo = List<String>.from(map['assignedTo']);
      } else if (map['assignedTo'] is String) {
        assignedTo = [map['assignedTo']];
      }
    }

    List<String> membersDone = [];
    if (map['membersDone'] != null) {
      if (map['membersDone'] is List) {
        membersDone = List<String>.from(map['membersDone']);
      }
    }

    return Ticket(
      ticketNumber: map['ticketNumber'] ?? 'Unknown',
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      priority: map['priority'],
      status: map['status'],
      assignedTo: assignedTo,
      membersDone: membersDone,
      projectId: map['projectId'],
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'])
          : DateTime.now(),
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
    List<String>? assignedTo,
    List<String>? membersDone,
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
      membersDone: membersDone ?? this.membersDone,
      projectId: projectId ?? this.projectId,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
