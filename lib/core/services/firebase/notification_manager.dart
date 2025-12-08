import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages in-app notifications for user activities
/// Generates notifications for:
/// - Project invitations and team member additions
/// - Task assignments and deadline reminders
/// - Task status changes (especially tasks assigned to you)
/// - Shared wishlist updates
/// - Journal entry milestones
/// - Overdue tasks
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a notification in Firestore
  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Get notifications stream for a user
  Stream<List<AppNotification>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppNotification(
          id: doc.id,
          userId: data['userId'] ?? '',
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          type: data['type'] ?? 'custom',
          data: Map<String, dynamic>.from(data['data'] ?? {}),
          isRead: data['isRead'] ?? false,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  /// Get unread notification count
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ==================== Notification Triggers ====================

  /// Notify when added to a project
  Future<void> notifyProjectInvitation({
    required String recipientUserId,
    required String projectTitle,
    required String projectId,
    required String inviterName,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'New Project Invitation',
      body: '$inviterName added you to "$projectTitle"',
      type: 'project_invitation',
      data: {
        'projectId': projectId,
        'projectTitle': projectTitle,
        'inviterName': inviterName,
      },
    );
  }

  /// Notify when assigned a task
  Future<void> notifyTaskAssigned({
    required String recipientUserId,
    required String taskTitle,
    required String projectTitle,
    required String taskId,
    required String projectId,
    required String assignerName,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'New Task Assignment',
      body: '$assignerName assigned you "$taskTitle" in $projectTitle',
      type: 'task_assigned',
      data: {
        'taskId': taskId,
        'projectId': projectId,
        'taskTitle': taskTitle,
        'projectTitle': projectTitle,
      },
    );
  }

  /// Notify when task deadline is approaching (1 day before)
  Future<void> notifyTaskDeadlineApproaching({
    required String userId,
    required String taskTitle,
    required String projectTitle,
    required String taskId,
    required String projectId,
    required DateTime deadline,
  }) async {
    final hoursRemaining = deadline.difference(DateTime.now()).inHours;
    await _createNotification(
      userId: userId,
      title: 'Task Deadline Approaching',
      body: '"$taskTitle" is due in $hoursRemaining hours',
      type: 'task_deadline',
      data: {
        'taskId': taskId,
        'projectId': projectId,
        'taskTitle': taskTitle,
        'deadline': deadline.toIso8601String(),
      },
    );
  }

  /// Notify when task is overdue
  Future<void> notifyTaskOverdue({
    required String userId,
    required String taskTitle,
    required String projectTitle,
    required String taskId,
    required String projectId,
  }) async {
    await _createNotification(
      userId: userId,
      title: 'Task Overdue',
      body: '"$taskTitle" in $projectTitle is now overdue',
      type: 'task_overdue',
      data: {
        'taskId': taskId,
        'projectId': projectId,
        'taskTitle': taskTitle,
      },
    );
  }

  /// Notify when task status changes
  Future<void> notifyTaskStatusChanged({
    required String recipientUserId,
    required String taskTitle,
    required String projectTitle,
    required String newStatus,
    required String taskId,
    required String projectId,
    required String changedByName,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'Task Status Updated',
      body: '$changedByName marked "$taskTitle" as $newStatus',
      type: 'task_status_changed',
      data: {
        'taskId': taskId,
        'projectId': projectId,
        'taskTitle': taskTitle,
        'newStatus': newStatus,
      },
    );
  }

  /// Notify when someone updates a shared wishlist
  Future<void> notifyWishlistUpdate({
    required String recipientUserId,
    required String wishlistTitle,
    required String wishlistId,
    required String updaterName,
    required String action, // 'added', 'completed', 'updated'
  }) async {
    String actionText = action == 'added'
        ? 'added'
        : action == 'completed'
            ? 'completed'
            : 'updated';

    await _createNotification(
      userId: recipientUserId,
      title: 'Shared Wishlist Update',
      body: '$updaterName $actionText "$wishlistTitle"',
      type: 'wishlist_update',
      data: {
        'wishlistId': wishlistId,
        'wishlistTitle': wishlistTitle,
        'action': action,
      },
    );
  }

  /// Notify journal entry milestone (e.g., 10th entry, 30 days streak)
  Future<void> notifyJournalMilestone({
    required String userId,
    required String milestoneType,
    required int count,
  }) async {
    String title = '';
    String body = '';

    switch (milestoneType) {
      case 'entry_count':
        title = 'Journal Milestone! 🎉';
        body = 'You\'ve written $count journal entries. Keep it up!';
        break;
      case 'streak':
        title = 'Streak Milestone! 🔥';
        body = 'You\'re on a $count-day journaling streak!';
        break;
      case 'week':
        title = 'Weekly Achievement! ⭐';
        body = 'You journaled every day this week!';
        break;
    }

    await _createNotification(
      userId: userId,
      title: title,
      body: body,
      type: 'journal_milestone',
      data: {
        'milestoneType': milestoneType,
        'count': count,
      },
    );
  }

  /// Notify project milestone (e.g., 50% complete, all tasks done)
  Future<void> notifyProjectMilestone({
    required String userId,
    required String projectTitle,
    required String projectId,
    required String milestoneType,
    required int percentage,
  }) async {
    String title = '';
    String body = '';

    switch (milestoneType) {
      case 'halfway':
        title = 'Project Milestone! 🎯';
        body = '"$projectTitle" is 50% complete!';
        break;
      case 'almost_done':
        title = 'Almost There! 🚀';
        body = '"$projectTitle" is 90% complete!';
        break;
      case 'completed':
        title = 'Project Completed! 🎉';
        body = 'Congratulations! "$projectTitle" is 100% complete!';
        break;
    }

    await _createNotification(
      userId: userId,
      title: title,
      body: body,
      type: 'project_milestone',
      data: {
        'projectId': projectId,
        'projectTitle': projectTitle,
        'percentage': percentage,
      },
    );
  }

  /// Notify when project status changes
  Future<void> notifyProjectStatusChanged({
    required String recipientUserId,
    required String projectTitle,
    required String projectId,
    required String newStatus,
    required String changedByName,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'Project Status Updated',
      body: '$changedByName changed "$projectTitle" status to $newStatus',
      type: 'project_status_changed',
      data: {
        'projectId': projectId,
        'projectTitle': projectTitle,
        'newStatus': newStatus,
      },
    );
  }
}

/// Notification model for in-app notifications
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData getIcon() {
    switch (type) {
      case 'project_invitation':
        return Icons.group_add;
      case 'task_assigned':
        return Icons.assignment_ind;
      case 'task_deadline':
        return Icons.alarm;
      case 'task_overdue':
        return Icons.warning;
      case 'task_status_changed':
        return Icons.sync;
      case 'wishlist_update':
        return Icons.card_giftcard;
      case 'journal_milestone':
        return Icons.emoji_events;
      case 'project_milestone':
        return Icons.military_tech;
      case 'project_status_changed':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  Color getColor() {
    switch (type) {
      case 'project_invitation':
        return Colors.blue;
      case 'task_assigned':
        return Colors.green;
      case 'task_deadline':
        return Colors.orange;
      case 'task_overdue':
        return Colors.red;
      case 'task_status_changed':
        return Colors.purple;
      case 'wishlist_update':
        return Colors.pink;
      case 'journal_milestone':
        return Colors.amber;
      case 'project_milestone':
        return Colors.teal;
      case 'project_status_changed':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
