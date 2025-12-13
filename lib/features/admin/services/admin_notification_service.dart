import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_notification_model.dart';

/// Service for managing admin notifications
class AdminNotificationService {
  static final AdminNotificationService _instance = AdminNotificationService._internal();
  factory AdminNotificationService() => _instance;
  AdminNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'admin_notifications';

  /// Create a new admin notification
  Future<void> createNotification({
    required String title,
    required String message,
    required AdminNotificationType type,
    Map<String, dynamic>? metadata,
    String? actionUrl,
    String? userId,
    String? relatedEntityId,
  }) async {
    try {
      final notification = AdminNotificationModel(
        id: '', // Will be set by Firestore
        title: title,
        message: message,
        type: type,
        metadata: metadata ?? {},
        createdAt: DateTime.now(),
        isRead: false,
        actionUrl: actionUrl,
        userId: userId,
        relatedEntityId: relatedEntityId,
      );

      await _firestore.collection(_collectionPath).add(notification.toFirestore());
      
      if (kDebugMode) {
        print('Admin notification created: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating admin notification: $e');
      }
    }
  }

  /// Get stream of all admin notifications
  Stream<List<AdminNotificationModel>> getNotificationsStream({
    bool? onlyUnread,
    AdminNotificationType? type,
    int? limit,
  }) {
    Query query = _firestore
        .collection(_collectionPath)
        .orderBy('createdAt', descending: true);

    // Apply filters
    if (onlyUnread == true) {
      query = query.where('isRead', isEqualTo: false);
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => AdminNotificationModel.fromFirestore(doc))
          .toList();

      return notifications;
    });
  }

  /// Get unread notification count
  Stream<int> getUnreadCountStream() {
    return _firestore
        .collection(_collectionPath)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final unreadDocs = await _firestore
          .collection(_collectionPath)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(notificationId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
    }
  }

  /// Delete all read notifications
  Future<void> deleteAllRead() async {
    try {
      final readDocs = await _firestore
          .collection(_collectionPath)
          .where('isRead', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (var doc in readDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting read notifications: $e');
      }
    }
  }

  // ===== Notification Trigger Methods =====

  /// Notify admin of new user registration
  Future<void> notifyNewUser({
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    await createNotification(
      title: 'New User Registration',
      message: '$userName ($userEmail) just registered',
      type: AdminNotificationType.newUser,
      userId: userId,
      metadata: {
        'userName': userName,
        'userEmail': userEmail,
      },
      actionUrl: '/admin/users/$userId',
    );
  }

  /// Notify admin of new bug report
  Future<void> notifyNewBugReport({
    required String bugReportId,
    required String userId,
    required String title,
    required String severity,
    String? description,
  }) async {
    await createNotification(
      title: 'New Bug Report',
      message: 'User reported: $title (Severity: $severity)',
      type: AdminNotificationType.newBugReport,
      userId: userId,
      relatedEntityId: bugReportId,
      metadata: {
        'severity': severity,
        'reportTitle': title,
        if (description != null) 'description': description,
      },
      actionUrl: '/admin/bug-reports/$bugReportId',
    );
  }

  /// Notify admin of bug report status change
  Future<void> notifyBugReportStatusChange({
    required String bugReportId,
    required String title,
    required String oldStatus,
    required String newStatus,
  }) async {
    await createNotification(
      title: 'Bug Report Updated',
      message: '$title: $oldStatus → $newStatus',
      type: AdminNotificationType.bugReportStatusChange,
      relatedEntityId: bugReportId,
      metadata: {
        'oldStatus': oldStatus,
        'newStatus': newStatus,
        'reportTitle': title,
      },
      actionUrl: '/admin/bug-reports/$bugReportId',
    );
  }

  /// Notify admin of new account appeal
  Future<void> notifyNewAppeal({
    required String appealId,
    required String userId,
    required String userName,
    required String reason,
    String? appealMessage,
  }) async {
    await createNotification(
      title: 'New Account Appeal',
      message: '$userName submitted an appeal: $reason',
      type: AdminNotificationType.newAppeal,
      userId: userId,
      relatedEntityId: appealId,
      metadata: {
        'userName': userName,
        'appealReason': reason,
        if (appealMessage != null) 'appealMessage': appealMessage,
      },
      actionUrl: '/admin/appeals/$appealId',
    );
  }

  /// Notify admin of urgent appeal (suspended/banned user)
  Future<void> notifyUrgentAppeal({
    required String appealId,
    required String userId,
    required String userName,
    required String accountStatus,
    String? appealMessage,
  }) async {
    await createNotification(
      title: 'Urgent Appeal',
      message: '$userName (Account: $accountStatus) submitted an urgent appeal',
      type: AdminNotificationType.urgentAppeal,
      userId: userId,
      relatedEntityId: appealId,
      metadata: {
        'userName': userName,
        'accountStatus': accountStatus,
        if (appealMessage != null) 'appealMessage': appealMessage,
      },
      actionUrl: '/admin/appeals/$appealId',
    );
  }

  /// Notify admin of user milestone
  Future<void> notifyUserMilestone({
    required String userId,
    required String userName,
    required String milestone,
    required int count,
  }) async {
    await createNotification(
      title: 'User Milestone Achieved',
      message: '$userName reached $count $milestone!',
      type: AdminNotificationType.userMilestone,
      userId: userId,
      metadata: {
        'userName': userName,
        'milestone': milestone,
        'count': count,
      },
      actionUrl: '/admin/users/$userId',
    );
  }

  /// Notify admin of app milestone
  Future<void> notifyAppMilestone({
    required String milestone,
    required int count,
    String? description,
  }) async {
    await createNotification(
      title: 'App Milestone Reached',
      message: description ?? '$milestone: $count',
      type: AdminNotificationType.appMilestone,
      metadata: {
        'milestone': milestone,
        'count': count,
      },
    );
  }

  /// Notify admin of security alert
  Future<void> notifySecurityAlert({
    required String title,
    required String message,
    String? userId,
    Map<String, dynamic>? additionalData,
  }) async {
    await createNotification(
      title: title,
      message: message,
      type: AdminNotificationType.securityAlert,
      userId: userId,
      metadata: additionalData ?? {},
    );
  }

  /// Notify admin of account action (suspension, ban, activation)
  Future<void> notifyAccountAction({
    required String userId,
    required String userName,
    required String action,
    String? reason,
  }) async {
    await createNotification(
      title: 'Account Action Taken',
      message: '$action: $userName${reason != null ? " - $reason" : ""}',
      type: AdminNotificationType.accountAction,
      userId: userId,
      metadata: {
        'userName': userName,
        'action': action,
        'reason': reason,
      },
      actionUrl: '/admin/users/$userId',
    );
  }
}
