# Complete Appeal Flow - Data Tracking Guide

## Database Structure

### When Admin Suspends/Bans User

**user_metadata collection** document for user "abc123":
```json
{
  // ✅ NOW STORED (previously missing!)
  "userId": "abc123",
  "userEmail": "user@example.com",
  
  // Status Info
  "status": "suspended",
  "suspensionStartDate": Timestamp(2025-12-11),
  "suspensionDuration": "7 days",
  "suspensionReason": "Spam posting behavior",
  
  // Metadata
  "lastActive": Timestamp(2025-12-10),
  "createdAt": Timestamp(2025-10-01),
  "updatedAt": Timestamp(2025-12-11)
}
```

---

## Complete Appeal Flow with Data Tracking

### 1. User Attempts Login
```
Input:
  email: "user@example.com"
  password: "correctPassword123"

Firebase Auth ✓ Success
  → Returns UserCredential with uid = "abc123"
```

### 2. System Checks Account Status
```dart
final userId = "abc123"
final status = await adminService.checkAndUpdateSuspensionStatus(userId)
  → Gets metadata from user_metadata collection
  → Returns status = "suspended"
```

### 3. System Retrieves Suspension Details
```dart
final metadata = await adminService.getUserMetadata(userId)
// metadata now contains:
{
  userId: "abc123",              // ✅ Available
  userEmail: "user@example.com", // ✅ Available
  status: "suspended",
  suspensionReason: "Spam posting behavior",
  suspensionDuration: "7 days"
}
```

### 4. Dialog Appears with Appeal Option
```
Dialog Content:
  Icon: 🟠
  Title: "Account Suspended"
  Message: "Your account is suspended for 7 days.
            Reason: Spam posting behavior
            Please contact zentry_admin@zentry.app.com"
  Buttons: [Appeal This Action] [Close]
```

### 5. User Clicks "Appeal This Action"
```dart
Navigator.pushNamed(
  context,
  '/account-appeal',
  arguments: {
    'userId': userId,        // ✅ "abc123"
    'userEmail': userEmail,  // ✅ "user@example.com"
    'status': status,        // ✅ "suspended"
  },
)
```

### 6. AccountAppealScreen Opens
```dart
class AccountAppealScreen extends StatefulWidget {
  final String? userId;          // ✅ = "abc123"
  final String? userEmail;       // ✅ = "user@example.com"
  final String? status;          // ✅ = "suspended"
}
```

The form automatically pre-fills:
- Restriction Type: "Account Suspension" (based on status)
- Form is ready for user's title and description

### 7. User Submits Appeal
```dart
final appeal = AccountAppealModel.create(
  userId: "abc123",              // ✅ From passed parameter
  userEmail: "user@example.com", // ✅ From passed parameter
  reason: "suspension",
  title: "I didn't spam!",
  content: "Rich text description of appeal...",
  evidenceUrls: ["image1.jpg", "image2.jpg"],
);

await _appealService.submitAppeal(appeal)
```

### 8. Appeal Saved in Firestore
**appeals collection** new document:
```json
{
  "userId": "abc123",                    // ✅ Can identify user
  "userEmail": "user@example.com",       // ✅ Can contact user
  "reason": "suspension",
  "title": "I didn't spam!",
  "content": {...richTextJSON...},
  "evidenceUrls": ["image1.jpg", "image2.jpg"],
  "status": "pending",
  "submittedAt": Timestamp(2025-12-11),
  "createdAt": Timestamp(2025-12-11)
}
```

---

## Admin Dashboard Appeal Viewing

### Admin Can Now:
✅ See which user submitted the appeal (userId)
✅ Contact the user directly (userEmail)
✅ View the original suspension reason
✅ Review user's appeal details
✅ See supporting evidence (images)
✅ Approve/deny the appeal with full context

### Query Example:
```dart
// Get all appeals from a specific user
final appeals = await FirebaseFirestore.instance
  .collection('appeals')
  .where('userId', isEqualTo: 'abc123')
  .get();

// Get all pending appeals
final pendingAppeals = await FirebaseFirestore.instance
  .collection('appeals')
  .where('status', isEqualTo: 'pending')
  .get();
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    ADMIN SUSPENDS USER                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
        ┌─────────────────────────────┐
        │   Admin clicks "Suspend"    │
        │   - Enters reason           │
        │   - Selects duration        │
        └─────────────┬───────────────┘
                      │
                      ▼
        ┌─────────────────────────────────────────┐
        │   AdminAccountActionPage calls:         │
        │   updateUserStatus(                     │
        │     userId: "abc123",                   │
        │     status: "suspended",                │
        │     reason: "Spam",                     │
        │     duration: "7 days",                 │
        │     userEmail: "user@example.com" ◄────┼─── NEW! 
        │   )                                     │
        └─────────────┬───────────────────────────┘
                      │
                      ▼
        ┌─────────────────────────────────────────┐
        │   user_metadata collection               │
        │   Document "abc123":                    │
        │   {                                     │
        │     userId: "abc123",           ◄────┐ │
        │     userEmail: "user@...",      ◄────┤─┼─ STORED NOW!
        │     status: "suspended",             │ │
        │     suspensionReason: "Spam",       │ │
        │     ...                             │ │
        │   }                                 │ │
        └─────────────┬───────────────────────┘ │
                      │                         │
                      ▼                         │
┌─────────────────────────────────────────┐    │
│   USER ATTEMPTS LOGIN NEXT DAY          │    │
└─────────────┬───────────────────────────┘    │
              │                                 │
              ▼                                 │
  ┌──────────────────────────┐                 │
  │ Firebase Auth ✓ Success  │                 │
  └────────┬─────────────────┘                 │
           │                                   │
           ▼                                   │
  ┌──────────────────────────────────────────┐ │
  │ checkAndUpdateSuspensionStatus()          │ │
  │   → Returns "suspended"                   │ │
  └────────┬─────────────────────────────────┘ │
           │                                   │
           ▼                                   │
  ┌──────────────────────────────────────────┐ │
  │ getUserMetadata(userId)                   │ │
  │   → Retrieves metadata with:              │ │
  │     - userId: "abc123"          ◄─────────┘ │
  │     - userEmail: "user@..."     ◄────────── RETRIEVED!
  │     - suspensionReason: "Spam"             │
  │     - suspensionDuration: "7 days"        │
  └────────┬──────────────────────────────────┘
           │
           ▼
  ┌──────────────────────────────────────────┐
  │   _showAccountStatusDialog()              │
  │   Dialog shows:                           │
  │   - Status & reason                       │
  │   - Appeal button                         │
  └────────┬──────────────────────────────────┘
           │
           ▼
  ┌──────────────────────────────────────────┐
  │   User clicks "Appeal This Action"        │
  │   Passes to AccountAppealScreen:          │
  │   {                                       │
  │     userId: "abc123",          ◄───────┐  │
  │     userEmail: "user@...",     ◄─────┐ │  │
  │     status: "suspended"              │ │  │
  │   }                                  │ │  │
  └────────┬───────────────────────────────┘  │
           │                            │ │   │
           ▼                            │ │   │
  ┌──────────────────────────────────┐ │ │   │
  │ AccountAppealScreen              │ │ │   │
  │ - Auto-fills userId              │ │ │   │
  │ - Auto-fills userEmail           │ │ │   │
  │ - Auto-selects reason type       │ │ │   │
  │ - User provides:                 │ │ │   │
  │   * Title                        │ │ │   │
  │   * Description                  │ │ │   │
  │   * Evidence images              │ │ │   │
  └────────┬────────────────────────────┘ │   │
           │                          │   │   │
           ▼                          │   │   │
  ┌──────────────────────────────────────┐   │
  │ User clicks "Submit Appeal"          │   │
  │ Creates AccountAppealModel with:     │   │
  │ {                                    │   │
  │   userId: "abc123",          ◄───────┴───┘
  │   userEmail: "user@...",     ◄─────────┘
  │   reason: "suspension",
  │   title: "I didn't spam!",
  │   content: {...},
  │   evidenceUrls: [...]
  │ }
  └────────┬──────────────────────────────┘
           │
           ▼
  ┌──────────────────────────────────────────┐
  │ appeals collection new document:          │
  │ {                                        │
  │   userId: "abc123",         ✅ TRACKED   │
  │   userEmail: "user@...",    ✅ TRACKED   │
  │   reason: "suspension",                  │
  │   title: "I didn't spam!",               │
  │   content: {...},                        │
  │   evidenceUrls: [...],                   │
  │   status: "pending",                     │
  │   submittedAt: Timestamp                 │
  │ }                                        │
  └────────┬──────────────────────────────────┘
           │
           ▼
  ┌──────────────────────────────────────────┐
  │  ADMIN DASHBOARD - APPEALS PAGE           │
  │                                          │
  │  Admin can now:                          │
  │  ✅ See which user submitted (userId)   │
  │  ✅ Contact user (userEmail)            │
  │  ✅ View appeal reason                  │
  │  ✅ Review evidence                     │
  │  ✅ Approve/Deny with context           │
  └──────────────────────────────────────────┘
```

---

## Testing Checklist

- [x] Admin suspends user → userId and userEmail saved
- [x] User attempts login → Dialog shows
- [x] User clicks Appeal → Passed to AccountAppealScreen with userId
- [x] User submits appeal → Appeal saved with userId and userEmail
- [x] Admin can query appeals by userId
- [x] Admin can contact user from appeal (has userEmail)

---

## Summary

**The Fix**: Now when suspending/banning users, we store:
- `userId` → To identify which user the appeal is from
- `userEmail` → To contact the user

**The Result**: Complete appeal tracking with full user identification throughout the entire flow.

---

**Last Updated**: December 11, 2025
