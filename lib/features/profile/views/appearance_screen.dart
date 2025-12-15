import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:zentry/core/core.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
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
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              settingsProvider.resetToDefaults();
              _showSuccessDialog('Settings Reset', 'Settings reset to defaults');
            },
            child: Text(
              'Reset',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Section
              Text(
                'Theme',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),

              // Dark Mode Toggle
              _SettingsCard(
                title: 'Dark Mode',
                subtitle: themeProvider.isDarkMode
                    ? 'Using dark theme'
                    : 'Using light theme',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          themeProvider.isDarkMode ? 'Dark' : 'Light',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                      activeThumbColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Display Section
              Text(
                'Display',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),

              // Font Size Setting
              _SettingsCard(
                title: 'Font Size',
                subtitle:
                    'Adjust text size (${settingsProvider.fontSizeLabel})',
                child: Column(
                  children: [
                    Slider(
                      value: settingsProvider.fontSize,
                      min: SettingsProvider.fontSizeOptions.first,
                      max: SettingsProvider.fontSizeOptions.last,
                      divisions: SettingsProvider.fontSizeOptions.length - 1,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (value) {
                        settingsProvider.setFontSize(value);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: SettingsProvider.fontSizeOptions.map((size) {
                        return Text(
                          _getFontSizeLabel(size),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Preview Section
              Text(
                'Preview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),

              // Font Preview Card
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample Text',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This is how your text will look with the current settings. You can adjust the font family and size above to see how it affects the appearance.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Smaller text for details and labels.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Info Section
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Changes are automatically saved and applied throughout the app.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFontSizeLabel(double size) {
    switch (size) {
      case 0.8:
        return 'S';
      case 0.9:
        return 'M';
      case 1.0:
        return 'N';
      case 1.1:
        return 'L';
      case 1.2:
        return 'XL';
      case 1.3:
        return 'XXL';
      default:
        return 'N';
    }
  }
}

// Settings Card Widget
class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
