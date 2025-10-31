class AppConstants {
  // App Info
  static const String appName = 'Zentry';
  static const String appVersion = '1.0.0';

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXL = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;

  // Animation Durations
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 500);

  // Task Status
  static const String taskPending = 'pending';
  static const String taskCompleted = 'completed';

  // Priority Levels
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
  static const String timeFormat = 'hh:mm a';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 500;

  // UI Messages
  static const String emptyTasks = 'No tasks yet. Create one to get started!';
  static const String emptyJournal = 'Start writing your thoughts...';
  static const String emptyWishlist = 'Add items to your wishlist!';

  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection.';
  static const String errorAuth = 'Authentication failed.';
}
