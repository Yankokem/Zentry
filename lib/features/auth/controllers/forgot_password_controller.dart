import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zentry/core/core.dart';
import 'package:zentry/core/utils/password_validator.dart';

class ForgotPasswordController {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  /// Reset password using OOB code from Firebase email link
  Future<bool> resetPasswordWithCode(String oobCode) async {
    if (newPasswordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      _errorMessage = 'Please fill in all fields';
      _successMessage = null;
      return false;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      _errorMessage = 'Passwords do not match';
      _successMessage = null;
      return false;
    }

    // Validate password strength
    final passwordError = PasswordValidator.validatePassword(newPasswordController.text);
    if (passwordError != null) {
      _errorMessage = passwordError;
      _successMessage = null;
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;

    try {
      // Verify the OOB code is valid and get the email
      await _auth.verifyPasswordResetCode(oobCode);
      
      // Confirm the password reset with the OOB code
      await _auth.confirmPasswordReset(
        code: oobCode,
        newPassword: newPasswordController.text.trim(),
      );

      _isLoading = false;
      _successMessage = 'Password reset successfully!';
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _parseAuthError(e.code);
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An error occurred: ${e.toString()}';
      return false;
    }
  }

  /// Reset password for the current user (used if already logged in)
  Future<bool> resetPassword() async {
    if (newPasswordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      _errorMessage = 'Please fill in all fields';
      _successMessage = null;
      return false;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      _errorMessage = 'Passwords do not match';
      _successMessage = null;
      return false;
    }

    // Validate password strength
    final passwordError = PasswordValidator.validatePassword(newPasswordController.text);
    if (passwordError != null) {
      _errorMessage = passwordError;
      _successMessage = null;
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _errorMessage = 'User not authenticated. Please try again.';
        _isLoading = false;
        return false;
      }

      // Update the password
      await user.updatePassword(newPasswordController.text.trim());

      _isLoading = false;
      _successMessage = 'Password reset successfully!';
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _parseAuthError(e.code);
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An error occurred: ${e.toString()}';
      return false;
    }
  }

  /// Parse Firebase Auth error messages into user-friendly messages
  String _parseAuthError(String error) {
    switch (error) {
      case 'invalid-action-code':
        return 'This password reset link has expired. Please request a new one.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'User not found.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'requires-recent-login':
        return 'Please log in again before changing your password.';
      case 'network':
        return 'Network error. Please check your connection.';
      default:
        return error.replaceFirst('Exception: ', '');
    }
  }

  void clearError() {
    _errorMessage = null;
  }

  void clearSuccess() {
    _successMessage = null;
  }
}
