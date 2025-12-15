import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/core/utils/password_validator.dart';
import 'package:zentry/features/auth/auth.dart';

/// Formatter to capitalize the first letter of each word
class CapitalizeWordsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final List<String> words = newValue.text.split(' ');
    final List<String> capitalizedWords = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();

    final String capitalizedText = capitalizedWords.join(' ');

    return newValue.copyWith(
      text: capitalizedText,
      selection: TextSelection.fromPosition(
        TextPosition(offset: capitalizedText.length),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final SignupController _controller = SignupController();
  late final GoogleSignInController _googleController;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _googleController = GoogleSignInController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _googleController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {});
      bool success = await _controller.signup();
      setState(() {});
      if (success) {
        if (!mounted) return;
        // Show success message and redirect to login
        _showSuccessDialog('Account Created', 'Account created successfully! Please log in.');
        // Redirect to login page
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  void _handleGoogleSignUp() async {
    try {
      // Use the signup-specific method that checks for existing accounts
      final result = await _googleController.signUpWithGoogleAndCheckExisting();
      
      if (!mounted) return;

      if (result['success'] == true) {
        if (result['userExists'] == true) {
          // User already exists - show dialog
          _showExistingAccountDialog(result['message'] ?? 'Account already exists');
        } else {
          // New account created - navigate to home
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } else {
        // Show error message
        final errorMsg = result['error']?.toString() ?? _googleController.errorMessage;
        _showErrorDialog('Sign Up Error', errorMsg.toString());
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Google Sign Up Failed', 'Google sign-up failed: ${e.toString()}');
      }
    }
  }

  void _showExistingAccountDialog(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Account Already Exists'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              // User chose "No" - sign out and close dialog
              Navigator.pop(dialogContext);
              _googleController.signOut();
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              // User chose "Yes" - close dialog and navigate to home (already signed in)
              Navigator.pop(dialogContext);
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Create Account
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 60),
                
                // First Name Field
                TextFormField(
                  controller: _controller.firstNameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [CapitalizeWordsFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    hintText: 'Enter your first name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    if (value.length < 2) {
                      return 'First name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Last Name Field
                TextFormField(
                  controller: _controller.lastNameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [CapitalizeWordsFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    hintText: 'Enter your last name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    if (value.length < 2) {
                      return 'Last name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Email Field
                TextFormField(
                  controller: _controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
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
                
                const SizedBox(height: 16),
                
                // Password Field
                TextFormField(
                  controller: _controller.passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    return PasswordValidator.validatePassword(value);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Confirm Password Field
                TextFormField(
                  controller: _controller.confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _controller.passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Error Message
                if (_controller.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
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
                
                if (_controller.errorMessage != null) const SizedBox(height: 16),
                
                // Sign Up Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _controller.isLoading ? null : _handleSignup,
                    child: _controller.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Sign Up'),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                            ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Social Login Buttons
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
                            : _handleGoogleSignUp,
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
                              ? 'Signing up...'
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
                
                const SizedBox(height: 40),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Login',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}