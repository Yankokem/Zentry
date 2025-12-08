class TeamMember {
  final String email;
  final String status; // 'pending', 'accepted', 'rejected'
  final String? role; // Role name if assigned
  final DateTime invitedAt;
  final DateTime? respondedAt;

  TeamMember({
    required this.email,
    required this.status,
    this.role,
    DateTime? invitedAt,
    this.respondedAt,
  }) : invitedAt = invitedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'status': status,
      'role': role,
      'invitedAt': invitedAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      email: map['email'] ?? '',
      status: map['status'] ?? 'pending',
      role: map['role'],
      invitedAt: map['invitedAt'] != null
          ? DateTime.parse(map['invitedAt'])
          : DateTime.now(),
      respondedAt: map['respondedAt'] != null
          ? DateTime.parse(map['respondedAt'])
          : null,
    );
  }

  TeamMember copyWith({
    String? email,
    String? status,
    String? role,
    DateTime? invitedAt,
    DateTime? respondedAt,
  }) {
    return TeamMember(
      email: email ?? this.email,
      status: status ?? this.status,
      role: role ?? this.role,
      invitedAt: invitedAt ?? this.invitedAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}
