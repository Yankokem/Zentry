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
  /// Structure: notifications/users/{userId}/notifications/{notificationId}
  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore
          .collection('notifications')
          .doc('users')
          .collection(userId)
          .add({
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc('users')
          .collection(userId)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .doc('users')
          .collection(userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc('users')
          .collection(userId)
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Get notifications stream for a user
  Stream<List<AppNotification>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .doc('users')
        .collection(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppNotification(
          id: doc.id,
          userId: userId,
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          type: data['type'] ?? 'custom',
          data: Map<String, dynamic>.from(data['data'] ?? {}),
          isRead: data['isRead'] ?? false,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          responseStatus: data['responseStatus'],
        );
      }).toList();
    });
  }

  /// Get unread notification count
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .doc('users')
        .collection(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Update notification response status (accepted/rejected)
  Future<void> updateNotificationResponse(String userId, String notificationId, String status) async {
    try {
      await _firestore
          .collection('notifications')
          .doc('users')
          .collection(userId)
          .doc(notificationId)
          .update({
        'responseStatus': status,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating notification response: $e');
      rethrow;
    }
  }

  // ==================== Admin Notifications ====================
  // Future implementation for admin notifications
  // Structure: notifications/admin/{notificationId}
  // 
  // Future<void> _createAdminNotification({
  //   required String title,
  //   required String body,
  //   required String type,
  //   Map<String, dynamic>? data,
  // }) async {
  //   try {
  //     await _firestore
  //         .collection('notifications')
  //         .doc('admin')
  //         .collection('notifications')
  //         .add({
  //       'title': title,
  //       'body': body,
  //       'type': type,
  //       'data': data ?? {},
  //       'isRead': false,
  //       'createdAt': FieldValue.serverTimestamp(),
  //     });
  //   } catch (e) {
  //     debugPrint('Error creating admin notification: $e');
  //   }
  // }
  //
  // Future<Stream<List<AppNotification>>> getAdminNotificationsStream() {
  //   return _firestore
  //       .collection('notifications')
  //       .doc('admin')
  //       .collection('notifications')
  //       .orderBy('createdAt', descending: true)
  //       .snapshots()
  //       .map((snapshot) {
  //     return snapshot.docs.map((doc) {
  //       final data = doc.data();
  //       return AppNotification(
  //         id: doc.id,
  //         userId: 'admin',
  //         title: data['title'] ?? '',
  //         body: data['body'] ?? '',
  //         type: data['type'] ?? 'custom',
  //         data: Map<String, dynamic>.from(data['data'] ?? {}),
  //         isRead: data['isRead'] ?? false,
  //         createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  //       );
  //     }).toList();
  //   });
  // }

  // ==================== Notification Triggers ====================

  /// Notify when added to a project
  Future<void> notifyProjectInvitation({
    required String recipientUserId,
    required String projectTitle,
    required String projectId,
    required String inviterName,
    String? role,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'New Project Invitation',
      body: '$inviterName added you to "$projectTitle"${role != null ? ' as $role' : ''}',
      type: 'project_invitation',
      data: {
        'projectId': projectId,
        'projectTitle': projectTitle,
        'inviterName': inviterName,
        if (role != null) 'role': role,
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

  /// Notify when removed from a project
  Future<void> notifyProjectRemoval({
    required String recipientUserId,
    required String projectTitle,
    required String projectId,
    required String removerName,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'Removed from Project',
      body: '$removerName removed you from "$projectTitle"',
      type: 'project_removal',
      data: {
        'projectId': projectId,
        'projectTitle': projectTitle,
      },
    );
  }

  /// Notify when unassigned from a task
  Future<void> notifyTaskUnassigned({
    required String recipientUserId,
    required String taskTitle,
    required String projectTitle,
    required String taskId,
    required String projectId,
    required String unassignerName,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'Task Unassignment',
      body: '$unassignerName unassigned you from "$taskTitle"',
      type: 'task_unassigned',
      data: {
        'taskId': taskId,
        'projectId': projectId,
        'taskTitle': taskTitle,
        'projectTitle': projectTitle,
      },
    );
  }

  /// Notify when added to a shared wishlist
  Future<void> notifyWishlistInvitation({
    required String recipientUserId,
    required String wishlistTitle,
    required String wishlistId,
    required String inviterName,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'Added to Wishlist',
      body: '$inviterName shared "$wishlistTitle" with you',
      type: 'wishlist_invitation',
      data: {
        'wishlistId': wishlistId,
        'wishlistTitle': wishlistTitle,
      },
    );
  }

  /// Notify when removed from a shared wishlist
  Future<void> notifyWishlistRemoval({
    required String recipientUserId,
    required String wishlistTitle,
    required String wishlistId,
    required String removerName,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'Removed from Wishlist',
      body: '$removerName removed you from "$wishlistTitle"',
      type: 'wishlist_removal',
      data: {
        'wishlistId': wishlistId,
        'wishlistTitle': wishlistTitle,
      },
    );
  }

  /// Notify owner when project invitation is accepted
  Future<void> notifyProjectInvitationAccepted({
    required String recipientUserId,
    required String projectTitle,
    required String projectId,
    required String accepterName,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'Project Invitation Accepted',
      body: '$accepterName accepted your invitation to "$projectTitle"',
      type: 'project_invitation_accepted',
      data: {
        'projectId': projectId,
        'projectTitle': projectTitle,
      },
    );
  }

  /// Notify owner when project invitation is rejected
  Future<void> notifyProjectInvitationRejected({
    required String recipientUserId,
    required String projectTitle,
    required String projectId,
    required String rejecterName,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'Project Invitation Declined',
      body: '$rejecterName declined your invitation to "$projectTitle"',
      type: 'project_invitation_rejected',
      data: {
        'projectId': projectId,
        'projectTitle': projectTitle,
      },
    );
  }

  /// Notify owner when wishlist invitation is accepted
  Future<void> notifyWishlistInvitationAccepted({
    required String recipientUserId,
    required String wishlistTitle,
    required String wishlistId,
    required String accepterName,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'Wishlist Invitation Accepted',
      body: '$accepterName accepted your wishlist invitation for "$wishlistTitle"',
      type: 'wishlist_invitation_accepted',
      data: {
        'wishlistId': wishlistId,
        'wishlistTitle': wishlistTitle,
      },
    );
  }

  /// Notify owner when wishlist invitation is rejected
  Future<void> notifyWishlistInvitationRejected({
    required String recipientUserId,
    required String wishlistTitle,
    required String wishlistId,
    required String rejecterName,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'Wishlist Invitation Declined',
      body: '$rejecterName declined your wishlist invitation for "$wishlistTitle"',
      type: 'wishlist_invitation_rejected',
      data: {
        'wishlistId': wishlistId,
        'wishlistTitle': wishlistTitle,
      },
    );
  }

  /// Notify when someone marks a shared wish item as acquired
  Future<void> notifyWishlistAcquired({
    required String recipientUserId,
    required String wishTitle,
    required String wishlistId,
    required String acquiredByName,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'Wish Item Acquired! 🎁',
      body: '$acquiredByName marked "$wishTitle" as acquired',
      type: 'wishlist_acquired',
      data: {
        'wishlistId': wishlistId,
        'wishTitle': wishTitle,
      },
    );
  }

  /// Notify when someone marks a shared wish item as not acquired (undo)
  Future<void> notifyWishlistUndoAcquired({
    required String recipientUserId,
    required String wishTitle,
    required String wishlistId,
    required String undoneByName,
  }) async {
    await _createNotification(
      userId: recipientUserId,
      title: 'Wish Item Status Changed',
      body: '$undoneByName marked "$wishTitle" as not acquired',
      type: 'wishlist_undo_acquired',
      data: {
        'wishlistId': wishlistId,
        'wishTitle': wishTitle,
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
  final String? responseStatus; // 'accepted', 'rejected', or null for pending

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
    this.responseStatus,
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
      case 'project_removal':
        return Icons.person_remove;
      case 'task_assigned':
        return Icons.assignment_ind;
      case 'task_unassigned':
        return Icons.assignment_return;
      case 'task_deadline':
        return Icons.alarm;
      case 'task_overdue':
        return Icons.warning;
      case 'task_status_changed':
        return Icons.sync;
      case 'project_ticket':
        return Icons.assignment;
      case 'wishlist_update':
        return Icons.card_giftcard;
      case 'wishlist_invitation':
        return Icons.card_giftcard;
      case 'wishlist_removal':
        return Icons.remove_circle_outline;
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
      case 'project_invitation_accepted':
        return Colors.green;
      case 'project_invitation_rejected':
        return Colors.red.shade300;
      case 'project_removal':
        return Colors.red.shade400;
      case 'task_assigned':
        return Colors.green;
      case 'task_unassigned':
        return Colors.orange.shade400;
      case 'task_deadline':
        return Colors.orange;
      case 'task_overdue':
        return Colors.red;
      case 'task_status_changed':
        return Colors.purple;
      case 'project_ticket':
        if (data.containsKey('newStatus')) {
          final status = data['newStatus'];
          if (status == 'in_progress') return Colors.orange;
          if (status == 'in_review') return Colors.purple;
          if (status == 'done') return Colors.green;
          if (status == 'todo') return Colors.grey;
        } else if (data.containsKey('action')) {
          final action = data['action'];
          if (action == 'marked_done') return Colors.green;
          if (action == 'submitted_review') return Colors.purple;
        }
        return Colors.blue;
      case 'wishlist_update':
        return Colors.pink;
      case 'wishlist_invitation':
        return Colors.pink.shade300;
      case 'wishlist_invitation_accepted':
        return Colors.green;
      case 'wishlist_invitation_rejected':
        return Colors.red.shade300;
      case 'wishlist_removal':
        return Colors.red.shade300;
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
