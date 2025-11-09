import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Initialize GoogleSignIn with clientId for web
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb 
      ? '1038744556460-shj37ippgd0ate0nin6hihp8qbonvdee.apps.googleusercontent.com'
      : null,
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
      print('Google Sign-In: Starting authentication flow...');
      print('Google Sign-In: Platform = ${defaultTargetPlatform.name}');
      
      // For web platform, use Firebase popup
      if (kIsWeb) {
        print('Google Sign-In: Using Firebase popup for web...');
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
        
        print('Google Sign-In: Successfully signed in via Firebase popup');
        print('Google Sign-In: User UID = ${userCredential.user?.uid}');
        
        return userCredential;
      }
      
      // For mobile and desktop platforms, use google_sign_in package
      print('Google Sign-In: Using google_sign_in package for ${defaultTargetPlatform.name}...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign-In: User cancelled the sign-in');
        throw Exception('Google sign-in was cancelled');
      }

      print('Google Sign-In: User selected - ${googleUser.email}');

      // Obtain the auth details from the Google user
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('Google Sign-In: Got authentication tokens');
      print('Google Sign-In: accessToken present = ${googleAuth.accessToken != null}');
      print('Google Sign-In: idToken present = ${googleAuth.idToken != null}');

      // Check if tokens are null
      if (googleAuth.idToken == null) {
        print('Google Sign-In: Missing ID token!');
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

      print('Google Sign-In: Created OAuth credential');

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      print('Google Sign-In: Successfully signed into Firebase');
      print('Google Sign-In: User UID = ${userCredential.user?.uid}');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Google Sign-In: FirebaseAuthException - Code: ${e.code}, Message: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Google Sign-In: General Exception - $e');
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  // Sign out (also signs out from Google)
  Future<void> signOut() async {
    if (!kIsWeb) {
      // Only sign out from google_sign_in on mobile/desktop
      await _googleSignIn.signOut();
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
