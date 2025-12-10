class BugReportModel {
  final String id;
  final String userId;
  final String title;
  final String content; // Rich text content (Delta JSON)
  final String category;
  final String priority;
  final List<String> imageUrls;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BugReportModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    this.imageUrls = const [],
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  // Create from Firestore document
  factory BugReportModel.fromMap(String id, Map<String, dynamic> data) {
    return BugReportModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? 'General',
      priority: data['priority'] ?? 'Medium',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      status: data['status'] ?? 'Open',
      createdAt: (data['createdAt'] as DateTime?) ?? DateTime.now(),
      updatedAt: data['updatedAt'] as DateTime?,
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'category': category,
      'priority': priority,
      'imageUrls': imageUrls,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a new bug report for submission
  factory BugReportModel.create({
    required String userId,
    required String title,
    required String content,
    required String category,
    required String priority,
    List<String> imageUrls = const [],
  }) {
    return BugReportModel(
      id: '', // Will be set by Firestore
      userId: userId,
      title: title,
      content: content,
      category: category,
      priority: priority,
      imageUrls: imageUrls,
      status: 'Open',
      createdAt: DateTime.now(),
    );
  }
}
