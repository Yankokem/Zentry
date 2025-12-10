# Account Suspension and Ban System

## Overview
This document describes the comprehensive account suspension and ban system implemented in the Zentry application.

## Key Features

### 1. Role Field Cleanup
**Issue**: The `role` field was duplicated in both `users` and `user_metadata` collections, causing data inconsistency.

**Solution**: 
- Removed `role` field from `user_metadata` collection
- Role is now only stored in the `users` collection (single source of truth)
- Updated all methods to read role from `users` collection:
  - `AdminService.getAllUsers()`
  - `AdminService.getUserStatistics()`
  - `AdminService.isUserAdmin()`
  - `AdminService.updateUserRole()` - now updates `users` collection instead of `user_metadata`
  - `AdminService.initializeUserMetadata()` - no longer creates role field

**Files Modified**:
- `lib/core/services/firebase/admin_service.dart`
- `lib/core/utils/user_metadata_initializer.dart`

---

### 2. Login Blocking for Suspended/Banned Users

**Requirement**: Suspended and banned users must not be able to sign in.

**Implementation**:
- Added status check in `LoginController.login()` method
- After successful Firebase Authentication, the system:
  1. Checks if the user's suspension has expired (auto-reactivation)
  2. Retrieves the current user status from `user_metadata`
  3. If status is `suspended` or `banned`:
     - Signs the user out immediately
     - Shows a dialog with their status and reason
     - Provides an "Appeal This Action" button

**Files Modified**:
- `lib/features/auth/controllers/login_controller.dart`
- `lib/features/auth/views/login_screen.dart`

**Code Flow**:
```dart
1. User enters credentials
2. Firebase Auth verifies credentials
3. checkAndUpdateSuspensionStatus() is called
4. If status is active → proceed to home
5. If status is suspended/banned → show dialog with appeal option
```

---

### 3. Suspension Duration System

**Supported Durations**:
- 1 day
- 3 days
- 7 days
- 14 days
- 30 days

**Implementation**:

#### Database Schema (user_metadata collection):
```javascript
{
  status: 'active' | 'suspended' | 'banned',
  suspensionStartDate: Timestamp,      // When suspension was applied
  suspensionDuration: '7 days',        // How long suspension lasts
  suspensionReason: 'Violation reason',
  banReason: 'Ban reason',             // For banned accounts
  lastActive: Timestamp,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### Auto-Reactivation Logic:
New method `AdminService.checkAndUpdateSuspensionStatus()`:
1. Retrieves user metadata
2. Checks if status is 'suspended'
3. Calculates expiry date: `startDate + duration`
4. If current time > expiry date:
   - Updates status to 'active'
   - Removes suspension fields
5. Returns current status

**Called automatically during login** to ensure expired suspensions don't block users.

**Files Modified**:
- `lib/core/services/firebase/admin_service.dart` (added `checkAndUpdateSuspensionStatus()`)
- `lib/features/auth/controllers/login_controller.dart` (calls auto-reactivation)

---

### 4. Status Dialog with Appeal Option

**Dialog Features**:
- Shows appropriate icon and color (orange for suspended, red for banned)
- Displays clear message with:
  - Account status (Suspended/Banned)
  - Duration (for suspensions)
  - Reason for action
  - Contact email: `zentry_admin@zentry.app.com`
- Two action buttons:
  - **"Appeal This Action"** - Opens appeal form
  - **"Close"** - Dismisses dialog

**Appeal Flow**:
1. User clicks "Appeal This Action"
2. Dialog passes `userId`, `userEmail`, and `status` to `AccountAppealScreen`
3. Appeal form is pre-filled with:
   - User's information
   - Appropriate reason type (suspension/ban)
4. User submits appeal with:
   - Title
   - Detailed description (rich text)
   - Supporting evidence (images)

**Files Modified**:
- `lib/features/auth/controllers/login_controller.dart` (added `_showAccountStatusDialog()`)
- `lib/features/profile/views/account_appeal_screen.dart` (updated to accept arguments)
- `lib/core/config/routes.dart` (added `/account-appeal` route)

---

## Admin Workflow

### Suspending a User:
1. Admin navigates to Account Management
2. Selects user → clicks "Suspend"
3. Selects duration from dropdown:
   - 1 day, 3 days, 7 days, 14 days, or 30 days
4. Enters suspension reason
5. Clicks "Suspend User"
6. System records:
   - `status: 'suspended'`
   - `suspensionStartDate: current timestamp`
   - `suspensionDuration: selected duration`
   - `suspensionReason: entered reason`

### Banning a User:
1. Admin navigates to Account Management
2. Selects user → clicks "Ban"
3. Enters ban reason
4. Clicks "Ban User"
5. System records:
   - `status: 'banned'`
   - `banReason: entered reason`

### Reactivating a User:
1. Admin clicks 3-dot menu on suspended/banned user
2. Selects "Activate"
3. Confirms action
4. System removes all suspension/ban data and sets `status: 'active'`

---

## User Experience

### When Suspended User Attempts Login:
```
┌─────────────────────────────────────┐
│   🟠 Account Suspended              │
│                                     │
│   Your account is suspended for     │
│   7 days.                           │
│                                     │
│   Reason: Spam posting              │
│                                     │
│   Please contact                    │
│   zentry_admin@zentry.app.com       │
│   for account appeals.              │
│                                     │
│  [📝 Appeal This Action]            │
│  [    Close    ]                    │
└─────────────────────────────────────┘
```

### When Banned User Attempts Login:
```
┌─────────────────────────────────────┐
│   🔴 Account Banned                 │
│                                     │
│   Your account is banned.           │
│                                     │
│   Reason: Terms of Service          │
│   violation                         │
│                                     │
│   Please contact                    │
│   zentry_admin@zentry.app.com       │
│   for account appeals.              │
│                                     │
│  [📝 Appeal This Action]            │
│  [    Close    ]                    │
└─────────────────────────────────────┘
```

---

## Technical Details

### Collections Structure:

#### users Collection:
```javascript
{
  uid: 'user_id',
  email: 'user@example.com',
  firstName: 'John',
  lastName: 'Doe',
  fullName: 'John Doe',
  role: 'member' | 'admin',  // ← Stored here, not in user_metadata
  profileImageUrl: 'url',
  phoneNumber: '+1234567890',
  country: 'US',
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### user_metadata Collection:
```javascript
{
  status: 'active' | 'suspended' | 'banned',
  suspensionStartDate: Timestamp,      // Only for suspended
  suspensionDuration: '7 days',        // Only for suspended
  suspensionReason: 'Reason text',     // Only for suspended
  banReason: 'Reason text',            // Only for banned
  lastActive: Timestamp,
  createdAt: Timestamp,
  updatedAt: Timestamp
  // NO ROLE FIELD - moved to users collection
}
```

### Key Methods:

#### AdminService:
- `checkAndUpdateSuspensionStatus(userId)` - Auto-reactivates expired suspensions
- `updateUserStatus(userId, status, reason, duration)` - Updates user status
- `getUserMetadata(userId)` - Retrieves metadata
- `initializeUserMetadata(userId)` - Creates initial metadata (without role)
- `getAllUsers()` - Gets all users with combined data
- `getUserStatistics(userId)` - Gets detailed user stats

#### LoginController:
- `login(context)` - Handles authentication and status checking
- `_showAccountStatusDialog()` - Shows status dialog with appeal option

---

## Testing Checklist

### For Suspension:
- [x] Admin can suspend user with duration selection
- [x] Suspended user sees dialog on login attempt
- [x] Dialog shows correct duration and reason
- [x] Appeal button opens appeal form with correct data
- [x] Suspension auto-expires after duration passes
- [x] User can login normally after suspension expires

### For Ban:
- [x] Admin can ban user with reason
- [x] Banned user sees dialog on login attempt
- [x] Dialog shows correct reason
- [x] Appeal button opens appeal form with correct data
- [x] Admin can manually reactivate banned user

### For Role Field:
- [x] Role stored only in users collection
- [x] Admin dashboard displays roles correctly
- [x] User detail screen shows correct role
- [x] New users get role='member' in users collection
- [x] No role field created in user_metadata

---

## Migration Notes

### For Existing Data:
If you have existing user_metadata documents with `role` fields:

1. **Option A - Clean Slate (Recommended for development)**:
   - Delete all documents in `user_metadata` collection
   - Run app - metadata will be recreated without role field on next login

2. **Option B - Migration Script**:
   ```javascript
   // Run in Firebase Console
   db.collection('user_metadata').get().then(snapshot => {
     snapshot.forEach(doc => {
       doc.ref.update({
         role: firebase.firestore.FieldValue.delete()
       });
     });
   });
   ```

---

## Security Rules

Existing Firestore rules remain unchanged:
- Admin can read/write all `user_metadata` documents
- Users can only read their own metadata
- Admin checks use email verification: `zentry_admin@zentry.app.com`

---

## Future Enhancements

Potential improvements for future versions:
1. Email notifications when user is suspended/banned
2. Appeal review system for admins
3. Suspension/ban history tracking
4. Custom suspension durations
5. Scheduled auto-reactivation (Cloud Functions)
6. Warning system before suspension
7. Strike system (3 strikes = suspension)

---

## Contact

For questions or issues regarding this system:
- Admin Email: zentry_admin@zentry.app.com
- Firebase Project: zentry-f40a0

---

**Last Updated**: December 10, 2025
