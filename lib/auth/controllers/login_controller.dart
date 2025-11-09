import 'package:flutter/material.dart';
import 'package:zentry/services/firebase/auth_service.dart';
import 'package:zentry/services/firebase/firestore_service.dart';

class LoginController {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }

  Future<bool> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _errorMessage = 'Please fill in all fields';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;

    try {
      final email = emailController.text.trim().toLowerCase();
      
      // First, check if user exists in Firestore
      print('Checking if user exists: $email');
      final userExists = await _firestoreService.userExistsByEmail(email);
      print('User exists result: $userExists');

      if (!userExists) {
        _isLoading = false;
        _errorMessage = 'Email not found. Please sign up first.';
        return false;
      }

      // Attempt to sign in with Firebase Auth
      await _authService.signInWithEmailAndPassword(
        email,
        passwordController.text,
      );

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseAuthError(e.toString());
      print('Login error: $_errorMessage');
      return false;
    }
  }

  /// Parse Firebase Auth error messages into user-friendly messages
  String _parseAuthError(String error) {
    if (error.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (error.contains('user-not-found')) {
      return 'Email not found. Please sign up first.';
    } else if (error.contains('invalid-email')) {
      return 'Email is not valid. Please enter a valid email.';
    } else if (error.contains('user-disabled')) {
      return 'This account has been disabled.';
    } else if (error.contains('too-many-requests')) {
      return 'Too many login attempts. Please try again later.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection.';
    }
    return 'Login failed. Please check your credentials.';
  }

  void clearError() {
    _errorMessage = null;
  }
}