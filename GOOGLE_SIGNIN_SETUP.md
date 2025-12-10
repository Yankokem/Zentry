# Google Sign-In Setup Guide

## Current Issue: Connection Failure

The "connection failure" error when clicking "Log In with Google" on Android is typically caused by OAuth client configuration issues.

## Your Current Configuration

### SHA-1 Fingerprint (Debug)
```
SHA1: 1E:62:77:22:A9:97:D9:58:06:13:6A:80:D5:3A:85:F9:66:C9:D0:4B
```

### Package Name
```
com.example.zentry
```

### Client IDs from google-services.json
- **Android OAuth Client**: `1038744556460-o47i4dnojgpeevnefeib2sicgkiiai7e.apps.googleusercontent.com`
- **Web OAuth Client**: `1038744556460-shj37ippgd0ate0nin6hihp8qbonvdee.apps.googleusercontent.com`
- **iOS OAuth Client**: `1038744556460-lm9d4l2aqo31ojurpd4nq5hmtef2gh9m.apps.googleusercontent.com`

## Solution Steps

### Step 1: Verify Firebase Console Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **zentry-f40a0**
3. Navigate to **Authentication** → **Sign-in method**
4. Ensure **Google** is **enabled**
5. Check that the **Web SDK configuration** shows the correct Web client ID

### Step 2: Verify Google Cloud Console OAuth Configuration

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: **zentry-f40a0**
3. Navigate to **APIs & Services** → **Credentials**
4. You should see THREE OAuth 2.0 Client IDs:
   - **Web client** (for web and Android backend)
   - **Android client** (for Android app)
   - **iOS client** (for iOS app)

### Step 3: Verify Android OAuth Client Configuration

In Google Cloud Console → Credentials → Android OAuth Client:

**Required Settings:**
- **Package name**: `com.example.zentry`
- **SHA-1 certificate fingerprint**: `1E:62:77:22:A9:97:D9:58:06:13:6A:80:D5:3A:85:F9:66:C9:D0:4B`

**If the SHA-1 is missing or incorrect:**
1. Click on the Android OAuth 2.0 Client ID
2. Add the SHA-1 fingerprint: `1E:62:77:22:A9:97:D9:58:06:13:6A:80:D5:3A:85:F9:66:C9:D0:4B`
3. Save the changes
4. Wait 5-10 minutes for changes to propagate

### Step 4: Re-download google-services.json (If needed)

If you made changes in Firebase Console:

1. Go to Firebase Console → Project Settings → General
2. Scroll to **Your apps** section
3. Find your Android app
4. Click the **download** button to get the updated `google-services.json`
5. Replace the file at: `android/app/google-services.json`

### Step 5: Clean and Rebuild the App

```powershell
# Clean the build
flutter clean

# Get dependencies
flutter pub get

# Rebuild the app
flutter run
```

## Testing the Fix

1. **Stop the currently running app** (if any)
2. **Restart the app** with `flutter run`
3. Click **Log In with Google**
4. Select your Google account
5. You should now be able to sign in successfully

## Common Issues and Solutions

### Issue: "Connection Failure" persists
**Solution**: 
- Ensure your device/emulator has internet access
- Check that Google Play Services is installed and updated on the device
- Wait 5-10 minutes after making changes in Firebase/Google Cloud Console

### Issue: "Developer Error" or "API key not valid"
**Solution**:
- Verify SHA-1 fingerprint is correctly added to **both** Firebase Console and Google Cloud Console
- Ensure the package name matches exactly: `com.example.zentry`

### Issue: Works on one device but not another
**Solution**:
- Each device may have different keystore if you're testing on physical devices
- For debug builds, all devices use the same debug.keystore
- For release builds, you'll need to add the release SHA-1 fingerprint

## Additional Notes

### For Release Build
When you create a release build, you'll need to:
1. Generate a release keystore
2. Get the SHA-1 from the release keystore
3. Add it to Firebase Console and Google Cloud Console

### Web Client ID for Android
Android Google Sign-In requires the **Web client ID** (not the Android client ID) to be passed to the GoogleSignIn initialization. This has been configured in the code.

## Code Changes Made

The following changes were made to fix the issue:

1. **auth_service.dart**: Updated GoogleSignIn initialization to explicitly provide the Web client ID for Android
2. **auth_service.dart**: Added `signOut()` call before sign-in to ensure clean state

## Need More Help?

If the issue persists after following these steps:

1. Check the Flutter logs when the error occurs: Look for detailed error messages
2. Verify all OAuth clients are created in Google Cloud Console
3. Ensure Firebase Authentication is enabled for Google provider
4. Double-check that the SHA-1 fingerprint matches exactly (no typos)
