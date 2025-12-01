import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  taskReminder,
  journalReminder,
  wishlistUpdate,
  systemUpdate,
  custom,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: _parseNotificationType(data['type']),
      data: data['data'] ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'taskReminder':
        return NotificationType.taskReminder;
      case 'journalReminder':
        return NotificationType.journalReminder;
      case 'wishlistUpdate':
        return NotificationType.wishlistUpdate;
      case 'systemUpdate':
        return NotificationType.systemUpdate;
      default:
        return NotificationType.custom;
    }
  }
}
