import 'package:cloud_firestore/cloud_firestore.dart';

class BugReportModel {
  final String id;
  final String userId;
  final String userEmail;
  final String title;
  final String content; // Rich text content (Delta JSON)
  final String category;
  final List<String> imageUrls;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BugReportModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.title,
    required this.content,
    required this.category,
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
      userEmail: data['userEmail'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? 'General',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      status: data['status'] ?? 'Open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'title': title,
      'content': content,
      'category': category,
      'imageUrls': imageUrls,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create a new bug report for submission
  factory BugReportModel.create({
    required String userId,
    required String userEmail,
    required String title,
    required String content,
    required String category,
    List<String> imageUrls = const [],
  }) {
    return BugReportModel(
      id: '', // Will be set by Firestore
      userId: userId,
      userEmail: userEmail,
      title: title,
      content: content,
      category: category,
      imageUrls: imageUrls,
      status: 'Open',
      createdAt: DateTime.now(),
    );
  }
}
