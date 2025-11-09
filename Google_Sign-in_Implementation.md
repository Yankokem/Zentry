# Google Signin Implementation

Last updated: 2025-11-09

This single document consolidates all existing documentation related to the Google Sign-In feature (web, Android, iOS) and the duplicate-account detection feature. It combines implementation notes, setup steps, troubleshooting, file changes, testing checklists and quick references.

---

## Table of contents

- Overview
- What changed (high level)
- Files modified / created
- Implementation details
  - Auth flow (web vs mobile)
  - Key methods and controllers
  - Firestore structure
- Duplicate-account detection (Signup page)
- Platform-specific setup
  - Web
  - Android
  - iOS
- Testing checklist
- Troubleshooting
- Quick reference (one-page checks)
- Next steps & optional enhancements
- Where to find source files

---

## Overview

Google Sign-In has been implemented across platforms with the following goals:
- Allow users to sign in / sign up with their Google account.
- Save Google user data in Firestore (firstName, lastName, email, photoUrl, authProvider).
- Auto-login users after successful Google authentication.
- Detect when a user tries to sign up with a Google account that already exists, and prompt them to sign in instead.
- Use a hybrid approach: Firebase popup for web, native `google_sign_in` for mobile.

This document consolidates the content previously spread among multiple files (e.g. `GOOGLE_SIGNIN_IMPLEMENTATION.md`, `GOOGLE_SIGNIN_COMPLETE_SETUP.md`, `GOOGLE_DUPLICATE_ACCOUNT_FEATURE.md`, `GOOGLE_DUPLICATE_QUICK_REFERENCE.md`, `FIREBASE_AUTH_DOCUMENTATION.md`, etc.).

---

## What changed (high level)

- Added `google_sign_in` dependency to `pubspec.yaml`.
- Implemented platform-specific Google sign-in logic in `lib/services/firebase/auth_service.dart`.
- Added `GoogleSignInController` (`lib/auth/controllers/google_signin_controller.dart`) to encapsulate flows and provide user-friendly errors and loading states.
- Integrated "Continue with Google" flow in both `lib/auth/login_screen.dart` and `lib/auth/signup_screen.dart`.
- Added Firestore helper `createGoogleUserDocument(User user)` to persist Google user info.
- Implemented duplicate-account detection on the signup screen with a modal dialog allowing the user to accept (sign in) or reject (sign out and try another account).
- Added multiple documentation files during development; this file replaces and centralizes them.

---

## Files modified / created (summary)

Core code:

- `pubspec.yaml` — added `google_sign_in: ^6.2.1`
- `lib/services/firebase/auth_service.dart` — platform detection; `signInWithGoogle()` uses `signInWithPopup` for web and `google_sign_in` for mobile
- `lib/services/firebase/firestore_service.dart` — `createGoogleUserDocument(User user)` and `userExistsByEmail(String email)` (queries)
- `lib/auth/controllers/google_signin_controller.dart` — new controller (signInWithGoogle, signUpWithGoogleAndCheckExisting, signOut, error parsing, state)
- `lib/auth/login_screen.dart` — integrated "Continue with Google" button and handler
- `lib/auth/signup_screen.dart` — integrated "Continue with Google" handler with duplicate detection dialog

Platform files (configuration):

- `web/index.html` — meta tag for client id, Google platform script
- `android/app/src/main/AndroidManifest.xml` — added google play meta-data and INTERNET permission
- `android/app/src/main/res/values/strings.xml` — added `fallback_app_signature` placeholder (if used, replace with actual signature or remove meta-data)
- `ios/Runner/Info.plist` — added URL scheme (CFBundleURLTypes) for Google sign-in callbacks

Documentation files (migrated/merged into this doc):

- `GOOGLE_SIGNIN_IMPLEMENTATION.md`
- `GOOGLE_SIGNIN_COMPLETE_SETUP.md`
- `GOOGLE_SIGNIN_COMPLETE_FILE_SUMMARY.md`
- `GOOGLE_DUPLICATE_ACCOUNT_FEATURE.md`
- `GOOGLE_DUPLICATE_QUICK_REFERENCE.md`
- `FIREBASE_AUTH_DOCUMENTATION.md`

---

## Implementation details

### Platform strategy

- Web: Use Firebase Auth `signInWithPopup(GoogleAuthProvider)` — simple, works in development without needing a full OAuth consent flow; only `localhost` needs to be on Firebase authorized domains.
- Mobile (Android / iOS): Use `google_sign_in` package to integrate with native account selection and return tokens which are then passed to Firebase via `GoogleAuthProvider.credential(...)`.

The `auth_service.dart` detects `kIsWeb` and `defaultTargetPlatform` and picks the appropriate flow.

### Key controller methods

- `AuthService.signInWithGoogle()`
  - Web: `signInWithPopup(GoogleAuthProvider)`
  - Mobile: `GoogleSignIn().signIn()` → obtain auth tokens → create `OAuthCredential` → `FirebaseAuth.instance.signInWithCredential(credential)`

- `GoogleSignInController.signInWithGoogle()`
  - Used by login screen; performs sign-in and ensures Firestore doc exists/updated.

- `GoogleSignInController.signUpWithGoogleAndCheckExisting()`
  - Used by signup screen; signs in with Google, queries Firestore via `userExistsByEmail(email)`. If account exists, returns `userExists=true` with `user` object so the UI can show the duplicate-account dialog.

- `FirestoreService.createGoogleUserDocument(User user)`
  - Extracts `displayName`, splits into `firstName`/`lastName`, sets `authProvider: 'google'`, and ensures not to overwrite an existing doc unintentionally.

### Firestore data structure (Google users)

Example document:

{
  "uid": "firebase-uid-from-google",
  "firstName": "John",
  "lastName": "Doe",
  "fullName": "John Doe",
  "email": "john@gmail.com",
  "photoUrl": "https://lh3.googleusercontent.com/...",
  "authProvider": "google",
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}

Emails are stored in lowercase for consistent queries.

---

## Duplicate-account detection (Sign-Up page)

Behavior:
- When the user taps "Continue with Google" on the signup page, the app signs in with Google and obtains the email.
- The controller calls `userExistsByEmail(email)`.
- If an existing account is found, UI shows a modal dialog (non-dismissible) with:
  - Title: "Account Exists"
  - Body: "Google Account already exists" + the email address
  - Buttons: "No" (sign out and let the user try another account) and "Yes" (accept and navigate to home / sign in)

Controller contract (short):
- Inputs: user taps button
- Outputs: map { success: bool, userExists: bool, user: User?, message: String }
- Error modes: sign-in failure, Firestore failure — controller returns success:false and an error message string

Edge cases considered:
- Null `user` from Firebase after sign-in → treated as failure with user-facing message
- Network/Firestore errors are caught and returned for UI display
- Duplicate account dialog cannot be dismissed accidentally (barrierDismissible: false)

---

## Platform-specific setup

These are the essential steps to get Google Sign-In working per platform.

### Web (quick)
- Add `localhost` to Firebase Auth → Authorized domains.
- In `web/index.html` ensure the client id meta tag is present (for non-popup web flows) and platform script loaded. However, the implemented web flow uses Firebase popup so OAuth consent screen is not strictly required for development.
- Test: `flutter run -d chrome` and click "Continue with Google".

### Android
- Add `google-services.json` to `android/app/` (download from Firebase Console after adding app)
- Add your app's SHA-1 (debug or release) to Firebase Console 
  - Run in PowerShell in the android folder: `.\gradlew signingReport` (on Windows in PowerShell; or use keytool)
- Ensure `android/app/src/main/AndroidManifest.xml` contains the required permissions and meta-data entries (we added INTERNET and Google meta-data). If `@string/fallback_app_signature` is referenced, put the string in `res/values/strings.xml` or remove the meta-data if not needed.
- Rebuild: `flutter clean && flutter pub get && flutter run`.

### iOS
- Download `GoogleService-Info.plist` from Firebase Console and add it to `ios/Runner` in Xcode (use `Runner.xcworkspace`).
- Ensure `CFBundleURLTypes` contains the Google client ID scheme in `ios/Runner/Info.plist`.
- Test on a real device (simulator cannot perform Google Sign-In reliably).

---

## Testing checklist (canonical)

- [ ] Web: Click "Continue with Google" → popup appears → authenticate → user lands on Home and Firestore doc created
- [ ] Android: Add SHA-1 and `google-services.json` → run on emulator/device → sign-in works
- [ ] iOS: Add `GoogleService-Info.plist` → run on device → sign-in works
- [ ] Signup duplicate flow: Sign up with a Google account that already exists → dialog appears; "Yes" logs in, "No" signs out
- [ ] Firestore documents are created with correct fields and lowercase emails
- [ ] Error messages show meaningful guidance for configuration errors (DEVELOPER_ERROR, invalid_client, network)

---

## Troubleshooting (quick reference)

Symptom: Android build fails with resource linking complaining about `@string/fallback_app_signature`
- Fix: Add `android/app/src/main/res/values/strings.xml` with `<string name="fallback_app_signature">YOUR_VALUE</string>` or remove the `<meta-data>` line in `AndroidManifest.xml` if you don't need fallback signature.

Symptom: `DEVELOPER_ERROR` during sign-in
- Fix: Ensure SHA-1 in Firebase Console matches the app's cert, package name matches, and `google-services.json` is current.

Symptom: Web "ClientID not set" or OAuth errors
- Fix: For web development use Firebase popup method; ensure `localhost` is in authorized domains. If using full OAuth flow, configure OAuth consent screen in Google Cloud Console and add authorized origins/redirect URIs.

Symptom: Google Sign-In returns null tokens
- Fix: Verify `google_sign_in` package is configured properly, the device/emulator has Google Play Services and at least one account.

Symptom: Firestore write permission denied
- Fix: Check Firestore security rules and ensure authenticated users have write access to their own `users/{uid}` document.

---

## Quick reference (one-page checks)

Web quick check:
- [ ] `localhost` in Firebase authorized domains
- [ ] `flutter run -d chrome` → sign-in popup opens

Android quick check:
- [ ] SHA-1 added to Firebase
- [ ] `google-services.json` placed in `android/app/`
- [ ] Device/emulator has Google Play Services

iOS quick check:
- [ ] `GoogleService-Info.plist` added to `ios/Runner`
- [ ] URL scheme present in `Info.plist`
- [ ] Test on real device

Duplicate-account quick check:
- [ ] Signup with existing account shows modal
- [ ] "Yes" accepts and navigates to home
- [ ] "No" signs out and allows retry with another account

---

## Next steps & optional enhancements

- Account linking: let users link Google account to an existing email/password account.
- Add other social providers (Apple, Facebook) following the same pattern.
- Improve UX: remember user preference for duplicate resolution.
- Clean up linter warnings (remove `print` calls, update deprecated APIs, address `use_build_context_synchronously` warnings).

---

## Where to find source files

- Controllers: `lib/auth/controllers/google_signin_controller.dart`
- Auth service: `lib/services/firebase/auth_service.dart`
- Firestore helpers: `lib/services/firebase/firestore_service.dart`
- Login/Signup UI: `lib/auth/login_screen.dart`, `lib/auth/signup_screen.dart`
- Web config: `web/index.html`
- Android manifest: `android/app/src/main/AndroidManifest.xml`
- iOS Info: `ios/Runner/Info.plist`

---

If you'd like, I can now:
- Replace the old separate .md files with this new consolidated file (delete/archive them), or
- Keep the original files and simply add this consolidated document (I created it already).

Tell me if you want me to also remove or archive the old .md files, and whether to commit these changes to the current branch.
