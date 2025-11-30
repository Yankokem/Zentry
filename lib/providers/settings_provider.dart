import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsProvider extends ChangeNotifier {
  // Font settings
  double _fontSize = 1.0; // Scale factor (1.0 = normal)

  // Notification settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _reminderNotifications = true;

  // Privacy settings
  bool _analyticsEnabled = true;
  bool _crashReporting = true;

  // Language settings
  String _language = 'English';

  // Available languages
  static const List<String> availableLanguages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
  ];

  // Font size options
  static const List<double> fontSizeOptions = [0.8, 0.9, 1.0, 1.1, 1.2, 1.3];

  // SharedPreferences keys
  static const String _fontSizeKey = 'font_size';
  static const String _pushNotificationsKey = 'push_notifications';
  static const String _emailNotificationsKey = 'email_notifications';
  static const String _reminderNotificationsKey = 'reminder_notifications';
  static const String _analyticsEnabledKey = 'analytics_enabled';
  static const String _crashReportingKey = 'crash_reporting';
  static const String _languageKey = 'language';

  // Getters
  double get fontSize => _fontSize;
  bool get pushNotifications => _pushNotifications;
  bool get emailNotifications => _emailNotifications;
  bool get reminderNotifications => _reminderNotifications;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get crashReporting => _crashReporting;
  String get language => _language;

  // Get font size label
  String get fontSizeLabel {
    switch (_fontSize) {
      case 0.8:
        return 'Small';
      case 0.9:
        return 'Medium Small';
      case 1.0:
        return 'Normal';
      case 1.1:
        return 'Medium Large';
      case 1.2:
        return 'Large';
      case 1.3:
        return 'Extra Large';
      default:
        return 'Normal';
    }
  }

  SettingsProvider() {
    _loadSettingsFromPrefs();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettingsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble(_fontSizeKey) ?? 1.0;
    _pushNotifications = prefs.getBool(_pushNotificationsKey) ?? true;
    _emailNotifications = prefs.getBool(_emailNotificationsKey) ?? true;
    _reminderNotifications = prefs.getBool(_reminderNotificationsKey) ?? true;
    _analyticsEnabled = prefs.getBool(_analyticsEnabledKey) ?? true;
    _crashReporting = prefs.getBool(_crashReportingKey) ?? true;
    _language = prefs.getString(_languageKey) ?? 'English';
    notifyListeners();
  }

  // Set font size
  Future<void> setFontSize(double size) async {
    if (fontSizeOptions.contains(size)) {
      _fontSize = size;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, size);
    }
  }

  // Set notification settings
  Future<void> setPushNotifications(bool value) async {
    _pushNotifications = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushNotificationsKey, value);
  }

  Future<void> setEmailNotifications(bool value) async {
    _emailNotifications = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailNotificationsKey, value);
  }

  Future<void> setReminderNotifications(bool value) async {
    _reminderNotifications = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderNotificationsKey, value);
  }

  // Set privacy settings
  Future<void> setAnalyticsEnabled(bool value) async {
    _analyticsEnabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsEnabledKey, value);
  }

  Future<void> setCrashReporting(bool value) async {
    _crashReporting = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_crashReportingKey, value);
  }

  // Set language
  Future<void> setLanguage(String language) async {
    if (availableLanguages.contains(language)) {
      _language = language;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language);
    }
  }

  // Get TextTheme with current settings
  TextTheme getTextTheme(bool isDark) {
    final baseTextTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    // Apply font size scaling using Inter font
    return GoogleFonts.interTextTheme(baseTextTheme).copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: (baseTextTheme.displayLarge?.fontSize ?? 32) * _fontSize,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: (baseTextTheme.displayMedium?.fontSize ?? 28) * _fontSize,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: (baseTextTheme.displaySmall?.fontSize ?? 24) * _fontSize,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: (baseTextTheme.headlineLarge?.fontSize ?? 22) * _fontSize,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: (baseTextTheme.headlineMedium?.fontSize ?? 20) * _fontSize,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: (baseTextTheme.headlineSmall?.fontSize ?? 18) * _fontSize,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: (baseTextTheme.titleLarge?.fontSize ?? 16) * _fontSize,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: (baseTextTheme.titleMedium?.fontSize ?? 14) * _fontSize,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: (baseTextTheme.titleSmall?.fontSize ?? 12) * _fontSize,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: (baseTextTheme.bodyLarge?.fontSize ?? 16) * _fontSize,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: (baseTextTheme.bodyMedium?.fontSize ?? 14) * _fontSize,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: (baseTextTheme.bodySmall?.fontSize ?? 12) * _fontSize,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: (baseTextTheme.labelLarge?.fontSize ?? 14) * _fontSize,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: (baseTextTheme.labelMedium?.fontSize ?? 12) * _fontSize,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: (baseTextTheme.labelSmall?.fontSize ?? 11) * _fontSize,
      ),
    );
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _fontSize = 1.0;
    _pushNotifications = true;
    _emailNotifications = true;
    _reminderNotifications = true;
    _analyticsEnabled = true;
    _crashReporting = true;
    _language = 'English';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, 1.0);
    await prefs.setBool(_pushNotificationsKey, true);
    await prefs.setBool(_emailNotificationsKey, true);
    await prefs.setBool(_reminderNotificationsKey, true);
    await prefs.setBool(_analyticsEnabledKey, true);
    await prefs.setBool(_crashReportingKey, true);
    await prefs.setString(_languageKey, 'English');
  }
}
