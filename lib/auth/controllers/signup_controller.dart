import 'package:flutter/material.dart';
import 'package:zentry/services/firebase/auth_service.dart';
import 'package:zentry/services/firebase/firestore_service.dart';

class SignupController {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<bool> signup() async {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _errorMessage = 'Please fill in all fields';
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _errorMessage = 'Passwords do not match';
      return false;
    }

    if (passwordController.text.length < 8) {
      _errorMessage = 'Password must be at least 8 characters';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;

    try {
      final email = emailController.text.trim().toLowerCase();
      
      // Try to create user in Firebase Auth
      await _authService.signUpWithEmailAndPassword(
        email,
        passwordController.text,
      );
      
      // Save user data to Firestore
      final fullName = '${firstNameController.text.trim()} ${lastNameController.text.trim()}';
      await _firestoreService.createUserDocument(
        uid: _authService.currentUser!.uid,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        fullName: fullName,
        email: email,
      );
      
      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseAuthError(e.toString());
      return false;
    }
  }

  /// Parse Firebase Auth error messages into user-friendly messages
  String _parseAuthError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Email already exists. Please use a different email.';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Use at least 8 characters.';
    } else if (error.contains('invalid-email')) {
      return 'Email is not valid. Please enter a valid email.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection.';
    }
    return error.replaceFirst('Exception: ', '');
  }

  void clearError() {
    _errorMessage = null;
  }
}