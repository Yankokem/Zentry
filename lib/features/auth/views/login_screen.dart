import 'package:flutter/material.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/auth/auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final LoginController _controller = LoginController();
  late final GoogleSignInController _googleController;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _googleController = GoogleSignInController();
    // Listen to email field changes to update UI state
    _controller.emailController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _googleController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {});
      bool success = await _controller.login(context);
      setState(() {});
      if (success) {
        if (!mounted) return;

        // Check if user is admin and redirect accordingly
        final adminService = AdminService();
        final isAdmin = await adminService.isAdmin();

        if (isAdmin) {
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      }
    }
  }

  void _handleGoogleSignIn() async {
    try {
      bool success = await _googleController.signInWithGoogle();
      if (success && mounted) {
        // Check if user is admin and redirect accordingly
        final adminService = AdminService();
        final isAdmin = await adminService.isAdmin();

        if (isAdmin) {
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } else if (mounted) {
        // Show error message
        _showErrorDialog('Google Sign In Failed', _googleController.errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Google Sign-in Failed', 'Failed to sign in with Google: $e');
      }
    }
  }

  void _sendForgotPasswordEmail() async {
    final email = _controller.emailController.text.trim().toLowerCase();
    
    if (email.isEmpty) {
      _showErrorDialog('Error', 'Please enter your email first');
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Send password reset email
      final authService = AuthService();
      await authService.sendPasswordResetEmail(email);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show success message
      _showSuccessDialog('Password Reset', 'Password reset email sent! Please check your email and click the link.');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      _showErrorDialog('Reset Failed', 'Failed to send password reset email: ${e.toString()}');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        icon: const Icon(Icons.error, color: Colors.red, size: 32),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDF6B2),
              Color(0xFFF9ED69),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                centerTitle: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),

                        // Logo
                        Center(
                          child: Image.asset(
                            'assets/images/bgremove.png',
                            width: 100,
                            height: 100,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Welcome Back
                        const Text(
                          'Zentry',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to continue your journey.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Email Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _controller.emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'Enter your email address',
                              hintStyle: TextStyle(color: Colors.black38),
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: Colors.black),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _controller.passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: const TextStyle(color: Colors.black38),
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Colors.black),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length <
                                  AppConstants.minPasswordLength) {
                                return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _controller.emailController.text.isEmpty
                                ? null
                                : () {
                                    // Send forgot password email
                                    _sendForgotPasswordEmail();
                                  },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: _controller.emailController.text.isEmpty
                                    ? Colors.black26
                                    : Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Error Message
                        if (_controller.errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _controller.errorMessage!,
                              style: TextStyle(color: Colors.red.shade800),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Login Button
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed:
                                _controller.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _controller.isLoading
                                ? const CircularProgressIndicator()
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.black26,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Or',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.black26,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Google Login Button
                        ListenableBuilder(
                          listenable: _googleController,
                          builder: (context, child) {
                            return Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: OutlinedButton.icon(
                                onPressed: _googleController.isLoading
                                    ? null
                                    : _handleGoogleSignIn,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                icon: _googleController.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'G',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                label: Text(
                                  _googleController.isLoading
                                      ? 'Signing in...'
                                      : 'Continue with Google',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.signup);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
