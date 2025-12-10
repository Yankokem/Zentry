# Cloudinary Upload Debugging Guide

## Current Configuration

**Cloud Name:** `dg1cz2twr`

**Presets (All Unsigned):**
- `zentry_accounts_photos` - Profile photos
- `zentry_journal_images` - Journal entry images  
- `zentry_project_images` - Project images
- `zentry_wishlist_images` - Wishlist item images
- `zentry_bug_reports` - Bug report screenshots
- `zentry_account_appeal` - Account appeal documents

## Common Error: "DioException [bad request]"

This error occurs when the request format doesn't match what Cloudinary expects. Here's how to fix it:

### Step 1: Verify Preset Configuration in Cloudinary Dashboard

Go to: Settings → Upload → Upload presets

For **EACH** preset, ensure:

1. ✅ **Signing Mode:** `Unsigned`
2. ✅ **Upload preset name** matches exactly (case-sensitive)
3. ✅ **Folder** is configured (or leave empty if you want root)
4. ⚠️ **DO NOT enable** these options:
   - Use filename or externally defined Public ID
   - Unique filename
   - Overwrite (keep OFF)
   - Auto-tagging
   - Any transformation that requires authentication

### Step 2: Test with Minimal Settings

For `zentry_accounts_photos` preset:
```
Signing mode: Unsigned
Folder: accounts (or leave empty)
Upload controls:
  - Discard original filename: OFF
  - Use filename: OFF  
  - Unique filename: OFF
```

### Step 3: Verify Code is Correct

The current implementation:
```dart
final response = await cloudinary.uploadFile(
  CloudinaryFile.fromFile(
    file.path,
    resourceType: CloudinaryResourceType.Image,
  ),
);
```

This is the MINIMAL configuration for unsigned uploads. DO NOT add:
- `publicId` parameter
- `folder` parameter  
- Any transformation parameters
- Tags or metadata

### Step 4: Check Cloudinary Account Limits

Free tier limits:
- 25 monthly credits
- 25 GB storage
- 25 GB monthly bandwidth

Verify you haven't exceeded limits in: Dashboard → Usage

### Step 5: Test Direct Upload via Cloudinary Widget

Add this test function to verify your preset works:

```dart
// Test function - paste in account_settings_screen.dart temporarily
Future<void> _testCloudinaryUpload() async {
  try {
    print('Testing Cloudinary upload...');
    print('Cloud name: dg1cz2twr');
    print('Preset: zentry_accounts_photos');
    
    if (_selectedImage == null) {
      print('No image selected');
      return;
    }
    
    final cloudinary = CloudinaryPublic('dg1cz2twr', 'zentry_accounts_photos');
    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(_selectedImage!.path),
    );
    
    print('SUCCESS! URL: ${response.secureUrl}');
  } catch (e) {
    print('ERROR: $e');
  }
}
```

### Step 6: Common Fixes

**If error persists:**

1. **Recreate the preset:**
   - Delete `zentry_accounts_photos`
   - Create new unsigned preset with ONLY these settings:
     - Name: `zentry_accounts_photos`
     - Signing mode: Unsigned
     - Everything else: DEFAULT

2. **Check preset name spelling:**
   - Must be EXACT match (case-sensitive)
   - No extra spaces
   - Use underscores, not hyphens

3. **Verify API is enabled:**
   - Settings → Security → Allowed fetch domains: Allow all
   - Settings → Upload → Upload restrictions: None

4. **Try without folder:**
   - Remove any folder configuration in preset
   - Let images go to root

## Testing Checklist

Run through these tests:

- [ ] Preset exists in Cloudinary dashboard
- [ ] Preset is set to "Unsigned" 
- [ ] Preset name matches code exactly
- [ ] No special transformations enabled in preset
- [ ] Account has available credits
- [ ] Flutter clean && flutter pub get executed
- [ ] App completely restarted (not hot reload)
- [ ] Image file exists and is valid format (jpg/png)
- [ ] Image size is reasonable (<10MB)

## Still Not Working?

Try this alternative preset configuration:

```
Mode: Unsigned
Folder: [EMPTY - leave blank]
Access mode: public
Transformation: [EMPTY]
Format: Auto
Use filename: NO
Unique filename: NO
Discard original filename: YES
Overwrite: NO
Backup: NO
```

## Success Indicators

When upload works correctly, you'll see:
1. Green snackbar: "Profile photo uploaded successfully"
2. Image appears in Cloudinary Media Library
3. Profile picture updates in app immediately
4. No errors in console

## Contact Support

If none of these work, check:
- Cloudinary Status Page: status.cloudinary.com
- Cloudinary Support: support.cloudinary.com
- Package Issues: github.com/cloudinary/cloudinary_dart
