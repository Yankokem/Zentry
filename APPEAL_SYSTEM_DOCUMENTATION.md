# Account Appeal System Documentation

## Overview

The Account Appeal System allows suspended or banned users to submit appeals through your Zentry application. The system includes user-facing appeal forms, admin review interfaces, and complete Firestore integration.

## Appeal Storage & Location

**Firestore Collection:** `account_appeal`

Appeals are stored in the `account_appeal` collection in Firestore with the following structure:

```
account_appeal/
  ├── {appealId1}/
  │   ├── userId (string) - User's Firebase UID
  │   ├── userEmail (string) - User's email address
  │   ├── reason (string) - 'suspension' or 'ban'
  │   ├── title (string) - Appeal title
  │   ├── content (string) - Rich text content (Delta JSON format)
  │   ├── evidenceUrls (array) - URLs of uploaded evidence images
  │   ├── status (string) - 'Pending', 'Approved', 'Rejected', 'Under Review'
  │   ├── adminResponse (string, optional) - Admin's response to the appeal
  │   ├── createdAt (timestamp) - When the appeal was submitted
  │   ├── updatedAt (timestamp) - Last update time
  │   └── resolvedAt (timestamp, optional) - When the appeal was resolved
  └── {appealId2}/
      └── [same structure as above]
```

## Can Admins See Appeals?

**Yes, absolutely!** The Firestore security rules explicitly allow admins to:

1. **Read all appeals** - Admins can view any appeal regardless of user
2. **Update appeals** - Admins can change appeal status, add responses, and resolve appeals
3. **Manage appeals** - Admins have full write/delete access to the collection

### Current Firestore Rules for Appeals

```firestore
// Account Appeals - Users can create appeals, admins can read and manage
match /account_appeal/{appealId} {
  // Users can create their own appeals
  allow create: if request.auth != null && 
                   request.resource.data.userId == request.auth.uid;
  
  // Users can read their own appeals
  allow read: if request.auth != null && (
    isAdmin() ||
    resource.data.userId == request.auth.uid
  );
  
  // Admins can read all appeals and update them
  allow write, delete: if isAdmin();
}
```

## User Flow

1. **User receives suspension/ban dialog** during login with options:
   - View suspension details (duration, reason)
   - Submit an appeal
   - Logout

2. **Appeal Screen** opens with pre-filled data:
   - `userId` - Automatically filled with user's UID
   - `userEmail` - Automatically filled with user's email
   - `status` - Shows current account status (suspended/banned)
   - User provides:
     - Appeal title
     - Detailed description using rich text editor
     - Evidence images (optional, uploaded to Cloudinary)
     - Reason (suspension or ban)

3. **Submission**
   - Appeal is created with status: `'Pending'`
   - `createdAt` timestamp is set to current time
   - Stored in `account_appeal` Firestore collection

4. **Admin Review**
   - Admins can view pending appeals in admin dashboard
   - Review user's explanation and evidence
   - Approve or reject the appeal
   - Add admin response message
   - Update appeal status to `'Approved'`, `'Rejected'`, or `'Under Review'`
   - `resolvedAt` timestamp is set when appeal is finalized

## Related Classes

### AccountAppealModel
**Location:** `lib/features/admin/models/account_appeal_model.dart`

Data model representing an appeal:
```dart
class AccountAppealModel {
  final String id;
  final String userId;
  final String userEmail;
  final String reason; // 'suspension' or 'ban'
  final String title;
  final String content; // Rich text (Delta JSON)
  final List<String> evidenceUrls;
  final String status;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
}
```

### AccountAppealService
**Location:** `lib/features/admin/services/firebase/account_appeal_service.dart`

Service methods available:
- `submitAppeal(appeal)` - Submit a new appeal
- `getAllAppeals()` - Get all appeals (admin)
- `getAppealsByUser(userId)` - Get user's appeals
- `updateAppealStatus(appealId, status)` - Update status
- `updateAppealWithResponse(appealId, status, response)` - Resolve with admin response
- `getAppealsStream()` - Real-time stream of all appeals
- `getAppealsByStatusStream(status)` - Real-time stream by status

### AccountAppealScreen
**Location:** `lib/features/profile/views/account_appeal_screen.dart`

User-facing appeal submission form with:
- Pre-filled userId and userEmail
- Rich text editor for detailed explanation
- Image upload support via Cloudinary
- Form validation
- Appeal submission with error handling

## Admin Dashboard

The admin section needs to include an appeals dashboard to display and manage appeals:

**Expected Features:**
- List of pending appeals
- Filter by status (Pending, Under Review, Approved, Rejected)
- View appeal details (user info, reason, description, evidence images)
- Admin actions:
  - Review appeal
  - Add response message
  - Approve/Reject with decision

## Firestore Security Rules Summary

The appeal collection rules implement:

1. **User Creation:** Users can only create appeals with their own `userId`
2. **User Read:** Users can only read their own appeals
3. **Admin Read:** Admins can read all appeals
4. **Admin Write/Delete:** Admins have full control over all appeals
5. **Authentication Required:** All operations require Firebase authentication

## Testing the Appeal System

1. **Submit an Appeal:**
   - Login with a suspended/banned account
   - Click "Submit Appeal" in the suspension dialog
   - Fill in the appeal form with details
   - Add evidence images if available
   - Submit

2. **Verify in Firestore:**
   - Go to Firebase Console
   - Navigate to `account_appeal` collection
   - Verify your appeal document exists with correct data

3. **Admin Review (Future Implementation):**
   - Create admin dashboard view
   - Display all pending appeals
   - Allow admin to approve/reject
   - Send notification to user about decision

## Next Steps

1. ✅ **Firestore Rules Added** - Appeals collection now has proper security rules
2. ✅ **Service Implemented** - AccountAppealService with full CRUD operations
3. ✅ **Model Defined** - AccountAppealModel with all necessary fields
4. ✅ **User UI Created** - AccountAppealScreen for appeal submission
5. ⏳ **Admin Dashboard** - Need to create admin view to manage appeals
6. ⏳ **Notifications** - Consider notifying users when appeal is reviewed
7. ⏳ **Appeal Status Updates** - Auto-update user status if appeal is approved

## Important Notes

- Appeals are immutable once submitted (users cannot edit)
- Admins can only update status and add response
- All timestamps are in UTC (Firestore format)
- Evidence images are stored in Cloudinary with URLs in the `evidenceUrls` array
- Rich text content is stored as Delta JSON (Quill format)
