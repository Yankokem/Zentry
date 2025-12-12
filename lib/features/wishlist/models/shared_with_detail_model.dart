import 'package:flutter/foundation.dart';

class SharedWithDetail {
  final String email;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime invitedAt;
  final DateTime? respondedAt;
  final bool canEdit; // Always false for shared users, only owner can edit

  SharedWithDetail({
    required this.email,
    required this.status,
    DateTime? invitedAt,
    this.respondedAt,
    this.canEdit = false,
  }) : invitedAt = invitedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'status': status,
      'invitedAt': invitedAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'canEdit': canEdit,
    };
  }

  factory SharedWithDetail.fromMap(Map<String, dynamic> map) {
    final email = map['email'] ?? '';
    final status = map['status'] ?? 'pending';
    debugPrint('\ud83c\udfaf SharedWithDetail.fromMap: email=$email, status=$status');
    return SharedWithDetail(
      email: email,
      status: status,
      invitedAt: map['invitedAt'] != null
          ? DateTime.parse(map['invitedAt'])
          : DateTime.now(),
      respondedAt: map['respondedAt'] != null
          ? DateTime.parse(map['respondedAt'])
          : null,
      canEdit: map['canEdit'] ?? false,
    );
  }

  SharedWithDetail copyWith({
    String? email,
    String? status,
    DateTime? invitedAt,
    DateTime? respondedAt,
    bool? canEdit,
  }) {
    return SharedWithDetail(
      email: email ?? this.email,
      status: status ?? this.status,
      invitedAt: invitedAt ?? this.invitedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      canEdit: canEdit ?? this.canEdit,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}
