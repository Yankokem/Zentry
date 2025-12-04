import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zentry/widgets/common/floating_nav_bar.dart';
import 'package:zentry/views/home/home_page.dart';
import 'package:zentry/views/home/projects_page.dart'; // NEW
import 'package:zentry/views/home/journal_page.dart';
import 'package:zentry/views/home/wishlist_page.dart';
import 'package:zentry/providers/wishlist_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ValueNotifier<String> _projectsFilterNotifier = ValueNotifier<String>('all');

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
