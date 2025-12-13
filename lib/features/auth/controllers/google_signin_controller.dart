import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/admin/services/admin_notification_service.dart';

class GoogleSignInController with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Check if user exists in Firestore by email
  Future<bool> checkIfUserExists(String email) async {
    try {
      return await _firestoreService.userExistsByEmail(email);
    } catch (e) {
      // Error checking user existence
      return false;
    }
  }

  // Handle Google Sign-In for signup (with existing account check)
  Future<Map<String, dynamic>> signUpWithGoogleAndCheckExisting() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Starting Google Sign-In process for signup

      // Call AuthService to handle Google sign-in
      final UserCredential userCredential =
          await _authService.signInWithGoogle();
      final User? user = userCredential.user;

      if (user == null) {
        _errorMessage = 'Google sign-in failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'userExists': false};
      }

      // Google Sign-In successful

      // Check if user already exists in Firestore
      final userExists =
          await _firestoreService.userExistsByEmail(user.email ?? '');

      if (userExists) {
        // User already exists
        _isLoading = false;
        _errorMessage = '';
        notifyListeners();
        return {
          'success': true,
          'userExists': true,
          'user': user,
          'message': 'Google Account already exists. Sign in with this account?'
        };
      }

      // Create new user document in Firestore (user doesn't exist)
      await _firestoreService.createGoogleUserDocument(user);

      // Initialize user metadata for admin tracking
      final adminService = AdminService();
      await adminService.initializeUserMetadata(user.uid);

      // Notify admin of new Google user registration
      final adminNotificationService = AdminNotificationService();
      await adminNotificationService.notifyNewUser(
        userId: user.uid,
        userName: user.displayName ?? 'Google User',
        userEmail: user.email ?? 'No Email',
      );

      // User document created in Firestore

      _isLoading = false;
      _errorMessage = '';
      notifyListeners();
      return {
        'success': true,
        'userExists': false,
        'user': user,
        'message': 'Account created successfully!'
      };
    } catch (e) {
      _errorMessage = _parseAuthError(e.toString());
      // Google Sign-In error
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'userExists': false, 'error': e.toString()};
    }
  }

  // Handle Google Sign-In (legacy method for login page)
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Starting Google Sign-In process

      // Call AuthService to handle Google sign-in
      final UserCredential userCredential =
          await _authService.signInWithGoogle();
      final User? user = userCredential.user;

      if (user == null) {
        _errorMessage = 'Google sign-in failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create or update user document in Firestore
      await _firestoreService.createGoogleUserDocument(user);

      // User document created/updated in Firestore

      _isLoading = false;
      _errorMessage = '';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseAuthError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Parse authentication errors into user-friendly messages
  String _parseAuthError(String error) {
    // Parsing auth error

    if (error.contains('network') || error.contains('Network')) {
      return 'Network error. Please check your connection.';
    } else if (error.contains('cancelled') || error.contains('Cancelled')) {
      return 'Google sign-in was cancelled.';
    } else if (error.contains('sign_in_failed') ||
        error.contains('sign_in_failed')) {
      return 'Failed to sign in with Google. Please try again.';
    } else if (error.contains('invalid_client') ||
        error.contains('INVALID_CLIENT')) {
      return 'Google sign-in configuration error. Please contact support.';
    } else if (error.contains('DEVELOPER_ERROR') ||
        error.contains('developer')) {
      return 'Google sign-in configuration error. Please check Firebase console configuration.';
    } else if (error.contains('Google sign-in was cancelled')) {
      return 'Google sign-in was cancelled.';
    } else if (error.contains('authentication tokens')) {
      return 'Failed to get Google authentication tokens. Please try again.';
    } else {
      // Return the actual error for debugging
      return 'Google sign-in failed: $error';
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Sign out from Google and Firebase
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
}
