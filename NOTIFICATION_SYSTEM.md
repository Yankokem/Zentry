# Notification System Documentation

## Overview

The Zentry notification system provides real-time activity notifications to users about important events across projects, tasks, wishlist items, and journals. The system consists of:

1. **NotificationManager** - Service for creating and managing notifications
2. **NotificationsScreen** - Activity feed UI with read/unread states
3. **Badge Counter** - Unread notification count on the notification bell icon

## Features

### ✅ Implemented

- **Real-time notification stream** from Firestore
- **Activity feed UI** with grouped notifications (Today, Yesterday, This Week, Earlier)
- **Unread badge** on notification bell icon
- **Mark as read** functionality (single and bulk)
- **Swipe to delete** notifications
- **Color-coded notification types** with custom icons
- **Time ago display** (e.g., "2h ago", "3d ago")
- **Empty state** UI when no notifications exist

### 📋 Notification Types

The system supports 9 notification types:

1. **project_invitation** - When added to a project team
2. **task_assigned** - When assigned a new task
3. **task_deadline** - When task deadline is approaching (1 day before)
4. **task_overdue** - When task becomes overdue
5. **task_status_changed** - When task status is updated
6. **wishlist_update** - When someone updates a shared wishlist
7. **journal_milestone** - Achievement milestones (entry count, streaks)
8. **project_milestone** - Project completion milestones (50%, 90%, 100%)
9. **project_status_changed** - When project status is updated

## How to Use

### Creating Notifications

Import the NotificationManager:

```dart
import 'package:zentry/core/services/firebase/notification_manager.dart';

final notificationManager = NotificationManager();
```

### Example: Notify Task Assignment

```dart
// When assigning a task to a user
await notificationManager.notifyTaskAssigned(
  recipientUserId: 'user123',
  taskTitle: 'Fix login bug',
  projectTitle: 'Mobile App',
  taskId: 'task456',
  projectId: 'project789',
  assignerName: 'John Doe',
);
```

### Example: Notify Project Invitation

```dart
// When adding a user to a project
await notificationManager.notifyProjectInvitation(
  recipientUserId: 'user123',
  projectTitle: 'Website Redesign',
  projectId: 'project456',
  inviterName: 'Jane Smith',
);
```

### Example: Notify Deadline Approaching

```dart
// Run this as a scheduled task (daily check)
await notificationManager.notifyTaskDeadlineApproaching(
  userId: 'user123',
  taskTitle: 'Submit proposal',
  projectTitle: 'Client Project',
  taskId: 'task789',
  projectId: 'project123',
  deadline: DateTime(2024, 12, 31, 17, 0),
);
```

### Example: Notify Wishlist Update

```dart
// When someone updates a shared wishlist
await notificationManager.notifyWishlistUpdate(
  recipientUserId: 'user123',
  wishlistTitle: 'Birthday Wishlist',
  wishlistId: 'wishlist456',
  updaterName: 'Sarah Connor',
  action: 'completed', // 'added', 'completed', 'updated'
);
```

### Example: Journal Milestone

```dart
// When user reaches entry milestone
await notificationManager.notifyJournalMilestone(
  userId: 'user123',
  milestoneType: 'entry_count', // 'entry_count', 'streak', 'week'
  count: 10,
);
```

## Integration Points

### Where to Add Notification Triggers

#### 1. **Project Service** (when creating/updating projects)

```dart
// In lib/core/services/firebase/firestore_service.dart

// After adding team member to project
await notificationManager.notifyProjectInvitation(
  recipientUserId: newMemberId,
  projectTitle: project.title,
  projectId: project.id,
  inviterName: currentUserName,
);

// After changing project status
for (var memberId in project.teamMembers) {
  if (memberId != currentUserId) {
    await notificationManager.notifyProjectStatusChanged(
      recipientUserId: memberId,
      projectTitle: project.title,
      projectId: project.id,
      newStatus: newStatus,
      changedByName: currentUserName,
    );
  }
}
```

#### 2. **Ticket/Task Management** (when creating/updating tasks)

```dart
// In lib/features/projects/views/add_ticket_page.dart

// After creating task with assignee
if (assignedUserId != null && assignedUserId != currentUserId) {
  await notificationManager.notifyTaskAssigned(
    recipientUserId: assignedUserId,
    taskTitle: ticket.title,
    projectTitle: projectTitle,
    taskId: ticket.id,
    projectId: projectId,
    assignerName: currentUserName,
  );
}

// After changing task status
if (ticket.assignedTo != null && ticket.assignedTo != currentUserId) {
  await notificationManager.notifyTaskStatusChanged(
    recipientUserId: ticket.assignedTo!,
    taskTitle: ticket.title,
    projectTitle: projectTitle,
    newStatus: newStatus,
    taskId: ticket.id,
    projectId: projectId,
    changedByName: currentUserName,
  );
}
```

#### 3. **Wishlist Service** (when sharing/updating items)

```dart
// In lib/features/wishlist/views/add_wishlist_screen.dart

// After adding/updating shared wishlist item
for (var sharedUserId in wish.sharedWith) {
  if (sharedUserId != currentUserId) {
    await notificationManager.notifyWishlistUpdate(
      recipientUserId: sharedUserId,
      wishlistTitle: wish.title,
      wishlistId: wish.id,
      updaterName: currentUserName,
      action: isEditing ? 'updated' : 'added',
    );
  }
}
```

#### 4. **Background Jobs** (scheduled tasks for deadlines)

Create a background service or Cloud Function to check for:

- Tasks due within 24 hours → `notifyTaskDeadlineApproaching()`
- Tasks past deadline → `notifyTaskOverdue()`
- Journal entry streaks → `notifyJournalMilestone()`
- Project completion percentages → `notifyProjectMilestone()`

## UI Components

### Notification Badge

The notification bell icon displays an unread count badge:

```dart
StreamBuilder<int>(
  stream: NotificationManager().getUnreadCountStream(userId),
  builder: (context, snapshot) {
    final unreadCount = snapshot.data ?? 0;
    // Display badge if unreadCount > 0
  },
)
```

### Notifications Screen

Navigate to notifications:

```dart
Navigator.pushNamed(context, AppRoutes.notifications);
```

Features:
- **Grouped by date** - Today, Yesterday, This Week, Earlier
- **Color-coded icons** - Each notification type has unique color and icon
- **Read/Unread states** - Unread notifications have left border and background tint
- **Swipe to delete** - Swipe left to delete a notification
- **Mark all as read** - Button in app bar when unread notifications exist
- **Tap to navigate** - Tap notification to navigate to related content (TODO: implement navigation)

## Data Model

Notifications are stored in Firestore collection `notifications`:

```json
{
  "userId": "user123",
  "title": "New Task Assignment",
  "body": "John Doe assigned you 'Fix login bug' in Mobile App",
  "type": "task_assigned",
  "data": {
    "taskId": "task456",
    "projectId": "project789",
    "taskTitle": "Fix login bug",
    "projectTitle": "Mobile App"
  },
  "isRead": false,
  "createdAt": "2024-01-15T10:30:00Z"
}
```

## Next Steps (TODO)

### 1. **Implement Navigation Handlers**

Currently, tapping notifications shows a placeholder SnackBar. Update `_handleNotificationTap()` in `notifications_screen.dart`:

```dart
case 'task_assigned':
  // Navigate to project details with task highlighted
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProjectDetailPage(
        projectId: notification.data['projectId'],
        highlightTaskId: notification.data['taskId'],
      ),
    ),
  );
  break;
```

### 2. **Add Notification Triggers**

Integrate notification creation into your existing services:

- ✅ Project invitations
- ✅ Task assignments
- ✅ Task status changes
- ✅ Deadline reminders
- ✅ Wishlist updates
- ✅ Journal milestones
- ✅ Project milestones

### 3. **Background Job for Deadline Checks**

Create a Cloud Function or background service to:

- Check daily for tasks due within 24 hours
- Mark overdue tasks and notify users
- Calculate and notify project completion milestones
- Track journal streaks and milestones

### 4. **Push Notifications (Optional)**

Integrate Firebase Cloud Messaging for push notifications:

- Set up FCM tokens
- Send push notifications for critical events
- Link push notifications to in-app notifications

### 5. **Notification Preferences**

Allow users to customize which notifications they receive:

- Task reminders ON/OFF
- Project updates ON/OFF
- Wishlist updates ON/OFF
- Journal milestones ON/OFF
- Email notifications ON/OFF

## Testing

### Manual Testing

1. **Create a test notification**:

```dart
// In any screen, add a test button:
await NotificationManager().notifyTaskAssigned(
  recipientUserId: FirebaseAuth.instance.currentUser!.uid,
  taskTitle: 'Test Task',
  projectTitle: 'Test Project',
  taskId: 'test123',
  projectId: 'test456',
  assignerName: 'Test User',
);
```

2. **Navigate to notifications screen** - Should see the new notification
3. **Check badge count** - Should show "1" on the bell icon
4. **Tap notification** - Should mark as read and show navigation message
5. **Swipe to delete** - Should remove notification
6. **Test "Mark all as read"** - Should clear all unread states

### Test Scenarios

- ✅ Empty state displays when no notifications
- ✅ Notifications group by date correctly
- ✅ Unread badge appears and updates in real-time
- ✅ Mark as read works on tap
- ✅ Mark all as read button appears when unread exist
- ✅ Swipe to delete removes notification
- ✅ Different notification types show correct icons and colors
- ✅ Time ago display is accurate

## Troubleshooting

### Notifications not appearing?

1. Check Firestore rules allow read/write to `notifications` collection
2. Verify userId is correctly set when creating notifications
3. Check that `createdAt` field uses `FieldValue.serverTimestamp()`

### Badge count not updating?

1. Ensure `_currentUserId` is not null in `home_page.dart`
2. Check Firestore query has index for `userId` and `isRead` fields
3. Verify stream subscription is active

### Navigation not working?

The navigation handlers in `_handleNotificationTap()` are currently placeholders showing SnackBars. You need to implement actual navigation to your existing screens with the correct parameters.

## Security

### Firestore Rules

Add these rules to allow users to read their own notifications:

```javascript
match /notifications/{notificationId} {
  allow read: if request.auth != null && 
    resource.data.userId == request.auth.uid;
  
  allow update: if request.auth != null && 
    resource.data.userId == request.auth.uid &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead']);
  
  allow delete: if request.auth != null && 
    resource.data.userId == request.auth.uid;
  
  // Only server can create notifications (via Cloud Functions)
  allow create: if false;
}
```

For development, you can temporarily allow creates from client:

```javascript
allow create: if request.auth != null;
```

## Performance Considerations

- Notifications are limited to 50 per user (most recent)
- Firestore indexes required for `userId` + `createdAt` + `isRead`
- Consider archiving old notifications after 30 days
- Use pagination if notification count grows significantly

---

**Status**: ✅ Core notification system implemented and ready for integration
**Files Modified**: 
- `lib/core/services/firebase/notification_manager.dart` (created)
- `lib/features/profile/views/notifications_screen.dart` (replaced)
- `lib/core/views/home_page.dart` (added badge)
