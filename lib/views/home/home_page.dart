import 'package:flutter/material.dart';
import 'package:zentry/config/constants.dart';
import 'package:zentry/config/routes.dart';
import 'package:zentry/utils/admin_mode.dart';
import 'package:zentry/services/firebase/auth_service.dart';
import 'package:zentry/services/firebase/firestore_service.dart';

import 'package:zentry/widgets/home/task_card.dart';
import 'package:zentry/widgets/home/wish_card.dart';
import 'package:zentry/widgets/home/recent_journal_card.dart';
import 'package:zentry/widgets/home/calendar_dialog.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zentry/services/firebase/journal_service.dart';
import 'package:zentry/models/journal_entry_model.dart';
import 'package:zentry/models/project_model.dart';
import 'package:zentry/models/wish_model.dart';
import 'package:zentry/providers/wishlist_provider.dart';
import 'package:zentry/widgets/home/project_card.dart';
import 'package:zentry/views/home/project_detail_page.dart';
import 'package:zentry/views/home/add_project_page.dart';
import 'package:zentry/views/home/projects_page.dart';
import 'package:zentry/services/project_manager.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final Function(String? filter)? onNavigateToProjects;

  const HomePage({super.key, this.onNavigateToProjects});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final JournalService _journalService = JournalService();

  StreamSubscription<List<JournalEntry>>? _journalSubscription;
  StreamSubscription<User?>? _authSubscription;

  String _firstName = '';
  List<Project> _sharedProjects = [];
  List<JournalEntry> _recentJournalEntries = [];
  List<Wish> _wishlistItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadData();
    _subscribeToJournalEntries();
  }

  void _subscribeToJournalEntries() {
    // If user is already signed in, subscribe immediately
    if (_authService.currentUser != null) {
      _journalSubscription = _journalService.getEntriesStream().listen((entries) {
        if (!mounted) return;
        setState(() {
          _recentJournalEntries = entries.take(1).toList();
        });
      }, onError: (err) {
        debugPrint('Journal stream error: $err');
      });
      return;
    }

    // Otherwise wait for auth state to become available, then subscribe
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        // Cancel auth listener once we have a user
        _authSubscription?.cancel();
        _authSubscription = null;

        _journalSubscription = _journalService.getEntriesStream().listen((entries) {
          if (!mounted) return;
          setState(() {
            _recentJournalEntries = entries.take(1).toList();
          });
        }, onError: (err) {
          debugPrint('Journal stream error: $err');
        });
      }
    }, onError: (err) {
      debugPrint('Auth state stream error: $err');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load data when dependencies change (e.g., provider initialization)
    if (_isLoading) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _journalSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      final user = _authService.currentUser;
      String firstName = '';

      if (user != null) {
        // Try displayName first
        final displayName = user.displayName ?? '';
        if (displayName.isNotEmpty) {
          firstName = displayName.split(' ').first;
        } else {
          // Fallback to Firestore stored firstName
          final data = await _firestoreService.getUserData(user.uid);
          if (data != null && data['firstName'] != null) {
            firstName = data['firstName'] as String;
          }
        }
      }

      if (mounted) {
        setState(() {
          _firstName = firstName.isNotEmpty ? firstName : 'there';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _firstName = 'there');
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // Load shared projects (projects shared with the user, not owned by them)
      final projects = await _firestoreService.getUserProjects(user.uid, user.email ?? '');
      final sharedProjects = projects.where((project) =>
        project.userId != user.uid && project.teamMembers.contains(user.email ?? '')
      ).toList()
      // Sort by most recently updated first
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      // Load recent journal entries
      final journalEntries = await _journalService.getEntries();
      final recentEntries = journalEntries.take(1).toList(); // Get the most recent entry

      // Load wishlist items
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
      if (wishlistProvider.isInitialized) {
        final wishlistItems = wishlistProvider.controller.wishes.take(3).toList(); // Get first 3 items
        if (mounted) {
          setState(() {
            _sharedProjects = sharedProjects;
            _recentJournalEntries = recentEntries;
            _wishlistItems = wishlistItems;
            _isLoading = false;
          });
        }
      } else {
        // Wait for wishlist to initialize
        await Future.delayed(const Duration(milliseconds: 100));
        _loadData();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'excited':
        return '🤩';
      case 'calm':
      default:
        return '😌';
    }
  }

  IconData _getWishIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'clothing':
        return Icons.checkroom;
      case 'travel':
        return Icons.flight;
      case 'food':
        return Icons.restaurant;
      case 'books':
        return Icons.book;
      case 'sports':
        return Icons.sports_soccer;
      default:
        return Icons.star;
    }
  }

  Widget _buildSharedProjectCard(Project project) {
    Color _getProjectColor() {
      switch (project.color) {
        case 'yellow':
          return const Color(0xFFF9ED69);
        case 'blue':
          return Colors.blue.shade300;
        case 'green':
          return Colors.green.shade300;
        case 'purple':
          return Colors.purple.shade300;
        case 'red':
          return Colors.red.shade300;
        default:
          return const Color(0xFFF9ED69);
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailPage(project: project),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _getProjectColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Project info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (project.isPinned) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.push_pin,
                          size: 14,
                          color: Color(0xFFF9ED69),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${project.teamMembers.length} members',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getProjectColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          project.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getProjectColor().withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Progress indicator
            SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${project.completedTickets}/${project.totalTickets}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: project.totalTickets > 0 ? project.completedTickets / project.totalTickets : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_getProjectColor()),
                    minHeight: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _timeBasedGreeting();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big Gradient Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: const Color(0xFF1E1E1E),
                                ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.calendar_today_outlined),
                                color: const Color(0xFF1E1E1E),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const CalendarDialog(),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                color: const Color(0xFF1E1E1E),
                                onPressed: () {},
                              ),
                              // Admin mode toggle for testing (front-end only)
                              ValueListenableBuilder<bool>(
                                valueListenable: AdminMode.enabled,
                                builder: (context, isAdmin, _) {
                                  return IconButton(
                                    icon: Icon(
                                      Icons.admin_panel_settings,
                                      color: isAdmin
                                          ? Theme.of(context).colorScheme.secondary
                                          : const Color(0xFF1E1E1E),
                                    ),
                                    tooltip: 'Admin Mode (test)',
                                    onPressed: () {
                                      AdminMode.toggle();
                                      final newVal = AdminMode.enabled.value;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(newVal
                                              ? 'Admin mode enabled (test)'
                                              : 'Admin mode disabled'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                      if (newVal) {
                                        Navigator.pushNamed(
                                            context, AppRoutes.adminDashboard);
                                      }
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.person_outline),
                                color: const Color(0xFF1E1E1E),
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, AppRoutes.profile);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Greeting
                              Text(
                                '$greeting, $_firstName!',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: const Color(0xFF1E1E1E),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Let\'s make a productive day today',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF1E1E1E).withOpacity(0.8),
                              fontSize: 15,
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Shared Projects Section
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Shared Projects',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.people_outline,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onNavigateToProjects?.call('shared');
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            if (_sharedProjects.isNotEmpty)
              ..._sharedProjects.take(2).map((project) => _buildSharedProjectCard(project)),
            if (_sharedProjects.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'No shared projects available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Recent Journal Entry
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Journal Entry',
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            if (_recentJournalEntries.isNotEmpty)
              RecentJournalCard(
                date: _recentJournalEntries.first.date,
                emoji: _getMoodEmoji(_recentJournalEntries.first.mood),
                title: _recentJournalEntries.first.title,
                description: _recentJournalEntries.first.content,
              )
            else
              const RecentJournalCard(
                date: 'No entries yet',
                emoji: '😌',
                title: 'No journal entries',
                description: 'Start writing your first journal entry today!',
              ),

            const SizedBox(height: 24),

            // My Wishlist (Personal)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Wishlist',
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium),
                children: _wishlistItems.isNotEmpty
                  ? _wishlistItems.map((wish) => WishCard(
                      title: wish.title,
                      price: '₱${wish.price}',
                      image: _getWishIcon(wish.category),
                    )).toList()
                  : const [
                      WishCard(
                        title: 'No wishlist items yet',
                        price: '',
                        image: Icons.add,
                      ),
                    ],
              ),
            ),

            const SizedBox(height: 100), // Space for floating nav
          ],
        ),
      ),
    );
  }
}