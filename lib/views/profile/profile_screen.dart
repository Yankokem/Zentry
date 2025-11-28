import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zentry/config/constants.dart';
import 'package:zentry/config/routes.dart';
import 'package:zentry/providers/theme_provider.dart';
import 'package:zentry/services/firebase/auth_service.dart';
import 'package:zentry/services/firebase/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  String _firstName = '';
  String _fullName = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final displayName = user.displayName ?? '';
        if (displayName.isNotEmpty) {
          _fullName = displayName;
          _firstName = displayName.split(' ').first;
        }
        _email = user.email ?? '';

        // Try to get Firestore-stored names if displayName not present
        if (_firstName.isEmpty) {
          final data = await _firestoreService.getUserData(user.uid);
          if (data != null) {
            _firstName = (data['firstName'] ?? '') as String;
            _fullName = (data['fullName'] ?? '') as String;
          }
        }
      }
    } catch (_) {
      // ignore and fallback to defaults
    } finally {
      if (mounted) setState(() {});
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close dialog first
              Navigator.pop(dialogContext);
              // Perform sign out
              await _authService.signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _editUsername(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit username feature coming soon!')),
    );
  }

  // Removed time-based greeting (not used in profile)

  @override
  Widget build(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Profile Picture
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Color(0xFF1E1E1E),
              ),
            ),

            const SizedBox(height: 24),

            // Username with Edit Icon (show full name)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _fullName.isNotEmpty
                      ? _fullName
                      : (_firstName.isNotEmpty ? _firstName : 'User'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _editUsername(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Email
            Text(
              _email.isNotEmpty ? _email : 'No email available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),

            const SizedBox(height: 40),

            // Stats Cards
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ProfileStatCard(
                      icon: Icons.check_circle_rounded,
                      count: '42',
                      label: 'Tasks Done',
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _ProfileStatCard(
                      icon: Icons.book_rounded,
                      count: '18',
                      label: 'Journal Entries',
                      color: Colors.purple,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _ProfileStatCard(
                      icon: Icons.star_rounded,
                      count: '7',
                      label: 'Wishes',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Options Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferences',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Dark Mode Toggle
                  _ProfileOption(
                    icon: themeProvider.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: 'Dark Mode',
                    subtitle: themeProvider.isDarkMode
                        ? 'Switch to light theme'
                        : 'Switch to dark theme',
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                      activeThumbColor: Theme.of(context).primaryColor,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Settings
                  _ProfileOption(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    subtitle: 'App preferences and configurations',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings page coming soon!'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // Notifications
                  _ProfileOption(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifications settings coming soon!'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // Privacy
                  _ProfileOption(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy',
                    subtitle: 'Control your privacy settings',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Privacy settings coming soon!'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Support',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Help & Support
                  _ProfileOption(
                    icon: Icons.help_rounded,
                    title: 'Help & Support',
                    subtitle: 'Get help with the app',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.helpSupport);
                    },
                  ),

                  const SizedBox(height: 8),

                  // About
                  _ProfileOption(
                    icon: Icons.info_rounded,
                    title: 'About',
                    subtitle: 'App version and information',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.about);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleLogout(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, color: Colors.red),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Stat Card Widget
class _ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;

  const _ProfileStatCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// Profile Option Widget
class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
          ],
        ),
      ),
    );
  }
}
