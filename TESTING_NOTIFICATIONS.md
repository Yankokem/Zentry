# Notification System Testing Guide

## Quick Start

The notification system has been fully integrated into Zentry. Follow these steps to test all functionality:

## 1. Enable Test Notification Button (Optional)

To easily create test notifications during development:

1. Open `lib/core/views/home_page.dart`
2. Uncomment line 8: 
   ```dart
   import 'package:zentry/core/widgets/test_notification_button.dart';
   ```
3. Uncomment line 1296:
   ```dart
   floatingActionButton: const TestNotificationButton(),
   ```
4. Hot reload the app
5. You'll see a floating button with a bell icon on the home screen
6. Tap it to create different types of test notifications instantly

## 2. Test Firestore Rules

Before creating notifications, make sure Firestore security rules are deployed:

### Deploy Rules (if needed)

```bash
firebase deploy --only firestore:rules
```

### Verify Rules

The notification rules in `firestore.rules` allow:
- ✅ Users can read their own notifications
- ✅ Users can update `isRead` field only
- ✅ Users can delete their own notifications
- ✅ Users can create notifications (for development)

## 3. Test Each Notification Type

### A. Task Assignment Notifications

1. **Create a project** with team members
2. **Create a new task** in that project
3. **Assign the task** to another team member
4. **Expected**: The assigned user receives "New Task Assignment" notification
5. **Verify**:
   - Badge appears on notification bell
   - Notification shows in feed with correct title and body
   - Tapping notification navigates to project details

### B. Wishlist Update Notifications

1. **Create a wishlist item**
2. **Share it** with another user (add their email)
3. **Save the item**
4. **Expected**: Shared user receives "Shared Wishlist Update" notification
5. **Verify**:
   - Notification shows "added" action
   - Tapping navigates to wishlist page
   
6. **Edit the shared item**
7. **Expected**: Shared user receives notification with "updated" action

### C. Test Notification Button (Quick Testing)

1. Tap the floating test notification button
2. Select notification type to create:
   - Task Assigned
   - Project Invitation
   - Task Deadline
   - Wishlist Update
   - Journal Milestone
3. **Expected**: Notification appears immediately in feed
4. **Verify all features**:
   - Unread badge on bell icon
   - Notification appears in appropriate date group
   - Unread visual indicators (blue tint, left border, dot)
   - Time ago display ("Just now", "2h ago", etc.)

## 4. Test Notification Features

### Read/Unread States

1. Open notifications screen
2. **Verify unread notifications** have:
   - Blue background tint (light mode) or white tint (dark mode)
   - Colored left border
   - Blue dot in trailing position
   - Bold title text
   
3. **Tap a notification**
4. **Expected**:
   - Background tint disappears
   - Left border becomes transparent
   - Dot disappears
   - Title becomes normal weight
   - Badge count decreases

### Mark All as Read

1. Have multiple unread notifications
2. **Tap "Mark all read"** button in app bar
3. **Expected**:
   - All notifications become read
   - Badge counter disappears
   - Success snackbar appears
   - All visual unread indicators disappear

### Swipe to Delete

1. **Swipe left** on any notification
2. **Expected**:
   - Red delete background appears
   - Notification is deleted
   - Success snackbar with undo option appears
   - Notification count updates

### Navigation from Notifications

1. **Tap project-related notification**
   - Should navigate to ProjectDetailPage
   - Project should be loaded correctly
   
2. **Tap task-related notification**
   - Should navigate to ProjectDetailPage with that project
   
3. **Tap wishlist notification**
   - Should navigate to WishlistPage
   
4. **Tap journal milestone**
   - Should navigate to JournalPage

### Date Grouping

1. Create notifications on different days
2. **Expected groups**:
   - Today (notifications from today)
   - Yesterday (notifications from yesterday)
   - This Week (notifications from last 7 days)
   - Earlier (older notifications)

### Real-time Updates

1. Have notifications screen open
2. Create new notification from another device/browser
3. **Expected**: Notification appears instantly without refresh

### Badge Counter

1. **Check home page** notification bell icon
2. **Expected**:
   - Badge shows unread count
   - Badge disappears when all marked as read
   - Badge updates in real-time
   - Shows "9+" when count > 9

## 5. Test Error Handling

### No Notifications

1. Delete all notifications from Firestore
2. Open notifications screen
3. **Expected**:
   - Empty state with bell icon
   - "No notifications yet" message
   - Helpful description text

### Firestore Error

1. Disconnect from internet
2. Open notifications screen
3. **Expected**:
   - Error icon displayed
   - "Error loading notifications" message
   - Retry button shown
   - Error details displayed

4. **Tap Retry**
5. **Expected**: Attempts to reload

### Navigation Error

1. Create notification with invalid project ID
2. Tap the notification
3. **Expected**:
   - "Project not found" snackbar
   - No navigation occurs
   - No crash

## 6. Production Workflow Testing

### Task Assignment Flow

1. **User A** creates a project
2. **User A** adds **User B** to team
3. **User A** creates task
4. **User A** assigns task to **User B**
5. **User B** opens app
6. **Expected**:
   - User B sees badge on notification bell
   - User B sees "New Task Assignment" notification
   - User B taps notification → navigates to project
   - User B can see the assigned task

### Wishlist Sharing Flow

1. **User A** creates wishlist item
2. **User A** adds **User B**'s email to shared members
3. **User A** saves item
4. **User B** opens app
5. **Expected**:
   - User B sees "Shared Wishlist Update" notification
   - Notification says "User A added 'Item Title'"
   - Tapping navigates to wishlist page

## 7. Performance Testing

### Load Testing

1. Create 50+ notifications
2. Open notifications screen
3. **Expected**:
   - Loads within 2 seconds
   - Smooth scrolling
   - No lag when marking as read
   - Proper pagination (limit 50 shown)

### Stream Performance

1. Keep notifications screen open
2. Create notifications from another device
3. **Expected**:
   - New notifications appear instantly
   - No performance degradation
   - Scroll position maintained

## 8. Edge Cases

### Empty Email Assignments

1. Create task without assignees
2. **Expected**: No notifications sent

### Self-Assignment

1. Assign task to yourself
2. **Expected**: No notification sent to self

### Duplicate Notifications

1. Edit same task multiple times quickly
2. **Expected**: Multiple notifications created (correct behavior)

### Deleted Projects

1. Create notification for a project
2. Delete that project
3. Tap notification
4. **Expected**: "Project not found" message

## 9. Cleanup After Testing

### Remove Test Button

After testing is complete:

1. Comment out test button import in `home_page.dart`
2. Comment out `floatingActionButton` line
3. Hot reload

### Clear Test Notifications

Option 1: Delete from Firebase Console
- Go to Firestore → notifications collection
- Delete test documents

Option 2: Swipe to delete in app
- Open notifications screen
- Swipe left on each test notification

## 10. Verification Checklist

Before considering testing complete:

- [ ] Task assignment notifications work
- [ ] Wishlist update notifications work
- [ ] Project invitation notifications work (if implemented)
- [ ] Navigation works for all notification types
- [ ] Badge counter updates correctly
- [ ] Mark as read works (single and bulk)
- [ ] Swipe to delete works
- [ ] Date grouping is accurate
- [ ] Empty state displays correctly
- [ ] Error state displays with retry
- [ ] Real-time updates work
- [ ] Unread visual indicators display correctly
- [ ] Notifications persist after app restart
- [ ] Firestore security rules prevent unauthorized access

## 11. Known Limitations

1. **Task highlighting not implemented** - Tapping task notifications navigates to project but doesn't highlight the specific task
2. **No push notifications** - Only in-app notifications (Firebase Cloud Messaging not integrated)
3. **No deadline checking** - Requires background job/Cloud Function to check approaching/overdue tasks
4. **Project invitation notifications** - Only triggered when creating tasks, not when adding team members directly
5. **Notification limit** - Only 50 most recent notifications shown per user

## 12. Troubleshooting

### Notifications not appearing?

**Check:**
1. User is signed in with valid Firebase Auth
2. Firestore rules allow read/write to notifications collection
3. User ID matches in notification document
4. Internet connection is active
5. Console for any error messages

### Badge not updating?

**Check:**
1. Stream subscription is active
2. User ID is not null in home_page.dart
3. Firestore query has proper index
4. Check browser/app console for errors

### Navigation not working?

**Check:**
1. Project/wishlist ID exists in notification data
2. Firestore document for that ID exists
3. User has permission to access that resource
4. Route navigation code is uncommented

### "Error loading notifications" message?

**Check:**
1. Firestore rules allow reading notifications
2. Internet connection
3. Firebase project configuration is correct
4. Check specific error message in debug output

## Success Criteria

✅ All notification types can be created and displayed
✅ Real-time updates work smoothly
✅ Navigation from notifications works correctly
✅ Badge counter is accurate
✅ Read/unread states work properly
✅ Security rules protect user data
✅ No errors in production build
✅ Performance is acceptable with 50+ notifications

---

**Status**: ✅ All core features implemented and ready for testing
**Last Updated**: December 7, 2024
