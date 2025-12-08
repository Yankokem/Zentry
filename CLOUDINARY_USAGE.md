# Cloudinary Service - Usage Guide

## 📝 Quick Reference

Your CloudinaryService is now configured with **6 upload presets** for different image types.

### Cloud Name
✅ **dg1cz2twr** (Already configured in code)

---

## 🎯 Upload Presets Configuration

| Upload Type | Preset Name | Folder Location | Usage |
|-------------|-------------|-----------------|-------|
| Account Photo | `zentry_account_photos` | `zentry/account_photos/` | User profile pictures |
| Journal Image | `zentry_journal_images` | `zentry/journal_images/` | Journal entry attachments |
| Project Image | `zentry_project_images` | `zentry/project_images/` | Project file attachments |
| Wishlist Image | `zentry_wishlist_images` | `zentry/wishlist_images/` | Wishlist item images |
| Bug Report | `zentry_bug_reports` | `zentry/bug_reports/` | Bug report screenshots |
| Account Appeal | `zentry_account_appeals` | `zentry/account_appeals/` | Account appeal documents |

---

## 💻 How to Use CloudinaryService

### 1. Import the Service

```dart
import 'package:zentry/core/core.dart';
```

### 2. Upload Images

```dart
// Get the CloudinaryService instance
final cloudinaryService = CloudinaryService();

// Example 1: Upload Account Photo
try {
  final imageUrl = await cloudinaryService.uploadImage(
    imageFile,
    uploadType: CloudinaryUploadType.accountPhoto,
    publicId: userId, // Optional: custom identifier
  );
  print('Uploaded to: $imageUrl');
} catch (e) {
  print('Upload failed: $e');
}

// Example 2: Upload Journal Image
try {
  final imageUrl = await cloudinaryService.uploadImage(
    imageFile,
    uploadType: CloudinaryUploadType.journalImage,
    publicId: 'journal_${DateTime.now().millisecondsSinceEpoch}',
  );
  print('Uploaded to: $imageUrl');
} catch (e) {
  print('Upload failed: $e');
}

// Example 3: Upload Project Image
try {
  final imageUrl = await cloudinaryService.uploadImage(
    imageFile,
    uploadType: CloudinaryUploadType.projectImage,
  );
  print('Uploaded to: $imageUrl');
} catch (e) {
  print('Upload failed: $e');
}

// Example 4: Upload Wishlist Image
try {
  final imageUrl = await cloudinaryService.uploadImage(
    imageFile,
    uploadType: CloudinaryUploadType.wishlistImage,
    publicId: 'wishlist_item_123',
  );
  print('Uploaded to: $imageUrl');
} catch (e) {
  print('Upload failed: $e');
}

// Example 5: Upload Bug Report Screenshot
try {
  final imageUrl = await cloudinaryService.uploadImage(
    imageFile,
    uploadType: CloudinaryUploadType.bugReport,
    publicId: 'bug_${bugReportId}',
  );
  print('Uploaded to: $imageUrl');
} catch (e) {
  print('Upload failed: $e');
}

// Example 6: Upload Account Appeal Document
try {
  final imageUrl = await cloudinaryService.uploadImage(
    imageFile,
    uploadType: CloudinaryUploadType.accountAppeal,
    publicId: 'appeal_${userId}_${timestamp}',
  );
  print('Uploaded to: $imageUrl');
} catch (e) {
  print('Upload failed: $e');
}
```

---

## 🔧 Available Upload Types

```dart
enum CloudinaryUploadType {
  accountPhoto,      // For user profile pictures
  journalImage,      // For journal entry images
  projectImage,      // For project attachments
  wishlistImage,     // For wishlist item images
  bugReport,         // For bug report screenshots
  accountAppeal,     // For account appeal documents
}
```

---

## 📋 Implementation Checklist

### Step 1: Create Presets in Cloudinary Dashboard
Follow `CLOUDINARY_SETUP.md` to create all 6 presets:
- [ ] zentry_account_photos
- [ ] zentry_journal_images
- [ ] zentry_project_images
- [ ] zentry_wishlist_images
- [ ] zentry_bug_reports
- [ ] zentry_account_appeals

### Step 2: Choose Signing Mode

#### Option A: Unsigned Presets (Current Implementation)
✅ **Already configured** - Works with current code
- Easier to implement
- No server-side signature needed
- Good for development and small apps

**To use**: Set all presets to **"Unsigned"** mode in Cloudinary dashboard

#### Option B: Signed Presets (More Secure)
⚠️ **Requires code changes**
- More secure
- Prevents unauthorized uploads
- Recommended for production

**To use**: 
1. Set all presets to **"Signed"** mode
2. Switch to `cloudinary` package (not `cloudinary_public`)
3. Implement signature generation (requires server-side code)

---

## 🎨 Where to Implement

### 1. Account Photo Upload
**File**: `lib/features/profile/views/account_settings_screen.dart`
✅ **Already implemented** - Uses `CloudinaryUploadType.accountPhoto`

### 2. Journal Image Upload
**File**: `lib/features/journal/views/add_journal_page.dart` or similar

```dart
// Add this method to your journal page
Future<String?> _uploadJournalImage(File imageFile) async {
  try {
    final imageUrl = await CloudinaryService().uploadImage(
      imageFile,
      uploadType: CloudinaryUploadType.journalImage,
      publicId: 'journal_${DateTime.now().millisecondsSinceEpoch}',
    );
    return imageUrl;
  } catch (e) {
    // Handle error
    return null;
  }
}
```

### 3. Project Image Upload
**File**: `lib/features/projects/views/` (wherever you handle project images)

```dart
Future<String?> _uploadProjectImage(File imageFile, String projectId) async {
  try {
    final imageUrl = await CloudinaryService().uploadImage(
      imageFile,
      uploadType: CloudinaryUploadType.projectImage,
      publicId: 'project_${projectId}_${DateTime.now().millisecondsSinceEpoch}',
    );
    return imageUrl;
  } catch (e) {
    return null;
  }
}
```

### 4. Wishlist Image Upload
**File**: `lib/features/wishlist/views/` (wherever you handle wishlist images)

```dart
Future<String?> _uploadWishlistImage(File imageFile, String itemId) async {
  try {
    final imageUrl = await CloudinaryService().uploadImage(
      imageFile,
      uploadType: CloudinaryUploadType.wishlistImage,
      publicId: 'wishlist_${itemId}',
    );
    return imageUrl;
  } catch (e) {
    return null;
  }
}
```

### 5. Bug Report Image Upload
**File**: `lib/features/help/` or support section (to be created)

```dart
Future<String?> _uploadBugReportImage(File imageFile, String reportId) async {
  try {
    final imageUrl = await CloudinaryService().uploadImage(
      imageFile,
      uploadType: CloudinaryUploadType.bugReport,
      publicId: 'bug_${reportId}',
    );
    return imageUrl;
  } catch (e) {
    return null;
  }
}
```

### 6. Account Appeal Image Upload
**File**: `lib/features/help/` (to be implemented)

```dart
Future<String?> _uploadAppealImage(File imageFile, String userId) async {
  try {
    final imageUrl = await CloudinaryService().uploadImage(
      imageFile,
      uploadType: CloudinaryUploadType.accountAppeal,
      publicId: 'appeal_${userId}_${DateTime.now().millisecondsSinceEpoch}',
    );
    return imageUrl;
  } catch (e) {
    return null;
  }
}
```

---

## 🛡️ Best Practices

### 1. Error Handling
Always wrap uploads in try-catch:
```dart
try {
  final url = await cloudinaryService.uploadImage(...);
  // Success
} catch (e) {
  // Show error to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Upload failed: $e')),
  );
}
```

### 2. Loading States
Show loading indicator during upload:
```dart
setState(() => _isUploading = true);
try {
  final url = await cloudinaryService.uploadImage(...);
  // Success
} catch (e) {
  // Error
} finally {
  setState(() => _isUploading = false);
}
```

### 3. Image Optimization
Use image picker with quality settings:
```dart
final ImagePicker picker = ImagePicker();
final XFile? image = await picker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 1920,
  maxHeight: 1920,
  imageQuality: 85, // 0-100
);
```

### 4. Public ID Naming Convention
Use descriptive, unique IDs:
```dart
// Good
publicId: 'user_${userId}_profile'
publicId: 'journal_${journalId}_${timestamp}'
publicId: 'project_${projectId}_attachment_${index}'

// Bad
publicId: 'image1'
publicId: 'photo'
```

---

## 📊 Monitoring

### Check Upload Status
Monitor uploads in Cloudinary dashboard:
1. Go to [https://cloudinary.com/console/media_library](https://cloudinary.com/console/media_library)
2. Navigate to folders: `zentry/account_photos/`, etc.
3. View uploaded images and their details

### Storage Usage
Check your storage quota:
1. Go to [https://cloudinary.com/console](https://cloudinary.com/console)
2. View usage stats on dashboard
3. Free tier: 25GB storage, 25GB bandwidth/month

---

## 🔄 Migration from Firebase Storage

If you have existing images in Firebase Storage:

1. **Option A**: Leave old images, use Cloudinary for new ones
2. **Option B**: Migrate old images to Cloudinary:
   ```dart
   // Download from Firebase
   final url = await FirebaseStorage.instance.ref(oldPath).getDownloadURL();
   // Upload to Cloudinary
   final newUrl = await cloudinaryService.uploadImage(...);
   // Update Firestore with new URL
   ```

---

## ✅ Summary

1. ✅ CloudinaryService initialized in `main.dart`
2. ✅ Account photo upload implemented
3. ⏳ Journal, Project, Wishlist uploads - ready to implement
4. ⏳ Bug Report, Account Appeal - pending feature implementation
5. ✅ All preset names configured in code
6. ⏳ Presets need to be created in Cloudinary dashboard

**Next Step**: Follow `CLOUDINARY_SETUP.md` to create the presets in your Cloudinary dashboard!
