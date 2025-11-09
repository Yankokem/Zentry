import 'package:flutter/material.dart';
import 'package:zentry/config/constants.dart';
import 'package:zentry/config/routes.dart';
import 'package:zentry/services/firebase/auth_service.dart';
import 'package:zentry/services/firebase/firestore_service.dart';
import 'package:zentry/widgets/home/stat_card.dart';
import 'package:zentry/widgets/home/task_card.dart';
import 'package:zentry/widgets/home/wish_card.dart';
import 'package:zentry/widgets/home/recent_journal_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  String _firstName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
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

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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
                                icon: const Icon(Icons.notifications_outlined),
                                color: const Color(0xFF1E1E1E),
                                onPressed: () {},
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

            // Task Overview Cards
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.check_circle_rounded,
                      count: '10',
                      label: 'Done Today',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.access_time_rounded,
                      count: '5',
                      label: 'Pending',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.trending_up_rounded,
                      count: '15',
                      label: 'Total Tasks',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Shared Tasks Section
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Shared Tasks',
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
                    onPressed: () {},
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            TaskCard(
              title: 'Complete the final documentation',
              time: '10:30 AM',
              priority: 'high',
              assignedTo: 'John Doe',
              isDone: false,
            ),
            TaskCard(
              title: 'Review pull request #342',
              time: '2:00 PM',
              priority: 'medium',
              assignedTo: 'Sarah Lee',
              isDone: false,
            ),
            TaskCard(
              title: 'Update server dependencies',
              time: 'Tomorrow',
              priority: 'medium',
              assignedTo: 'You',
              isDone: false,
            ),

            const SizedBox(height: 24),

            // My Personal Tasks Section
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'My Tasks',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.person_outline,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            TaskCard(
              title: 'Buy groceries',
              time: '4:30 PM',
              priority: 'medium',
              assignedTo: null,
              isDone: false,
            ),
            TaskCard(
              title: 'Call dentist',
              time: 'Tomorrow',
              priority: 'low',
              assignedTo: null,
              isDone: false,
            ),

            const SizedBox(height: 24),

            // Personal Journal Banner
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.shade400,
                      Colors.blue.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'My Journal',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.lock_outline,
                                color: Colors.white.withOpacity(0.8),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Write down your thoughts and feelings',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

            RecentJournalCard(
              date: 'Nov 2, 2025',
              emoji: '😊',
              title: 'A Productive Day',
              description:
                  'Today was amazing! I completed all my tasks and had time to relax. Looking forward to tomorrow and all the new challenges it brings.',
            ),

            const SizedBox(height: 24),

            // My Wishlist (Personal)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'My Wishlist',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
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
                children: [
                  WishCard(
                    title: 'New MacBook Pro',
                    price: '\$2,499',
                    image: Icons.laptop_mac,
                  ),
                  WishCard(
                    title: 'Trip to Japan',
                    price: '\$3,500',
                    image: Icons.flight_takeoff,
                  ),
                  WishCard(
                    title: 'New Camera',
                    price: '\$1,200',
                    image: Icons.camera_alt,
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