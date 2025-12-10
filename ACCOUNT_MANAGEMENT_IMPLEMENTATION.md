# Account Management System - Implementation Guide

## Overview
This document describes the Firebase-integrated account management system for admin users in Zentry.

## Features Implemented

### 1. **Account Management Page** (`admin_accounts.dart`)
- ✅ **Search functionality**: Search users by name or email
- ✅ **Filter tabs with status colors**: 
  - Active (Green)
  - Suspended (Orange)
  - Banned (Red)
- ✅ **Real Firebase integration**: Replaced test data with live Firebase queries
- ✅ **Pull-to-refresh**: Reload user data by pulling down
- ✅ **Click to view details**: Tap any user to see their full profile
- ✅ **Action menu**: Suspend, ban, or activate users directly from the list

### 2. **User Detail Screen** (`user_detail_screen.dart`)
- ✅ **Profile card**: Shows user photo, name, email, role, and status
- ✅ **Activity statistics**: 
  - Journal entries count
  - Projects count
  - Tickets count
  - Wishlists count
- ✅ **Account information**: 
  - Member since date
  - Last active time
  - Phone number
  - Country
  - Shared projects and wishlists
- ✅ **Admin actions**: Suspend, ban, activate, promote/demote users
- ✅ **Suspension/ban details**: Shows reason and duration if applicable

### 3. **Firebase Backend** (`admin_service.dart`)
New methods added to AdminService:

#### User Management
- `getAllUsers()` - Fetch all users with their metadata
- `getUserStatistics(userId)` - Get detailed user stats and activity
- `updateUserStatus()` - Change user status (active/suspended/banned)
- `updateUserRole()` - Promote/demote users (admin/member)
- `initializeUserMetadata()` - Create metadata for new users
- `updateLastActive()` - Track user activity
- `isUserAdmin()` - Check if a specific user is admin
- `getUserMetadata()` - Get user's administrative metadata

### 4. **Firebase Collections**

#### `user_metadata` Collection
Stores administrative data for each user:
```javascript
{
  role: 'member' | 'admin',
  status: 'active' | 'suspended' | 'banned',
  lastActive: Timestamp,
  suspensionReason: string (optional),
  suspensionDuration: string (optional),
  banReason: string (optional),
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

## Usage Instructions

### For Admins

#### Viewing Users
1. Navigate to Admin Dashboard
2. Go to "Accounts" tab
3. Use filter tabs to view Active, Suspended, or Banned users
4. Use search bar to find specific users by name or email

#### Viewing User Details
1. Tap on any user card
2. View their complete profile and statistics
3. See suspension/ban details if applicable

#### Suspending a User
1. Click user or use action menu (⋮)
2. Select "Suspend User"
3. Enter reason and select duration
4. Confirm suspension

#### Banning a User
1. Click user or use action menu (⋮)
2. Select "Ban User"
3. Enter ban reason
4. Confirm ban

#### Activating a User
1. Find suspended/banned user
2. Click user or use action menu (⋮)
3. Select "Activate"
4. Confirm activation

#### Promoting/Demoting Users
1. Open user detail screen
2. Click menu (⋮) in top-right
3. Select "Promote to Admin" or "Demote to Member"
4. Confirm action

### For Developers

#### Integrating User Metadata in Auth Flow

The system automatically initializes user metadata when users sign up. This is already integrated in:
- `signup_controller.dart` - Email/password signup
- `google_signin_controller.dart` - Google sign-in
- `login_controller.dart` - Fallback for existing auth users

#### Tracking User Activity

To update a user's last active timestamp:
```dart
final adminService = AdminService();
await adminService.updateLastActive(userId);
```

Call this in your main screen or frequently used pages.

#### Checking User Status

Before allowing user actions, check their status:
```dart
final metadata = await adminService.getUserMetadata(userId);
final status = metadata?['status'] ?? 'active';

if (status == 'suspended' || status == 'banned') {
  // Show blocked message and sign out user
}
```

## Security Setup

### Firestore Rules

Add the rules from `FIRESTORE_RULES_USER_METADATA.md` to your `firestore.rules` file:

```bash
firebase deploy --only firestore:rules
```

### Testing Security Rules

1. Create test accounts with different roles
2. Verify users can only read their own metadata
3. Verify only admins can modify user metadata
4. Verify status checks work correctly

## Routes Added

```dart
// In routes.dart
static const String adminUserDetail = '/admin/user-detail';
```

## Files Modified

### New Files
- `lib/features/admin/views/user_detail_screen.dart`
- `FIRESTORE_RULES_USER_METADATA.md`

### Modified Files
- `lib/features/admin/views/admin_accounts.dart`
- `lib/features/admin/views/admin_account_action.dart`
- `lib/features/admin/admin.dart`
- `lib/core/services/firebase/admin_service.dart`
- `lib/core/config/routes.dart`
- `lib/features/auth/controllers/signup_controller.dart`
- `lib/features/auth/controllers/google_signin_controller.dart`
- `lib/features/auth/controllers/login_controller.dart`

## Testing Checklist

- [ ] Create new user account (verify metadata is created)
- [ ] View all users in account management page
- [ ] Search for users by name and email
- [ ] Filter users by status (Active, Suspended, Banned)
- [ ] Click on a user to view details
- [ ] Suspend a user and verify status changes
- [ ] Ban a user and verify status changes
- [ ] Activate a suspended/banned user
- [ ] Promote user to admin
- [ ] Demote admin to member
- [ ] Pull to refresh user list
- [ ] Verify statistics are accurate (journals, projects, etc.)

## Known Limitations

1. **Real-time updates**: User list doesn't update in real-time. Use pull-to-refresh.
2. **Pagination**: All users are loaded at once. For large user bases (>1000 users), implement pagination.
3. **User session management**: Banned/suspended users aren't automatically signed out. Implement session checks.

## Future Enhancements

1. **Real-time listener**: Add StreamBuilder to watch user_metadata collection
2. **Pagination**: Implement lazy loading for large user lists
3. **Session management**: Auto-sign out suspended/banned users
4. **Activity logs**: Track all admin actions in a separate collection
5. **Email notifications**: Notify users when their status changes
6. **Appeal system**: Allow users to appeal suspensions/bans
7. **Bulk actions**: Select multiple users for batch operations
8. **Export data**: Export user list to CSV
9. **Advanced filters**: Filter by date range, country, activity level, etc.
10. **User analytics**: Charts and graphs for user growth, activity, etc.

## Troubleshooting

### Users not showing up
- Check Firestore permissions
- Verify `user_metadata` collection exists
- Run metadata initialization script for existing users

### Can't update user status
- Verify you're logged in as admin
- Check Firestore security rules
- Verify AdminService methods are working

### Statistics not accurate
- Check collection names match (projects, journal_entries, wishlists, etc.)
- Verify Firestore queries are correct
- Check user IDs match across collections

## Support

For issues or questions, refer to:
- Firebase Console: Check logs and database
- Flutter DevTools: Debug network calls and state
- This documentation: Reference implementation details
