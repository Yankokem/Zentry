import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  // KPI stats
  int _totalProjects = 0;
  int _journalEntries = 0;
  int _wishlistItems = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadStats();
  }
  
  Future<void> _loadStats() async {
    int projectCount = 0;
    int journalCount = 0;
    int wishlistCount = 0;
    
    try {
      final user = _authService.currentUser;
      if (user == null) {
        debugPrint('❌ No user logged in');
        return;
      }
      
      debugPrint('🔍 Loading stats for user: ${user.uid} (${user.email})');
      final userEmailLower = user.email?.toLowerCase() ?? '';
      
      final firestore = FirebaseFirestore.instance;
      
      // === PROJECTS COUNT ===
      try {
        final projectsSnapshot = await firestore
            .collection('projects')
            .get();
        
        debugPrint('📊 Total projects in Firestore: ${projectsSnapshot.docs.length}');
        
        projectCount = 0;
        for (final doc in projectsSnapshot.docs) {
          final data = doc.data();
          final projectId = doc.id;
          final deleted = data['deleted'] == true;
          final status = (data['status'] as String? ?? '').trim().toLowerCase();
          final userId = data['userId'] as String?;
          final workspaceMembers = List<String>.from(data['workspaceMembers'] as List? ?? []);
          final sharedWith = List<String>.from(data['sharedWith'] as List? ?? []);
          
          debugPrint('📌 [$projectId] Status: $status | Deleted: $deleted | Owner: $userId');
          debugPrint('   WS Members: $workspaceMembers | SharedWith: $sharedWith');
          
          // Skip deleted projects
          if (deleted) {
            debugPrint('   ⊘ SKIP: deleted');
            continue;
          }
          
          // Skip "finished" status projects
          if (status == 'finished') {
            debugPrint('   ⊘ SKIP: finished status');
            continue;
          }
          
          // Check if user is owner
          final isOwner = userId == user.uid;
          // Check if user is workspace member
          final isWorkspaceMember = workspaceMembers.contains(user.uid);
          // Check if user is in shared list (case-insensitive)
          final isShared = sharedWith.any((email) => email.toLowerCase() == userEmailLower);
          
          debugPrint('   Owner: $isOwner | WS Member: $isWorkspaceMember | Shared: $isShared');
          
          if (isOwner || isWorkspaceMember || isShared) {
            debugPrint('   ✓ INCLUDED');
            projectCount++;
          } else {
            debugPrint('   ⊘ SKIP: not owner/member/shared');
          }
        }
        
        debugPrint('✅ Final project count: $projectCount');
      } catch (e) {
        debugPrint('❌ Error loading projects: $e');
      }
      
      // === JOURNAL ENTRIES COUNT ===
      try {
        final journalSnapshot = await firestore
            .collection('journal_entries')
            .where('userId', isEqualTo: user.uid)
            .get();
        
        debugPrint('📓 Journal entries found: ${journalSnapshot.docs.length}');
        
        journalCount = 0;
        for (final doc in journalSnapshot.docs) {
          final data = doc.data();
          final deleted = data['deleted'] == true;
          
          if (deleted) {
            continue;
          }
          journalCount++;
        }
        
        debugPrint('✅ Final journal count: $journalCount');
      } catch (e) {
        debugPrint('❌ Error loading journal entries: $e');
      }
      
      // === WISHLIST ITEMS COUNT ===
      try {
        final wishlistSnapshot = await firestore
            .collection('wishlists')
            .where('userId', isEqualTo: user.uid)
            .get();
        
        debugPrint('⭐ Total wishlist items for user: ${wishlistSnapshot.docs.length}');
        
        wishlistCount = 0;
        for (final doc in wishlistSnapshot.docs) {
          final data = doc.data();
          final itemTitle = data['title'] as String? ?? 'Unknown';
          final completed = data['completed'] == true;
          
          debugPrint('   Item: "$itemTitle" | Completed: $completed');
          
          // Only count items NOT acquired (completed == false)
          if (completed == false) {
            wishlistCount++;
            debugPrint('      ✓ INCLUDED (not acquired)');
          } else {
            debugPrint('      ⊘ SKIP (acquired)');
          }
        }
        
        debugPrint('✅ Final wishlist count: $wishlistCount');
      } catch (e) {
        debugPrint('❌ Error loading wishlist items: $e');
      }
      
      // Update state with final counts
      if (mounted) {
        setState(() {
          _totalProjects = projectCount;
          _journalEntries = journalCount;
          _wishlistItems = wishlistCount;
          _isLoadingStats = false;
        });
        
        debugPrint('🎯 FINAL: Projects: $_totalProjects | Journals: $_journalEntries | Wishlist: $_wishlistItems');
      }
    } catch (e) {
      debugPrint('❌ Fatal error in _loadStats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
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

            const SizedBox(height: 40),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
              ),
              child: _isLoadingStats
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(
                          child: _ProfileStatCard(
                            icon: Icons.folder_rounded,
                            count: '$_totalProjects',
                            label: 'Total Projects',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ProfileStatCard(
                            icon: Icons.book_rounded,
                            count: '$_journalEntries',
                            label: 'Journal Entries',
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ProfileStatCard(
                            icon: Icons.star_rounded,
                            count: '$_wishlistItems',
                            label: 'Wishlist Items',
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

                  const SizedBox(height: 8),

                  // Notifications
                  _ProfileOption(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.notifications);
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