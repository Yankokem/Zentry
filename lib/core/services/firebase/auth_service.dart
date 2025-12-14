import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Initialize GoogleSignIn with clientId
  // For Android: Use the Web client ID (OAuth 2.0 client ID of type "Web application")
  // For iOS: Use the iOS client ID
  // For Web: Use the Web client ID
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb 
      ? '1038744556460-shj37ippgd0ate0nin6hihp8qbonvdee.apps.googleusercontent.com'
      : (defaultTargetPlatform == TargetPlatform.iOS)
        ? '1038744556460-lm9d4l2aqo31ojurpd4nq5hmtef2gh9m.apps.googleusercontent.com'
        : '1038744556460-shj37ippgd0ate0nin6hihp8qbonvdee.apps.googleusercontent.com', // Android uses Web client ID
    scopes: [
      'email',
      'profile',
    ],
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // For web platform, use Firebase popup
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        
        // Add scopes
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        // Set custom parameters
        googleProvider.setCustomParameters({
          'prompt': 'select_account'
        });
        
        // Sign in with popup
        final UserCredential userCredential = 
            await _auth.signInWithPopup(googleProvider);
        
        return userCredential;
      }
      
      // For mobile and desktop platforms, use google_sign_in package
      
      // First, sign out to ensure clean state
      await _googleSignIn.signOut();
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

  // User selected a Google account

      // Obtain the auth details from the Google user
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

  // Obtained authentication tokens

      // Check if tokens are null
      if (googleAuth.idToken == null) {
  // Missing ID token
        String platformMessage = '';
        if (defaultTargetPlatform == TargetPlatform.android) {
          platformMessage = '\n\nAndroid: Ensure SHA-1 certificate is added to Firebase Console';
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          platformMessage = '\n\niOS: Ensure Bundle ID matches Firebase Console configuration';
        }
        throw Exception('Failed to get Google ID token. Check Firebase Console configuration.$platformMessage');
      }

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken!,
      );

  // Created OAuth credential

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

  // Successfully signed into Firebase

      return userCredential;
    } on FirebaseAuthException catch (e) {
  // FirebaseAuthException during Google sign-in
      throw _handleAuthException(e);
    } catch (e) {
  // General exception during Google sign-in
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  // Sign out (also signs out from Google)
  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Re-authenticate the current user using Google OAuth.
  /// On mobile/desktop this uses the GoogleSignIn flow and calls
  /// `reauthenticateWithCredential` on the current user with the
  /// obtained OAuth credential. On web it uses `signInWithPopup`.
  Future<void> reauthenticateWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});

        // signInWithPopup will refresh the authentication for current session
        final UserCredential cred = await _auth.signInWithPopup(googleProvider);

        // If the re-authenticated email doesn't match the current user's email,
        // throw an error to avoid accidental account switch.
        if ((cred.user?.email ?? '') != (user.email ?? '')) {
          throw Exception('Selected Google account does not match your current account');
        }

        return;
      }

      // For mobile/desktop, trigger Google Sign-In to obtain tokens
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token. Check Firebase Console configuration.');
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Reauthenticate the current user
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google re-authentication failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      // On mobile/desktop, sign out and disconnect the GoogleSignIn
      // Disconnect revokes the previous grant and clears the cached
      // account so the next signIn() will prompt account selection.
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}
    }

    await _auth.signOut();
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'email-already-in-use':
        return Exception('An account already exists for that email.');
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided for that user.');
      case 'invalid-email':
        return Exception('The email address is badly formatted.');
      default:
        return Exception('An error occurred: ${e.message}');
    }
  }
}
