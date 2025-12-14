/// Password validation utilities
class PasswordValidator {
  // Special characters allowed for password validation
  static const String _specialCharacters = "!@#\$%^&*()_+-=[]{};:'\",.<>?/\\|`~";

  /// Validates password strength based on requirements:
  /// - At least 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  /// - At least one special character
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for special characters using a safely escaped character class
    const String specialCharacters = "!@#\$%^&*()_+-=[]{};:'\",.<>?/\\|`~";
    final hasSpecialChar = password.contains(RegExp('[${RegExp.escape(specialCharacters)}]'));
    if (!hasSpecialChar) {
      return 'Password must contain at least one special character (!@#\$%^&*)';
    }

    return null;
  }

  /// Get a list of password requirements and their status
  static Map<String, bool> getPasswordRequirements(String password) {
    return {
      'At least 8 characters': password.length >= 8,
      'Contains uppercase letter (A-Z)': password.contains(RegExp(r'[A-Z]')),
      'Contains lowercase letter (a-z)': password.contains(RegExp(r'[a-z]')),
      'Contains number (0-9)': password.contains(RegExp(r'[0-9]')),
      'Contains special character (!@#\$%^&*)': password.contains(RegExp('[${RegExp.escape(_specialCharacters)}]')),
    };
  }
}
