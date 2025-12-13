# Admin Notification System Documentation

## Overview
The Admin Notification System provides real-time notifications to administrators about important events in the Zentry app. The system is designed to be extensible and supports future enhancements for push notifications and email delivery.

## Architecture

### Components

#### 1. AdminNotificationModel
**Location:** `lib/features/admin/models/admin_notification_model.dart`

Defines the data structure for admin notifications.

**Notification Types:**
- `newUser` - New user registration
- `newBugReport` - New bug report submitted
- `bugReportStatusChange` - Bug report status changed
- `newAppeal` - New account appeal submitted
- `urgentAppeal` - Appeal requiring immediate attention (suspended/banned users)
- `userMilestone` - User reached a milestone
- `appMilestone` - App reached a milestone
- `securityAlert` - Security-related events
- `systemHealth` - System health issues
- `criticalError` - Critical errors
- `unusualActivity` - Unusual patterns detected
- `userFeedback` - User feedback submitted
- `accountAction` - Account actions (suspension, ban, activation)

**Priority Levels:**
- `low` - Can be reviewed later
- `normal` - Regular importance
- `high` - Should be reviewed soon
- `urgent` - Requires immediate attention

**Fields:**
- `id` - Unique identifier
- `title` - Notification title
- `message` - Notification message
- `type` - Notification type (enum)
- `priority` - Priority level (enum)
- `metadata` - Additional contextual data (Map)
- `createdAt` - Creation timestamp
- `isRead` - Read status
- `actionUrl` - Deep link or route for action
- `userId` - Related user ID (if applicable)
- `relatedEntityId` - ID of related entity (bug report, appeal, etc.)

#### 2. AdminNotificationService
**Location:** `lib/features/admin/services/admin_notification_service.dart`

Manages notification creation, retrieval, and updates.

**Key Methods:**

**Data Management:**
- `createNotification()` - Create a new notification
- `getNotificationsStream()` - Stream all notifications with optional filters
- `getUnreadCountStream()` - Stream of unread notification count
- `markAsRead()` - Mark single notification as read
- `markAllAsRead()` - Mark all notifications as read
- `deleteNotification()` - Delete a single notification
- `deleteAllRead()` - Delete all read notifications

**Trigger Methods (called automatically by other services):**
- `notifyNewUser()` - Notify of new user registration
- `notifyNewBugReport()` - Notify of new bug report
- `notifyBugReportStatusChange()` - Notify of bug status change
- `notifyNewAppeal()` - Notify of new appeal
- `notifyUrgentAppeal()` - Notify of urgent appeal
- `notifyUserMilestone()` - Notify of user milestone
- `notifyAppMilestone()` - Notify of app milestone
- `notifySecurityAlert()` - Notify of security alert
- `notifyAccountAction()` - Notify of account action

#### 3. AdminNotificationsScreen
**Location:** `lib/features/admin/views/admin_notifications_screen.dart`

User interface for viewing and managing notifications.

**Features:**
- Real-time notification stream
- Swipe to mark as read (swipe right)
- Swipe to delete (swipe left)
- Filter by priority
- Filter by type
- Mark all as read
- Clear all read notifications
- Unread indicator styling
- Priority badges
- Emoji icons for notification types
- Relative timestamps (e.g., "5 minutes ago")
- Tap to navigate to related content

## Notification Triggers

### 1. New User Registration
**Triggered in:**
- `SignupController.signup()` - Email/password signup
- `GoogleSignInController.signUpWithGoogleAndCheckExisting()` - Google signup

**Priority:** Low
**Navigation:** `/admin/users/{userId}`

### 2. New Bug Report
**Triggered in:**
- `BugReportService.submitBugReport()`

**Priority:** 
- High (if category is "Critical" or "High")
- Normal (otherwise)

**Navigation:** `/admin/bug-reports/{bugReportId}`

### 3. Bug Report Status Change
**Triggered in:**
- `BugReportService.updateBugReportStatus()`

**Priority:** Low
**Navigation:** `/admin/bug-reports/{bugReportId}`

### 4. New Appeal
**Triggered in:**
- `AccountAppealService.submitAppeal()`

**Priority:** High (normal appeals) or Urgent (suspended/banned users)
**Navigation:** `/admin/appeals/{appealId}`

**Urgent Detection:**
Appeals are marked as urgent if the user's `accountStatus` field contains "suspend" or "ban".

## Firebase Collection

**Collection:** `admin_notifications`

**Document Structure:**
```json
{
  "title": "New User Registration",
  "message": "John Doe (john@example.com) just registered",
  "type": "newUser",
  "priority": "low",
  "metadata": {
    "userName": "John Doe",
    "userEmail": "john@example.com"
  },
  "createdAt": "2024-01-15T10:30:00Z",
  "isRead": false,
  "actionUrl": "/admin/users/abc123",
  "userId": "abc123",
  "relatedEntityId": null
}
```

## Integration Points

### Dashboard Integration
The admin dashboard displays an unread notification badge:

**Location:** `lib/features/admin/views/admin_dashboard.dart`

```dart
StreamBuilder<int>(
  stream: _notificationService.getUnreadCountStream(),
  builder: (context, snapshot) {
    final unreadCount = snapshot.data ?? 0;
    // ... displays badge with count
  },
)
```

### Service Integration
Services automatically trigger notifications:

```dart
// In SignupController
final adminNotificationService = AdminNotificationService();
await adminNotificationService.notifyNewUser(
  userId: userId,
  userName: fullName,
  userEmail: email,
);
```

## Future Enhancements

### Push Notifications
The notification system is designed to support push notifications:

1. Add FCM tokens to admin user documents
2. In `AdminNotificationService.createNotification()`, send push notification to all admin devices
3. Use Firebase Cloud Messaging for delivery
4. Store notification payload in `metadata` field

**Suggested Implementation:**
```dart
// After creating notification in Firestore
if (priority >= AdminNotificationPriority.high) {
  await _sendPushNotification(notification);
}
```

### Email Notifications
Email notifications can be added similarly:

1. Store admin email preferences in Firestore
2. In `AdminNotificationService.createNotification()`, send email for urgent notifications
3. Use Firebase Cloud Functions or SendGrid

**Suggested Implementation:**
```dart
// After creating notification in Firestore
if (priority == AdminNotificationPriority.urgent) {
  await _sendEmailNotification(notification);
}
```

### Additional Notification Types
The system can easily be extended with new notification types:

1. Add new enum value to `AdminNotificationType`
2. Add corresponding trigger method in `AdminNotificationService`
3. Update `getIconForType()` with appropriate emoji
4. Call trigger method from relevant service

**Example - Content Moderation:**
```dart
// In AdminNotificationType enum
contentReported,  // User reported inappropriate content

// In AdminNotificationService
Future<void> notifyContentReported({
  required String contentId,
  required String contentType,
  required String reportReason,
}) async {
  await createNotification(
    title: 'Content Reported',
    message: 'User reported $contentType: $reportReason',
    type: AdminNotificationType.contentReported,
    priority: AdminNotificationPriority.high,
    relatedEntityId: contentId,
  );
}
```

## Testing

### Manual Testing
1. **New User Registration:**
   - Register a new user via email/password or Google
   - Check admin notifications screen for "New User Registration" notification

2. **Bug Reports:**
   - Submit a bug report as a user
   - Check for "New Bug Report" notification
   - Update bug status as admin
   - Check for "Bug Report Updated" notification

3. **Appeals:**
   - Submit an appeal as a regular user
   - Check for "New Account Appeal" notification (High priority)
   - Submit an appeal as a suspended user
   - Check for "🚨 Urgent Appeal" notification (Urgent priority)

4. **Notification Actions:**
   - Swipe right to mark as read
   - Swipe left to delete
   - Tap notification to navigate to related content
   - Use filter options
   - Mark all as read
   - Clear read notifications

### Firestore Rules
Ensure Firestore rules allow admins to read/write notifications:

```javascript
match /admin_notifications/{notificationId} {
  allow read, write: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
}
```

## Best Practices

1. **Always provide actionUrl:** This enables navigation to related content
2. **Use appropriate priority:** Urgent should be rare and only for critical items
3. **Include contextual metadata:** Helps admins make decisions without navigating
4. **Keep messages concise:** Titles should be 3-5 words, messages 1-2 sentences
5. **Use descriptive notification types:** Easier to filter and search
6. **Clean up read notifications:** Implement periodic cleanup to avoid clutter

## Troubleshooting

### Notifications not appearing
1. Check Firestore console for `admin_notifications` collection
2. Verify user has `isAdmin: true` in Firestore
3. Check Firestore rules allow admin access
4. Check browser console for errors
5. Verify service methods are being called (check debug prints)

### Navigation not working
1. Ensure routes are registered in app router
2. Verify `actionUrl` matches route pattern
3. Check entity IDs are correct

### Priority not displaying correctly
1. Verify priority is set in trigger method
2. Check color mapping in `_getPriorityColor()`
3. Ensure priority enum values are correct

## Summary

The Admin Notification System provides:
- ✅ Real-time notifications for admin events
- ✅ Priority-based notification management
- ✅ Rich metadata and context
- ✅ Navigation to related content
- ✅ Filtering and searching
- ✅ Mark as read/unread
- ✅ Extensible architecture for push/email
- ✅ Clean, intuitive UI with swipe gestures
- ✅ Automatic triggers throughout the app

The system is production-ready and can be extended with additional notification types, delivery methods, and features as needed.
