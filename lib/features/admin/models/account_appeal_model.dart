class AccountAppealModel {
  final String id;
  final String userId;
  final String userEmail;
  final String reason; // 'suspension' or 'ban'
  final String title;
  final String content; // Rich text content (Delta JSON)
  final List<String> evidenceUrls;
  final String status;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  AccountAppealModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.reason,
    required this.title,
    required this.content,
    this.evidenceUrls = const [],
    required this.status,
    this.adminResponse,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  // Create from Firestore document
  factory AccountAppealModel.fromMap(String id, Map<String, dynamic> data) {
    return AccountAppealModel(
      id: id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      reason: data['reason'] ?? 'suspension',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      evidenceUrls: List<String>.from(data['evidenceUrls'] ?? []),
      status: data['status'] ?? 'Pending',
      adminResponse: data['adminResponse'],
      createdAt: (data['createdAt'] as DateTime?) ?? DateTime.now(),
      updatedAt: data['updatedAt'] as DateTime?,
      resolvedAt: data['resolvedAt'] as DateTime?,
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'reason': reason,
      'title': title,
      'content': content,
      'evidenceUrls': evidenceUrls,
      'status': status,
      'adminResponse': adminResponse,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'resolvedAt': resolvedAt,
    };
  }

  // Create a new appeal for submission
  factory AccountAppealModel.create({
    required String userId,
    required String userEmail,
    required String reason,
    required String title,
    required String content,
    List<String> evidenceUrls = const [],
  }) {
    return AccountAppealModel(
      id: '', // Will be set by Firestore
      userId: userId,
      userEmail: userEmail,
      reason: reason,
      title: title,
      content: content,
      evidenceUrls: evidenceUrls,
      status: 'Pending',
      createdAt: DateTime.now(),
    );
  }
}
