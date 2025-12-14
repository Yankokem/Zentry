import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/projects/projects.dart';

/// Service for handling project and ticket-related notifications
class ProjectNotificationService {
  static final ProjectNotificationService _instance =
      ProjectNotificationService._internal();
  factory ProjectNotificationService() => _instance;
  ProjectNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  /// Notify Project Manager when an assignee marks a ticket as done or submits for review
  Future<void> notifyPMTicketReady({
    required Ticket ticket,
    required Project project,
    required String action, // 'marked_done' or 'submitted_review'
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) return;

      // Get PM's email
      final pmDetails = await _userService.getUserDetailsByUid(project.userId);
      if (pmDetails == null || pmDetails['email'] == null) {
        print('⚠️ Could not find PM email for project ${project.id}');
        return;
      }

      final pmEmail = pmDetails['email']!;
      
      // Don't notify if PM is the one who performed the action
      if (pmEmail == currentUser.email) return;

      // Get current user's display name
      final userDetails =
          await _userService.getUserDetailsByEmail(currentUser.email!);
      final displayName = _userService.getDisplayName(userDetails ?? {}, currentUser.email!);

      String title;
      String body;

      if (action == 'marked_done') {
        title = 'Ticket Ready for Review';
        body =
            '$displayName marked ticket "${ticket.title}" as done. You can now move it to the next status.';
      } else if (action == 'submitted_review') {
        title = 'Ticket Submitted for Review';
        body =
            '$displayName submitted ticket "${ticket.title}" for review. Please review and update status.';
      } else {
        return;
      }

      // Create notification in Firestore
      await _createNotification(
        recipientEmail: pmEmail,
        title: title,
        body: body,
        type: 'project_ticket',
        data: {
          'projectId': project.id,
          'ticketNumber': ticket.ticketNumber,
          'action': action,
          'actorEmail': currentUser.email,
        },
      );

      print('✅ Sent notification to PM: $title');
    } catch (e) {
      print('❌ Error sending PM notification: $e');
    }
  }

  /// Notify assignee when PM changes ticket status
  Future<void> notifyAssigneeStatusChanged({
    required Ticket ticket,
    required Project project,
    required String oldStatus,
    required String newStatus,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) return;

      // Get PM's display name
      final pmDetails = await _userService.getUserDetailsByUid(project.userId);
      final pmDisplayName = _userService.getDisplayName(
          pmDetails ?? {}, pmDetails?['email'] ?? 'Project Manager');

      final statusText = _formatStatus(newStatus);

      // Notify all assignees (except the PM if they're assigned)
      for (final assigneeEmail in ticket.assignedTo) {
        if (assigneeEmail == currentUser.email) continue; // Don't notify self

        await _createNotification(
          recipientEmail: assigneeEmail,
          title: 'Ticket Status Updated',
          body:
              '$pmDisplayName changed the status of "${ticket.title}" to $statusText.',
          type: 'project_ticket',
          data: {
            'projectId': project.id,
            'ticketNumber': ticket.ticketNumber,
            'oldStatus': oldStatus,
            'newStatus': newStatus,
          },
        );
      }

      print('✅ Sent status change notifications to ${ticket.assignedTo.length} assignees');
    } catch (e) {
      print('❌ Error sending assignee notifications: $e');
    }
  }

  /// Notify the last assignee who hasn't marked their ticket as done
  Future<void> notifyLastAssignee({
    required Ticket ticket,
    required Project project,
    required String lastAssigneeEmail,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Don't send if the last assignee is the current user
      if (lastAssigneeEmail == currentUser.email) return;

      // Get last assignee's display name
      final assigneeDetails =
          await _userService.getUserDetailsByEmail(lastAssigneeEmail);
      final assigneeName =
          _userService.getDisplayName(assigneeDetails ?? {}, lastAssigneeEmail);

      await _createNotification(
        recipientEmail: lastAssigneeEmail,
        title: 'You\'re the Last One!',
        body:
            'All other team members have completed their work on "${ticket.title}". You\'re the only one left!',
        type: 'project_ticket',
        data: {
          'projectId': project.id,
          'ticketNumber': ticket.ticketNumber,
          'isLastAssignee': true,
        },
      );

      print('✅ Sent last assignee notification to $lastAssigneeEmail');
    } catch (e) {
      print('❌ Error sending last assignee notification: $e');
    }
  }

  /// Create a notification in Firestore
  Future<void> _createNotification({
    required String recipientEmail,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get recipient's UID from email
      final recipientDetails =
          await _userService.getUserDetailsByEmail(recipientEmail);
      if (recipientDetails == null || recipientDetails['uid'] == null) {
        print('⚠️ Could not find UID for email: $recipientEmail');
        return;
      }

      final recipientUid = recipientDetails['uid']!;

      final notification = {
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': recipientUid,
      };

      await _firestore.collection('notifications').add(notification);
    } catch (e) {
      print('❌ Error creating notification: $e');
      rethrow;
    }
  }

  /// Format status for display
  String _formatStatus(String status) {
    switch (status) {
      case 'todo':
        return 'To Do';
      case 'in_progress':
        return 'In Progress';
      case 'in_review':
        return 'In Review';
      case 'done':
        return 'Done';
      default:
        return status;
    }
  }
}
