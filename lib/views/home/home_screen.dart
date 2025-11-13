import 'package:flutter/material.dart';
import 'package:zentry/widgets/common/floating_nav_bar.dart';
import 'package:zentry/views/home/home_page.dart';
import 'package:zentry/views/home/projects_page.dart'; // NEW
import 'package:zentry/views/home/journal_page.dart';
import 'package:zentry/views/home/wishlist_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ProjectsPage(), // CHANGED from TasksPage to ProjectsPage
    const JournalPage(),
    const WishlistPage(),
  ];

  @override
  Widget build(BuildContext context) {
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
      ),
    );
  }
}