import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zentry/core/services/firebase/notification_manager.dart';
import 'package:zentry/core/services/firebase/firestore_service.dart';
import 'package:zentry/features/projects/projects.dart';
import 'package:zentry/features/journal/views/journal_page.dart';
import 'package:zentry/features/wishlist/views/wishlist_page.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationManager _notificationManager = NotificationManager();
  final FirestoreService _firestoreService = FirestoreService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          StreamBuilder<int>(
            stream: _notificationManager.getUnreadCountStream(_userId),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();

              return TextButton.icon(
                onPressed: () async {
                  await _notificationManager.markAllAsRead(_userId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Mark all read'),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notificationManager.getNotificationsStream(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your internet connection\nor contact support if the problem persists',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {}); // Rebuild to retry
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.error != null)
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: isDarkMode ? Colors.white24 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see updates about your projects,\ntasks, and activities here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group notifications by date
          final groupedNotifications = _groupNotificationsByDate(notifications);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: groupedNotifications.length,
            itemBuilder: (context, index) {
              final group = groupedNotifications[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      group['label']!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...group['notifications'].map((notification) {
                    return _buildNotificationTile(notification, isDarkMode);
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _groupNotificationsByDate(
      List<AppNotification> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(const Duration(days: 7));

    final Map<String, List<AppNotification>> groups = {
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'Earlier': [],
    };

    for (var notification in notifications) {
      final notificationDate = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      if (notificationDate.isAtSameMomentAs(today)) {
        groups['Today']!.add(notification);
      } else if (notificationDate.isAtSameMomentAs(yesterday)) {
        groups['Yesterday']!.add(notification);
      } else if (notificationDate.isAfter(thisWeek)) {
        groups['This Week']!.add(notification);
      } else {
        groups['Earlier']!.add(notification);
      }
    }

    // Convert to list format and filter out empty groups
    return groups.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => {
              'label': entry.key,
              'notifications': entry.value,
            })
        .toList();
  }

  Widget _buildNotificationTile(AppNotification notification, bool isDarkMode) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await _notificationManager.deleteNotification(notification.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  // In a real implementation, you'd store the deleted notification
                  // and restore it here
                },
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: InkWell(
        onTap: () async {
          if (!notification.isRead) {
            await _notificationManager.markAsRead(notification.id);
          }
          // TODO: Navigate to relevant screen based on notification type
          _handleNotificationTap(notification);
        },
        child: Container(
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : (isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.blue.withOpacity(0.05)),
            border: Border(
              left: BorderSide(
                color: notification.isRead
                    ? Colors.transparent
                    : notification.getColor(),
                width: 4,
              ),
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notification.getColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notification.getIcon(),
                color: notification.getColor(),
                size: 24,
              ),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight:
                    notification.isRead ? FontWeight.normal : FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.getTimeAgo(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
            trailing: !notification.isRead
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: notification.getColor(),
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) async {
    // Navigation logic based on notification type
    switch (notification.type) {
      case 'project_invitation':
      case 'project_status_changed':
      case 'project_milestone':
        // Navigate to project details
        final projectId = notification.data['projectId'];
        if (projectId != null) {
          try {
            final project = await _firestoreService.getProjectById(projectId);
            if (project != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectDetailPage(project: project),
                ),
              );
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Project not found')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading project: $e')),
              );
            }
          }
        }
        break;

      case 'task_assigned':
      case 'task_deadline':
      case 'task_overdue':
      case 'task_status_changed':
        // Navigate to project with task highlighted
        final projectId = notification.data['projectId'];
        if (projectId != null) {
          try {
            final project = await _firestoreService.getProjectById(projectId);
            if (project != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectDetailPage(project: project),
                ),
              );
              // TODO: Add task highlighting functionality to ProjectDetailPage
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Project not found')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading project: $e')),
              );
            }
          }
        }
        break;

      case 'wishlist_update':
        // Navigate to wishlist
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WishlistPage()),
          );
        }
        break;

      case 'journal_milestone':
        // Navigate to journal
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalPage()),
          );
        }
        break;

      default:
        break;
    }
  }
}
