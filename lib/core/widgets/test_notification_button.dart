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
      {'type': 'task_assigned', 'label': '✅ Task Assigned'},
      {'type': 'task_unassigned', 'label': '❌ Task Unassigned'},
      {'type': 'task_status_changed', 'label': '🔄 Task Status Changed'},
      {'type': 'task_deadline', 'label': '⏰ Task Deadline'},
      {'type': 'task_overdue', 'label': '⚠️ Task Overdue'},
      {'type': 'project_invitation', 'label': '📁 Project Invitation'},
      {'type': 'project_removal', 'label': '🚫 Project Removal'},
      {'type': 'project_status_changed', 'label': '📊 Project Status Changed'},
      {'type': 'project_milestone', 'label': '🎯 Project Milestone'},
      {'type': 'wishlist_invitation', 'label': '🎁 Wishlist Invitation'},
      {'type': 'wishlist_update', 'label': '🔔 Wishlist Update'},
      {'type': 'wishlist_removal', 'label': '❌ Wishlist Removal'},
      {'type': 'journal_milestone', 'label': '📖 Journal Milestone'},
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

        case 'task_unassigned':
          await notificationManager.notifyTaskUnassigned(
            recipientUserId: userId,
            taskTitle: 'Test Task - API Integration',
            projectTitle: 'Backend Project',
            taskId: 'TICK-54321',
            projectId: 'test-project-id',
            unassignerName: 'Project Lead',
          );
          break;

        case 'task_status_changed':
          await notificationManager.notifyTaskStatusChanged(
            recipientUserId: userId,
            taskTitle: 'Test Task - UI Design',
            projectTitle: 'Design Project',
            newStatus: 'In Review',
            taskId: 'TICK-11111',
            projectId: 'test-project-id',
            changedByName: 'Team Member',
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

        case 'task_overdue':
          await notificationManager.notifyTaskOverdue(
            userId: userId,
            taskTitle: 'Code Review',
            projectTitle: 'Development Project',
            taskId: 'TICK-99999',
            projectId: 'test-project-id',
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

        case 'project_removal':
          await notificationManager.notifyProjectRemoval(
            recipientUserId: userId,
            projectTitle: 'Old Project',
            projectId: 'test-project-id',
            removerName: 'Admin User',
          );
          break;

        case 'project_status_changed':
          await notificationManager.notifyProjectStatusChanged(
            recipientUserId: userId,
            projectTitle: 'Marketing Campaign',
            projectId: 'test-project-id',
            newStatus: 'Completed',
            changedByName: 'Project Manager',
          );
          break;

        case 'project_milestone':
          await notificationManager.notifyProjectMilestone(
            userId: userId,
            projectTitle: 'E-commerce Platform',
            projectId: 'test-project-id',
            milestoneType: 'halfway',
            percentage: 50,
          );
          break;

        case 'wishlist_invitation':
          await notificationManager.notifyWishlistInvitation(
            recipientUserId: userId,
            wishlistTitle: 'Birthday Wishlist',
            wishlistId: 'test-wish-id',
            inviterName: 'Sarah Connor',
          );
          break;

        case 'wishlist_update':
          await notificationManager.notifyWishlistUpdate(
            recipientUserId: userId,
            wishlistTitle: 'Holiday Shopping',
            wishlistId: 'test-wish-id',
            updaterName: 'Sarah Connor',
            action: 'completed',
          );
          break;

        case 'wishlist_removal':
          await notificationManager.notifyWishlistRemoval(
            recipientUserId: userId,
            wishlistTitle: 'Shared Wishlist',
            wishlistId: 'test-wish-id',
            removerName: 'John Doe',
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
