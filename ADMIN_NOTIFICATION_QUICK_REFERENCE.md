# Admin Notification System - Quick Reference

## 🚀 Getting Started

### View Notifications
1. Open Admin Dashboard
2. Click the bell icon (top right)
3. View all notifications with unread count badge

### Manage Notifications
- **Mark as Read:** Swipe right on notification
- **Delete:** Swipe left on notification
- **Mark All Read:** Tap "✓✓" icon in app bar
- **Clear Read:** Tap "Clear All" icon in app bar
- **Filter:** Use filter menu (funnel icon)

## 📝 Currently Active Notifications

| Event | Priority | Trigger Location | Details |
|-------|----------|------------------|---------|
| **New User** | Low | `SignupController`, `GoogleSignInController` | Email + Google signups |
| **Bug Report** | Normal/High | `BugReportService.submitBugReport()` | High if Critical category |
| **Bug Status Change** | Low | `BugReportService.updateBugReportStatus()` | Shows old → new status |
| **New Appeal** | High | `AccountAppealService.submitAppeal()` | Regular user appeals |
| **Urgent Appeal** | Urgent | `AccountAppealService.submitAppeal()` | Suspended/banned user appeals |

## 🔧 Adding New Notification Types

### Step 1: Add Enum Value
```dart
// In admin_notification_model.dart
enum AdminNotificationType {
  // ... existing types
  yourNewType,  // Add here
}
```

### Step 2: Add Icon
```dart
// In admin_notification_model.dart, getIconForType()
case AdminNotificationType.yourNewType:
  return '🆕';  // Choose appropriate emoji
```

### Step 3: Add Trigger Method
```dart
// In admin_notification_service.dart
Future<void> notifyYourNewType({
  required String param1,
  required String param2,
}) async {
  await createNotification(
    title: 'Your Title',
    message: 'Your message with $param1',
    type: AdminNotificationType.yourNewType,
    priority: AdminNotificationPriority.normal,
    metadata: {
      'param1': param1,
      'param2': param2,
    },
    actionUrl: '/admin/your-route',
  );
}
```

### Step 4: Call Trigger
```dart
// In your service where event occurs
final adminNotificationService = AdminNotificationService();
await adminNotificationService.notifyYourNewType(
  param1: 'value1',
  param2: 'value2',
);
```

## 📊 Notification Priority Guide

| Priority | When to Use | Example |
|----------|-------------|---------|
| **Low** | Informational, can wait | User registrations, status changes |
| **Normal** | Standard admin action needed | Regular bug reports, user feedback |
| **High** | Important, review soon | Account appeals, high-severity bugs |
| **Urgent** | Critical, immediate attention | Suspended user appeals, security alerts |

## 🗄️ Firestore Collection

**Collection Name:** `admin_notifications`

**Query Examples:**
```dart
// Get all notifications
_service.getNotificationsStream()

// Get only unread
_service.getNotificationsStream(onlyUnread: true)

// Get high priority and above
_service.getNotificationsStream(minPriority: AdminNotificationPriority.high)

// Get specific type
_service.getNotificationsStream(type: AdminNotificationType.newBugReport)

// Get unread count
_service.getUnreadCountStream()
```

## 🎯 Navigation URLs

| Entity | URL Pattern | Example |
|--------|-------------|---------|
| User | `/admin/users/{userId}` | `/admin/users/abc123` |
| Bug Report | `/admin/bug-reports/{bugReportId}` | `/admin/bug-reports/xyz789` |
| Appeal | `/admin/appeals/{appealId}` | `/admin/appeals/def456` |

## 🔮 Future Enhancements Ready

### Push Notifications
```dart
// In AdminNotificationService.createNotification()
// After Firestore save:
if (priority >= AdminNotificationPriority.high) {
  await _sendPushToAdminDevices(notification);
}
```

### Email Notifications
```dart
// In AdminNotificationService.createNotification()
// After Firestore save:
if (priority == AdminNotificationPriority.urgent) {
  await _sendEmailToAdmins(notification);
}
```

## 🐛 Troubleshooting

### Notifications not showing?
1. Check Firestore Rules allow admin access to `admin_notifications`
2. Verify current user has `isAdmin: true` in Firestore
3. Check browser console for errors
4. Verify service methods are called (check debug logs)

### Navigation not working?
1. Ensure routes exist in app router
2. Verify `actionUrl` format matches route pattern
3. Check entity IDs are valid

### Count badge not updating?
1. Check `getUnreadCountStream()` is subscribed
2. Verify Firestore writes are successful
3. Check network connection

## 📚 Documentation Files

- **ADMIN_NOTIFICATION_SYSTEM.md** - Complete system documentation
- **ADMIN_NOTIFICATION_IMPLEMENTATION_SUMMARY.md** - Implementation details
- **This file** - Quick reference guide

## ✅ Testing Checklist

Quick tests to verify system:
- [ ] Register user → See "New User" notification
- [ ] Submit bug → See "New Bug Report" notification  
- [ ] Change bug status → See "Bug Updated" notification
- [ ] Submit appeal → See "New Appeal" notification
- [ ] Swipe right → Notification marked as read
- [ ] Tap notification → Navigate to content
- [ ] Check badge → Shows correct unread count

## 🎨 UI Customization

### Change Priority Colors
```dart
// In admin_notifications_screen.dart, _getPriorityColor()
Color _getPriorityColor(AdminNotificationPriority priority) {
  switch (priority) {
    case AdminNotificationPriority.urgent:
      return Colors.red;  // Change to your color
    // ...
  }
}
```

### Change Icons
```dart
// In admin_notification_model.dart, getIconForType()
static String getIconForType(AdminNotificationType type) {
  switch (type) {
    case AdminNotificationType.newUser:
      return '👤';  // Change to your emoji
    // ...
  }
}
```

## 💡 Pro Tips

1. **Use metadata wisely** - Store any data you might need in the UI
2. **Keep messages concise** - Users scan notifications quickly
3. **Choose priority carefully** - Too many urgent notifications = notification fatigue
4. **Provide actionUrl** - Let admins navigate directly to content
5. **Clean up old notifications** - Implement auto-cleanup for read notifications older than 30 days

## 🔗 Key Files Quick Access

- Model: `lib/features/admin/models/admin_notification_model.dart`
- Service: `lib/features/admin/services/admin_notification_service.dart`
- UI: `lib/features/admin/views/admin_notifications_screen.dart`
- Dashboard Integration: `lib/features/admin/views/admin_dashboard.dart`

---

**System Status:** ✅ Production Ready  
**Version:** 1.0  
**Last Updated:** 2024
