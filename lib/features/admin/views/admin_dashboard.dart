import 'package:flutter/material.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/admin/admin.dart';
import 'package:zentry/features/admin/services/admin_notification_service.dart';
import 'package:zentry/features/admin/views/admin_notifications_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  final AdminNotificationService _notificationService = AdminNotificationService();
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AdminOverviewPage(),
    AdminAccountsPage(),
    AdminBugReportsPage(),
    AdminAppealsPage(),
  ];

  final List<_NavItemData> _navItems = const [
    _NavItemData(icon: Icons.analytics_rounded, label: 'Overview', title: 'Overview'),
    _NavItemData(icon: Icons.people_rounded, label: 'Accounts', title: 'Account Management'),
    _NavItemData(icon: Icons.bug_report_rounded, label: 'Reports', title: 'Bug Reports'),
    _NavItemData(icon: Icons.security_rounded, label: 'Appeals', title: 'Account Appeals'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF9ED69),
                  const Color(0xFFF9ED69).withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 16, 12),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/bgremove.png',
                      height: 32,
                      width: 32,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _navItems[_currentIndex].title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                    StreamBuilder<int>(
                      stream: _notificationService.getUnreadCountStream(),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                color: Color(0xFF1E1E1E),
                              ),
                              tooltip: 'Notifications',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminNotificationsScreen(),
                                  ),
                                );
                              },
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFF1E1E1E),
                      ),
                      tooltip: 'Logout',
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content:
                                const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true) {
                          await _authService.signOut();
                          if (!mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.login,
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_navItems.length, (index) {
          return _NavItem(
            icon: _navItems[index].icon,
            label: _navItems[index].label,
            isSelected: _currentIndex == index,
            onTap: () {
              setState(() {
                _currentIndex = index;
              });
            },
          );
        }),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final String title;

  const _NavItemData({
    required this.icon,
    required this.label,
    required this.title,
  });
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF9ED69).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFF9ED69) : Colors.grey[400],
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFF9ED69),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
