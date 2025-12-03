# Fix Login Issue for pau@gmail.com

## Tasks
- [ ] Modify LoginController to try Firebase Auth first instead of Firestore check
- [ ] If Auth succeeds, ensure Firestore document exists (create if not)
- [ ] If Auth fails, provide appropriate error message
- [ ] Test the login functionality

## Information Gathered
- Current login flow: Check Firestore -> Auth sign-in
- Issue: User exists in Firebase Auth but not Firestore, causing "Email not found" error
- Solution: Auth first, then sync Firestore document

## Dependent Files
- lib/auth/controllers/login_controller.dart
