import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zentry/services/firebase/auth_service.dart';
import 'package:zentry/services/firebase/firestore_service.dart';

class GoogleSignInController with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Handle Google Sign-In
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('Starting Google Sign-In process...');

      // Call AuthService to handle Google sign-in
      final UserCredential userCredential = await _authService.signInWithGoogle();
      final User? user = userCredential.user;

      if (user == null) {
        _errorMessage = 'Google sign-in failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('Google Sign-In successful for: ${user.email}');

      // Create or update user document in Firestore
      await _firestoreService.createGoogleUserDocument(user);

      print('User document created/updated in Firestore');

      _isLoading = false;
      _errorMessage = '';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseAuthError(e.toString());
      print('Google Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Parse authentication errors into user-friendly messages
  String _parseAuthError(String error) {
    print('GoogleSignInController: Parsing error - $error');
    
    if (error.contains('network') || error.contains('Network')) {
      return 'Network error. Please check your connection.';
    } else if (error.contains('cancelled') || error.contains('Cancelled')) {
      return 'Google sign-in was cancelled.';
    } else if (error.contains('sign_in_failed') || error.contains('sign_in_failed')) {
      return 'Failed to sign in with Google. Please try again.';
    } else if (error.contains('invalid_client') || error.contains('INVALID_CLIENT')) {
      return 'Google sign-in configuration error. Please contact support.';
    } else if (error.contains('DEVELOPER_ERROR') || error.contains('developer')) {
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
}
