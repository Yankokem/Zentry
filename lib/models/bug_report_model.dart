class BugReportModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BugReportModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
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
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      priority: data['priority'] ?? 'Medium',
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
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a new bug report for submission
  factory BugReportModel.create({
    required String userId,
    required String title,
    required String description,
    required String category,
    required String priority,
  }) {
    return BugReportModel(
      id: '', // Will be set by Firestore
      userId: userId,
      title: title,
      description: description,
      category: category,
      priority: priority,
      status: 'Open',
      createdAt: DateTime.now(),
    );
  }
}
