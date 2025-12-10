# Firestore Rules for User Metadata Collection

Add these rules to your `firestore.rules` file to secure the `user_metadata` collection:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Helper function to check if user is admin
    function isAdmin() {
      return isSignedIn() && 
             exists(/databases/$(database)/documents/user_metadata/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/user_metadata/$(request.auth.uid)).data.role == 'admin';
    }
    
    // User Metadata Collection
    // This collection stores administrative data about users
    match /user_metadata/{userId} {
      // Allow users to read their own metadata
      allow read: if isSignedIn() && request.auth.uid == userId;
      
      // Allow admins to read all user metadata
      allow read: if isAdmin();
      
      // Only admins can create, update, or delete user metadata
      allow write: if isAdmin();
      
      // Allow system to create initial metadata during signup
      allow create: if isSignedIn() && 
                      request.auth.uid == userId &&
                      request.resource.data.role == 'member' &&
                      request.resource.data.status == 'active';
    }
    
    // Existing rules for other collections...
    // (Keep your existing rules for users, projects, etc.)
  }
}
```

## Security Notes:

1. **Read Access**: Users can read their own metadata, admins can read all metadata
2. **Write Access**: Only admins can update user metadata (status, role, etc.)
3. **Initial Creation**: The system can create metadata during signup with default values (member role, active status)
4. **Admin Check**: The `isAdmin()` function checks if a user has admin role in their metadata

## Testing:

After deploying these rules, test them by:
1. Creating a new user account (should auto-create metadata)
2. Trying to read your own metadata (should succeed)
3. Trying to modify your own metadata (should fail for non-admins)
4. As admin, try to read and modify other users' metadata (should succeed)

## Deployment:

Deploy these rules using:
```bash
firebase deploy --only firestore:rules
```
