import 'package:flutter/material.dart';

import 'package:zentry/core/core.dart';

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
  String? _profileImageUrl;
  
  @override
  void initState() {
    super.initState();
    _loadUser();
  }
  


  Future<void> _loadUser() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        String newFirstName = '';
        String newFullName = '';
        String newEmail = user.email ?? '';
        String? newProfileImageUrl;

        final displayName = user.displayName ?? '';
        if (displayName.isNotEmpty) {
          newFullName = displayName;
          newFirstName = displayName.split(' ').first;
        }

        // Try to get Firestore-stored data
        final data = await _firestoreService.getUserData(user.uid);
        if (data != null) {
          if (newFirstName.isEmpty) {
            newFirstName = (data['firstName'] ?? '') as String;
          }
          if (newFullName.isEmpty) {
            newFullName = (data['fullName'] ?? '') as String;
          }
          // Load profile image URL from Firestore
          newProfileImageUrl = (data['profileImageUrl'] as String?);
        }

        // Update state with all values at once
        if (mounted) {
          setState(() {
            _firstName = newFirstName;
            _fullName = newFullName;
            _email = newEmail;
            _profileImageUrl = newProfileImageUrl;
            if (newProfileImageUrl != null) {
              debugPrint('Loaded profile image URL: $newProfileImageUrl');
            } else {
              debugPrint('No profile image URL found');
            }
          });
        }
      }
    } catch (_) {
      // ignore and fallback to defaults
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
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
                image: _profileImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_profileImageUrl!),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          // Image failed to load, fallback to gradient
                          debugPrint(
                              'Failed to load profile image: $exception');
                        },
                      )
                    : null,
                gradient: _profileImageUrl == null
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _profileImageUrl == null
                  ? const Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFF1E1E1E),
                    )
                  : null,
            ),

            const SizedBox(height: 24),

            // Username (show full name)
            Text(
              _fullName.isNotEmpty
                  ? _fullName
                  : (_firstName.isNotEmpty ? _firstName : 'User'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 8),

            // Email
            Text(
              _email.isNotEmpty ? _email : 'No email available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
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
                    'Account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Account Settings
                  _ProfileOption(
                    icon: Icons.manage_accounts_rounded,
                    title: 'Account Settings',
                    subtitle: 'Update your profile and credentials',
                    onTap: () async {
                      // Navigate to account settings and refresh profile when returning
                      await Navigator.pushNamed(
                          context, AppRoutes.accountSettings);
                      // Reload user data when returning to profile
                      await _loadUser();
                    },
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Preferences',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Appearance
                  _ProfileOption(
                    icon: Icons.palette_rounded,
                    title: 'Appearance',
                    subtitle: 'Customize theme and display',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.appearance);
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


// Profile Option Widget
class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
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