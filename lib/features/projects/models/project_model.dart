import 'package:cloud_firestore/cloud_firestore.dart';
import 'project_role_model.dart';
import 'team_member_model.dart';

class Project {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> teamMembers; // Kept for backward compatibility
  final List<TeamMember> teamMemberDetails; // New detailed member info
  final String status;
  final int totalTickets;
  final int completedTickets;
  final String color;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final String category;
  final List<ProjectRole> roles;

  Project({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.teamMembers,
    this.teamMemberDetails = const [],
    required this.status,
    required this.totalTickets,
    required this.completedTickets,
    this.color = 'yellow',
    this.deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
    this.category = 'workspace',
    this.roles = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Helper getters for team member management
  List<TeamMember> get acceptedMembers =>
      teamMemberDetails.where((m) => m.isAccepted).toList();

  List<TeamMember> get pendingMembers =>
      teamMemberDetails.where((m) => m.isPending).toList();

  List<String> get acceptedMemberEmails =>
      acceptedMembers.map((m) => m.email).toList();

  // Get all assignable members (accepted + pending, exclude rejected)
  List<String> get assignableMemberEmails => teamMemberDetails
      .where((m) => !m.isRejected)
      .map((m) => m.email)
      .toList();

  bool isMemberAccepted(String email) =>
      acceptedMembers.any((m) => m.email == email);

  bool isMemberPending(String email) =>
      pendingMembers.any((m) => m.email == email);

  bool isMemberRejected(String email) =>
      teamMemberDetails.any((m) => m.email == email && m.isRejected);

  Project copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<String>? teamMembers,
    List<TeamMember>? teamMemberDetails,
    String? status,
    int? totalTickets,
    int? completedTickets,
    String? color,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    String? category,
    List<ProjectRole>? roles,
  }) {
    return Project(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      teamMembers: teamMembers ?? this.teamMembers,
      teamMemberDetails: teamMemberDetails ?? this.teamMemberDetails,
      status: status ?? this.status,
      totalTickets: totalTickets ?? this.totalTickets,
      completedTickets: completedTickets ?? this.completedTickets,
      color: color ?? this.color,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      roles: roles ?? this.roles,
    );
  }

  double get progressPercentage {
    if (totalTickets == 0) return 0.0;
    return (completedTickets / totalTickets) * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'teamMembers': teamMembers,
      'teamMemberDetails': teamMemberDetails.map((m) => m.toMap()).toList(),
      'status': status,
      'totalTickets': totalTickets,
      'completedTickets': completedTickets,
      'color': color,
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'category': category,
      'roles': roles.map((role) => role.toMap()).toList(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    // Handle backward compatibility: if teamMemberDetails doesn't exist,
    // create it from teamMembers with 'accepted' status
    List<TeamMember> memberDetails = [];
    if (map['teamMemberDetails'] != null) {
      memberDetails = (map['teamMemberDetails'] as List)
          .map((m) => TeamMember.fromMap(m as Map<String, dynamic>))
          .toList();
    } else if (map['teamMembers'] != null) {
      // Migrate old data: assume existing members are accepted
      memberDetails = (map['teamMembers'] as List)
          .map((email) => TeamMember(
                email: email as String,
                status: 'accepted',
                invitedAt: DateTime.now(),
                respondedAt: DateTime.now(),
              ))
          .toList();
    }

    return Project(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      teamMembers: List<String>.from(map['teamMembers'] ?? []),
      teamMemberDetails: memberDetails,
      status: map['status'],
      totalTickets: map['totalTickets'],
      completedTickets: map['completedTickets'],
      color: map['color'] ?? 'yellow',
      deadline:
          map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
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
      isPinned: map['isPinned'] ?? false,
      category: map['category'] ?? 'workspace',
      roles: (map['roles'] as List?)
              ?.map((role) => ProjectRole.fromMap(role as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
