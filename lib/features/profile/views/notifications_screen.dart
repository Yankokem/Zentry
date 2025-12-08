import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zentry/core/core.dart';
import 'package:zentry/core/services/firebase/notification_manager.dart';
import 'package:zentry/core/services/firebase/firestore_service.dart';
import 'package:zentry/features/projects/projects.dart';
import 'package:zentry/features/journal/views/journal_page.dart';
import 'package:zentry/features/wishlist/wishlist.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationManager _notificationManager = NotificationManager();
  final FirestoreService _firestoreService = FirestoreService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Map<String, String> _invitationResponses = {}; // notificationId -> 'accepted' or 'rejected'

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
          // Initialize response status from Firebase data
          if (snapshot.hasData) {
            for (final notification in snapshot.data!) {
              if (notification.responseStatus != null) {
                _invitationResponses[notification.id] = notification.responseStatus!;
              }
            }
          }
          
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

  bool _isPendingInvitation(AppNotification notification) {
    return notification.type == 'project_invitation' ||
        notification.type == 'wishlist_invitation';
  }

  Future<void> _handleAcceptInvitation(AppNotification notification) async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) {
        throw Exception('User email not found');
      }

      if (notification.type == 'project_invitation') {
        final projectId = notification.data['projectId'];
        if (projectId == null) throw Exception('Project ID not found');

        await _firestoreService.acceptProjectInvitation(projectId, userEmail);

        // Notify the project owner
        final project = await _firestoreService.getProjectById(projectId);
        if (project != null) {
          final userName = FirebaseAuth.instance.currentUser?.displayName ?? userEmail;
          await _notificationManager.notifyProjectInvitationAccepted(
            recipientUserId: project.userId,
            projectTitle: project.title,
            projectId: projectId,
            accepterName: userName,
          );
        }
      } else if (notification.type == 'wishlist_invitation') {
        final wishlistId = notification.data['wishlistId'];
        if (wishlistId == null || wishlistId.toString().isEmpty) {
          throw Exception('Wishlist ID not found or empty');
        }

        final wishlistService = WishlistService();
        await wishlistService.acceptWishlistInvitation(wishlistId.toString(), userEmail);

        // Get wish details and notify owner
        final wishRef = await FirebaseFirestore.instance
            .collection('wishlists')
            .doc(wishlistId.toString())
            .get();
        
        if (wishRef.exists) {
          final wishData = wishRef.data()!;
          final ownerId = wishData['userId'];
          final wishTitle = wishData['title'] ?? 'Wishlist';
          final userName = FirebaseAuth.instance.currentUser?.displayName ?? userEmail;
          
          await _notificationManager.notifyWishlistInvitationAccepted(
            recipientUserId: ownerId,
            wishlistTitle: wishTitle,
            wishlistId: wishlistId.toString(),
            accepterName: userName,
          );
        }
      }

      // Update notification response status in Firebase
      await _notificationManager.updateNotificationResponse(notification.id, 'accepted');

      // Store response status in memory as well
      if (mounted) {
        setState(() {
          _invitationResponses[notification.id] = 'accepted';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation accepted!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting invitation: $e')),
        );
      }
    }
  }

  Future<void> _handleRejectInvitation(AppNotification notification) async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) {
        throw Exception('User email not found');
      }

      if (notification.type == 'project_invitation') {
        final projectId = notification.data['projectId'];
        if (projectId == null) throw Exception('Project ID not found');

        await _firestoreService.rejectProjectInvitation(projectId, userEmail);

        // Notify the project owner
        final project = await _firestoreService.getProjectById(projectId);
        if (project != null) {
          final userName = FirebaseAuth.instance.currentUser?.displayName ?? userEmail;
          await _notificationManager.notifyProjectInvitationRejected(
            recipientUserId: project.userId,
            projectTitle: project.title,
            projectId: projectId,
            rejecterName: userName,
          );
        }
      } else if (notification.type == 'wishlist_invitation') {
        final wishlistId = notification.data['wishlistId'];
        if (wishlistId == null) throw Exception('Wishlist ID not found');

        final wishlistService = WishlistService();
        await wishlistService.rejectWishlistInvitation(wishlistId, userEmail);

        // Get wish details and notify owner
        final wishRef = await FirebaseFirestore.instance
            .collection('wishlists')
            .doc(wishlistId)
            .get();
        
        if (wishRef.exists) {
          final wishData = wishRef.data()!;
          final ownerId = wishData['userId'];
          final wishTitle = wishData['title'] ?? 'Wishlist';
          final userName = FirebaseAuth.instance.currentUser?.displayName ?? userEmail;
          
          await _notificationManager.notifyWishlistInvitationRejected(
            recipientUserId: ownerId,
            wishlistTitle: wishTitle,
            wishlistId: wishlistId,
            rejecterName: userName,
          );
        }
      }

      // Update notification response status in Firebase
      await _notificationManager.updateNotificationResponse(notification.id, 'rejected');

      // Store response status in memory as well
      if (mounted) {
        setState(() {
          _invitationResponses[notification.id] = 'rejected';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation declined'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error declining invitation: $e')),
        );
      }
    }
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
                // Show accept/reject buttons or response status for pending invitations
                if (_isPendingInvitation(notification)) ...[
                  const SizedBox(height: 8),
                  if (_invitationResponses.containsKey(notification.id)) ...[
                    // Show response status text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _invitationResponses[notification.id] == 'accepted'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _invitationResponses[notification.id] == 'accepted'
                                ? Icons.check_circle
                                : Icons.block,
                            size: 14,
                            color: _invitationResponses[notification.id] == 'accepted'
                                ? Colors.green
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _invitationResponses[notification.id] == 'accepted'
                                ? 'You\'ve accepted ${notification.type == 'project_invitation' ? 'the project' : 'the wishlist'}'
                                : 'You\'ve declined ${notification.type == 'project_invitation' ? 'the project' : 'the wishlist'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _invitationResponses[notification.id] == 'accepted'
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Show action buttons
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _handleAcceptInvitation(notification),
                          icon: const Icon(Icons.check, size: 14),
                          label: const Text('Accept', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green, width: 1.5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _handleRejectInvitation(notification),
                          icon: const Icon(Icons.close, size: 14),
                          label: const Text('Decline', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 1.5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
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
        // Navigate to the specific project detail page
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

      case 'project_invitation_accepted':
      case 'project_invitation_rejected':
        // Navigate to the specific project detail page
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

      case 'project_removal':
        // Navigate to projects list page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProjectsPage()),
          );
        }
        break;

      case 'project_status_changed':
      case 'project_milestone':
        // Navigate to projects list page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProjectsPage()),
          );
        }
        break;

      case 'task_assigned':
      case 'task_unassigned':
      case 'task_deadline':
      case 'task_overdue':
      case 'task_status_changed':
        // Navigate to project detail with highlighted ticket
        final projectId = notification.data['projectId'];
        final taskId = notification.data['taskId'];
        if (projectId != null && taskId != null) {
          try {
            final project = await _firestoreService.getProjectById(projectId);
            if (project != null && mounted) {
              // Navigate to project detail page with highlight
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectDetailPage(
                    project: project,
                    highlightTicketId: taskId,
                  ),
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
                SnackBar(content: Text('Error loading ticket: $e')),
              );
            }
          }
        }
        break;

      case 'wishlist_invitation':
      case 'wishlist_update':
        // Navigate to wishlist page and show modal immediately
        final wishlistId = notification.data['wishlistId'];
        if (wishlistId != null && mounted) {
          // Navigate to wishlist page with modal popup
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WishlistPage(showModalForWishId: wishlistId),
            ),
          );
        } else if (mounted) {
          // Navigate to wishlist page without modal
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WishlistPage()),
          );
        }
        break;

      case 'wishlist_removal':
        // Just navigate to wishlist page without any modal
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
