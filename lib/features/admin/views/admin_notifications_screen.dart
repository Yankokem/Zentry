import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/admin_notification_model.dart';
import '../services/admin_notification_service.dart';
import '../services/firebase/bug_report_service.dart';
import '../services/firebase/account_appeal_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final AdminNotificationService _service = AdminNotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Notifications'),
        actions: [
          // Mark all as read
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await _service.markAllAsRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AdminNotificationModel>>(
        stream: _service.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AdminNotificationModel notification) {
    final notificationColor = AdminNotificationModel.getColorForType(notification.type);
    final notificationIcon = AdminNotificationModel.getIconForType(notification.type);
    
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.done, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - mark as read
          await _service.markAsRead(notification.id);
          return false;
        } else {
          // Swipe left - delete
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Notification'),
              content: const Text('Are you sure you want to delete this notification?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await _service.deleteNotification(notification.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : Colors.blue.withOpacity(0.05),
          border: Border(
            left: BorderSide(
              color: notification.isRead
                  ? Colors.transparent
                  : notificationColor,
              width: 4,
            ),
          ),
        ),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: notificationColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              notificationIcon,
              color: notificationColor,
              size: 24,
            ),
          ),
          title: Text(
            _getNotificationTitle(notification),
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                _getNotificationBody(notification),
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                timeago.format(notification.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          isThreeLine: true,
          trailing: !notification.isRead
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: notificationColor,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () async {
            // Mark as read when tapped
            if (!notification.isRead) {
              await _service.markAsRead(notification.id);
            }
            
            // Navigate based on notification type
            if (!mounted) return;
            
            switch (notification.type) {
              case AdminNotificationType.newUser:
                if (notification.userId != null) {
                  Navigator.pushNamed(
                    context,
                    '/admin/user-detail',
                    arguments: notification.userId!,
                  );
                }
                break;
              
              case AdminNotificationType.newBugReport:
              case AdminNotificationType.bugReportStatusChange:
                if (notification.relatedEntityId != null) {
                  _navigateToBugReport(context, notification.relatedEntityId!);
                }
                break;
              
              case AdminNotificationType.newAppeal:
              case AdminNotificationType.urgentAppeal:
                if (notification.relatedEntityId != null) {
                  _navigateToAppeal(context, notification.relatedEntityId!);
                }
                break;
              
              case AdminNotificationType.accountAction:
                // For account actions like suspension lifted, navigate to user detail
                if (notification.userId != null) {
                  Navigator.pushNamed(
                    context,
                    '/admin/user-detail',
                    arguments: notification.userId!,
                  );
                }
                break;
              
              default:
                // For other notification types, just mark as read (no navigation)
                break;
            }
          },
        ),
      ),
    );
  }

  String _getNotificationTitle(AdminNotificationModel notification) {
    switch (notification.type) {
      case AdminNotificationType.newUser:
        return 'New User Registered!';
      case AdminNotificationType.newBugReport:
        return notification.metadata['reportTitle'] ?? notification.title;
      case AdminNotificationType.newAppeal:
      case AdminNotificationType.urgentAppeal:
        return notification.metadata['appealReason'] ?? notification.title;
      default:
        return notification.title;
    }
  }

  String _getNotificationBody(AdminNotificationModel notification) {
    switch (notification.type) {
      case AdminNotificationType.newUser:
        final userName = notification.metadata['userName'] ?? 'Unknown';
        final userEmail = notification.metadata['userEmail'] ?? '';
        return '$userName\n$userEmail';
      case AdminNotificationType.newBugReport:
        // Show a preview of the description if available
        final description = notification.metadata['description'] ?? notification.message;
        return description.length > 80 ? '${description.substring(0, 80)}...' : description;
      case AdminNotificationType.newAppeal:
      case AdminNotificationType.urgentAppeal:
        // Show a preview of the appeal message
        final message = notification.metadata['appealMessage'] ?? notification.message;
        return message.length > 80 ? '${message.substring(0, 80)}...' : message;
      default:
        return notification.message;
    }
  }

  Future<void> _navigateToBugReport(BuildContext context, String bugReportId) async {
    try {
      final bugService = BugReportService();
      final report = await bugService.getBugReportById(bugReportId);
      
      if (mounted && report != null) {
        Navigator.pushNamed(
          context,
          '/admin/bug-report-details',
          arguments: report,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bug report: $e')),
        );
      }
    }
  }

  Future<void> _navigateToAppeal(BuildContext context, String appealId) async {
    try {
      final appealService = AccountAppealService();
      final appeal = await appealService.getAppealById(appealId);
      
      if (mounted && appeal != null) {
        Navigator.pushNamed(
          context,
          '/admin/appeal-details',
          arguments: appeal,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appeal: $e')),
        );
      }
    }
  }
}
