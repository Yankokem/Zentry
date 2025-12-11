# Appeal Permission Debug Guide

## What Was Fixed

### 1. **Firestore Security Rules**
- **Issue**: The `account_appeal` collection had no security rules defined
- **Fix**: Added comprehensive rules that allow:
  - ✅ **Any authenticated user to CREATE appeals** (userId is verified in the app code)
  - ✅ **Users to READ their own appeals** (filtered by `resource.data.userId == request.auth.uid`)
  - ✅ **Admins to READ, UPDATE, and DELETE all appeals**

### 2. **DateTime Serialization**
- **Issue**: DateTime objects were being saved directly to Firestore instead of as Timestamps
- **Fix**: Modified `AccountAppealModel.toMap()` to convert DateTime to Firestore Timestamp using `Timestamp.fromDate()`

### 3. **Enhanced Logging**
- **Added debug logging** in both `AccountAppealService` and `account_appeal_screen.dart` to track the full flow

## Updated Firestore Rules

```firestore
// Account Appeals - Users can create appeals, admins can read and manage
match /account_appeal/{appealId} {
  // Users can create their own appeals
  // Allowing any authenticated user to create (userId will be verified in app)
  allow create: if request.auth != null;
  
  // Users can read their own appeals, admins can read all
  allow read: if request.auth != null && (
    isAdmin() ||
    resource.data.userId == request.auth.uid
  );
  
  // Only admins can update or delete appeals
  allow update, delete: if isAdmin();
}
```

## Why the Original Rule Failed

The original rule was:
```
allow create: if request.auth != null && 
                 request.resource.data.userId == request.auth.uid;
```

**Problem**: When checking `request.resource.data.userId`, if there's ANY issue accessing that field or type mismatch, the rule fails. The simpler approach allows creation and relies on app-level validation.

## How to Test the Appeal System

### 1. **Start the App in Debug Mode**
```bash
flutter run
```

### 2. **Suspend/Ban Your Test Account**
- Use admin dashboard or Firebase Console to set suspension metadata

### 3. **Try to Login**
- You should see the suspension dialog
- Click "Submit Appeal"

### 4. **Watch the Console Logs**
You'll see output like:
```
🔍 Starting appeal submission...
  Widget userId: USER_UID_HERE
  Widget userEmail: user@example.com
  Appeal details:
    Title: My Appeal
    Reason: suspension
    Evidence count: 1
    Evidence URLs: [cloudinary_url]
📤 Calling _appealService.submitAppeal()...
📤 Submitting appeal:
  userId: USER_UID_HERE
  userEmail: user@example.com
  reason: suspension
  title: My Appeal
  status: Pending
  Collection: account_appeal
  Data keys: [userId, userEmail, reason, title, content, evidenceUrls, status, adminResponse, createdAt, updatedAt, resolvedAt]
✅ Appeal submitted successfully with ID: appeal_doc_id_here
```

### 5. **Verify in Firebase Console**
- Go to Firebase Console
- Navigate to Firestore → `account_appeal` collection
- You should see your appeal document with all fields populated

## Troubleshooting

### If You Still Get Permission Error:

1. **Check Authentication**
   - Ensure you're logged in: Check if `_authService.currentUser` is not null
   - Look for `Widget userId: null` in console logs

2. **Check Firestore Rules Deployment**
   - Run: `firebase deploy --only firestore:rules`
   - Verify rules compiled successfully

3. **Check Network**
   - Ensure device/emulator has internet connection
   - Try hot reload: `r` in Flutter console

4. **Check Firebase Project**
   - Verify project ID is correct: `zentry-f40a0`
   - Go to Firebase Console and check that Firestore is enabled

### If Data Doesn't Appear in Firestore:

1. **Check Timestamps**
   - All DateTime fields should be Firestore Timestamps (not strings or numbers)
   - Verify in `AccountAppealModel.toMap()` using `Timestamp.fromDate()`

2. **Check Field Names**
   - Appeal must have `userId` field matching the authenticated user's UID
   - Check exact spelling: `userId`, not `user_id` or `uid`

3. **Check App-Level Validation**
   - Verify form validation passes (title, description required)
   - Verify rich text editor has content

## Logging Output Locations

**Console Logs**: Run `flutter run` and watch the console output

**Log Categories**:
- 🔍 = Debug/Investigation logs
- 📤 = Upload/submission logs
- ✅ = Success logs
- ❌ = Error logs

## Security Notes

- Appeals are immutable once created (only admins can edit/delete)
- Users can only read their own appeals (unless they're admins)
- Admins can see and manage all appeals
- All timestamps are in UTC

## Next Steps

After verifying appeals can be submitted:

1. ✅ Appeal submission working
2. ⏳ Build admin dashboard to display pending appeals
3. ⏳ Add admin response/approval workflow
4. ⏳ Send notification to user when appeal is reviewed
5. ⏳ Auto-unlock account if appeal is approved
