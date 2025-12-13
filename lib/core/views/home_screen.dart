import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/projects/projects.dart';
import 'package:zentry/features/journal/journal.dart';
import 'package:zentry/features/wishlist/wishlist.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ValueNotifier<String> _projectsFilterNotifier = ValueNotifier<String>('all');
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _updateUserLastActive();
  }

  /// Update the current user's last active timestamp
  Future<void> _updateUserLastActive() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _adminService.updateLastActive(user.uid);
      }
    } catch (e) {
      debugPrint('Error updating last active: $e');
    }
  }

  void _onNavigateToProjects(String? filter) {
    if (filter != null) {
      _projectsFilterNotifier.value = filter;
    }
    setState(() {
      _selectedIndex = 1; // Projects tab index
    });
  }

  void _onNavigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late final List<Widget> _pages = [
    HomePage(
      onNavigateToProjects: _onNavigateToProjects,
      onNavigateToTab: _onNavigateToTab,
    ),
    ProjectsPage(filterNotifier: _projectsFilterNotifier, initialFilter: 'all'),
    const JournalPage(),
    const WishlistPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      extendBody: true,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        wishlistController: wishlistProvider.isInitialized ? wishlistProvider.controller : null,
      ),
    );
  }
}
