import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zentry/config/constants.dart';
import 'package:zentry/providers/settings_provider.dart';
import 'package:zentry/providers/notification_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              settingsProvider.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
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
                subtitle: 'Adjust text size (${settingsProvider.fontSizeLabel})',
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Notifications Section
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),

              // Push Notifications
              _SettingsCard(
                title: 'Push Notifications',
                subtitle: 'Receive push notifications for important updates',
                child: Switch(
                  value: settingsProvider.pushNotifications,
                  onChanged: (value) {
                    settingsProvider.setPushNotifications(value);
                  },
                  activeThumbColor: Theme.of(context).primaryColor,
                ),
              ),

              const SizedBox(height: 12),

              // Email Notifications
              _SettingsCard(
                title: 'Email Notifications',
                subtitle: 'Receive email notifications for account activity',
                child: Switch(
                  value: settingsProvider.emailNotifications,
                  onChanged: (value) {
                    settingsProvider.setEmailNotifications(value);
                  },
                  activeThumbColor: Theme.of(context).primaryColor,
                ),
              ),







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
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
