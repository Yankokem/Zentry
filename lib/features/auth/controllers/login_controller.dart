import 'package:flutter/material.dart';

import 'package:zentry/core/core.dart';

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

  Future<bool> login(BuildContext context) async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _errorMessage = 'Please fill in all fields';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;

    try {
      final email = emailController.text.trim().toLowerCase();
      final password = passwordController.text.trim();

      // First, attempt to sign in with Firebase Auth
      final userCredential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      final userId = userCredential.user!.uid;

      // If Auth succeeds, ensure Firestore document exists
      try {
        final userExists = await _firestoreService.userExistsByEmail(email);
        if (!userExists) {
          // Create Firestore document for existing Auth user
          await _firestoreService.createUserDocument(
            uid: userId,
            firstName: 'User',
            lastName: '',
            fullName: 'User',
            email: email,
          );
          
          // Initialize user metadata for admin tracking
          final adminService = AdminService();
          await adminService.initializeUserMetadata(userId);
        }
      } catch (firestoreError) {
        debugPrint('Firestore error during login: $firestoreError');
      }

      // Check user status and auto-reactivate if suspension expired
      final adminService = AdminService();
      final status = await adminService.checkAndUpdateSuspensionStatus(userId);

      // If user is suspended or banned, sign them out and show dialog
      if (status == 'suspended' || status == 'banned') {
        await _authService.signOut();
        
        // Get metadata for details
        final metadata = await adminService.getUserMetadata(userId);
        final reason = status == 'suspended'
            ? (metadata?['suspensionReason'] ?? 'Account suspended')
            : (metadata?['banReason'] ?? 'Account banned');
        final duration = metadata?['suspensionDuration'] ?? '';

        _isLoading = false;
        
        // Show status dialog with appeal option
        if (context.mounted) {
          await _showAccountStatusDialog(
            context,
            status: status,
            reason: reason,
            duration: duration,
            userId: userId,
            userEmail: email,
          );
        }
        
        return false;
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      debugPrint('Login error: $e');
      _errorMessage = _parseAuthError(e.toString());
      return false;
    }
  }

  /// Show dialog for suspended/banned users with appeal option
  Future<void> _showAccountStatusDialog(
    BuildContext context, {
    required String status,
    required String reason,
    required String duration,
    required String userId,
    required String userEmail,
  }) async {
    final isSuspended = status == 'suspended';
    final color = isSuspended ? Colors.orange : Colors.red;
    final icon = isSuspended ? Icons.pause_circle_outline : Icons.block;
    final title = isSuspended ? 'Account Suspended' : 'Account Banned';
    
    String message;
    if (isSuspended) {
      message = 'Your account is suspended for $duration.\n\nReason: $reason\n\nPlease contact zentry_admin@zentry.app.com for account appeals.';
    } else {
      message = 'Your account is banned.\n\nReason: $reason\n\nPlease contact zentry_admin@zentry.app.com for account appeals.';
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              // Appeal Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      '/account-appeal',
                      arguments: {
                        'userId': userId,
                        'userEmail': userEmail,
                        'status': status,
                      },
                    );
                  },
                  icon: const Icon(Icons.edit_document),
                  label: const Text('Appeal This Action'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Close Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    } else if (error.contains('permission-denied')) {
      return 'Permission error. Please try again later or contact support.';
    }
    return 'Login failed. Please check your credentials.';
  }

  void clearError() {
    _errorMessage = null;
  }
}