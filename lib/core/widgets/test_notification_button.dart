import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zentry/core/services/firebase/notification_manager.dart';

/// Test notification helper for development
/// Add this as a FloatingActionButton in any screen to create test notifications
class TestNotificationButton extends StatelessWidget {
  const TestNotificationButton({super.key});

  Future<void> _createTestNotification(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not signed in')),
      );
      return;
    }

    final notificationTypes = [
      {'type': 'task_assigned', 'label': 'Task Assigned'},
      {'type': 'project_invitation', 'label': 'Project Invitation'},
      {'type': 'task_deadline', 'label': 'Task Deadline'},
      {'type': 'wishlist_update', 'label': 'Wishlist Update'},
      {'type': 'journal_milestone', 'label': 'Journal Milestone'},
    ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Test Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: notificationTypes.map((item) {
            return ListTile(
              title: Text(item['label'] as String),
              onTap: () async {
                Navigator.pop(context);
                await _sendTestNotification(
                  context,
                  item['type'] as String,
                  currentUser.uid,
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification(
    BuildContext context,
    String type,
    String userId,
  ) async {
    try {
      final notificationManager = NotificationManager();

      switch (type) {
        case 'task_assigned':
          await notificationManager.notifyTaskAssigned(
            recipientUserId: userId,
            taskTitle: 'Test Task - Fix Login Bug',
            projectTitle: 'Mobile App Project',
            taskId: 'TICK-12345',
            projectId: 'test-project-id',
            assignerName: 'Test Manager',
          );
          break;

        case 'project_invitation':
          await notificationManager.notifyProjectInvitation(
            recipientUserId: userId,
            projectTitle: 'Website Redesign',
            projectId: 'test-project-id',
            inviterName: 'Jane Smith',
          );
          break;

        case 'task_deadline':
          await notificationManager.notifyTaskDeadlineApproaching(
            userId: userId,
            taskTitle: 'Submit Proposal',
            projectTitle: 'Client Project',
            taskId: 'TICK-67890',
            projectId: 'test-project-id',
            deadline: DateTime.now().add(const Duration(hours: 23)),
          );
          break;

        case 'wishlist_update':
          await notificationManager.notifyWishlistUpdate(
            recipientUserId: userId,
            wishlistTitle: 'Birthday Wishlist',
            wishlistId: 'test-wish-id',
            updaterName: 'Sarah Connor',
            action: 'completed',
          );
          break;

        case 'journal_milestone':
          await notificationManager.notifyJournalMilestone(
            userId: userId,
            milestoneType: 'entry_count',
            count: 10,
          );
          break;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test notification created: $type'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _createTestNotification(context),
      tooltip: 'Create Test Notification',
      child: const Icon(Icons.notification_add),
    );
  }
}
