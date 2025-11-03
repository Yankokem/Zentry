  import 'package:flutter/material.dart';
  import 'package:zentry/config/constants.dart';
  import 'package:zentry/config/routes.dart';
  import 'package:zentry/widgets/common/floating_nav_bar.dart'; // ADD THIS

  class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key});

    @override
    State<HomeScreen> createState() => _HomeScreenState();
  }

  class _HomeScreenState extends State<HomeScreen> {
    int _selectedIndex = 0;

    final List<Widget> _pages = [
      const HomePage(),
      const TasksPage(),
      const JournalPage(),
      const WishlistPage(),
    ];

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: _pages[_selectedIndex],
        extendBody: true, // ADD THIS - makes body extend behind nav
        bottomNavigationBar: FloatingNavBar(
          // REPLACE THE OLD NavigationBar
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

  // Keep all your other code (HomePage, TasksPage, etc.) the same...

  // Home Page
  class HomePage extends StatelessWidget {
    const HomePage({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Good Morning'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Overview',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.check_circle,
                            count: '5',
                            label: 'Tasks Done',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          _StatItem(
                            icon: Icons.book,
                            count: '2',
                            label: 'Entries',
                            color: Colors.blue,
                          ),
                          _StatItem(
                            icon: Icons.star,
                            count: '12',
                            label: 'Wishes',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add_task,
                      title: 'New Task',
                      color: Theme.of(context).primaryColor,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.edit_note,
                      title: 'Write Journal',
                      color: Theme.of(context).colorScheme.secondary,
                      onTap: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Tasks',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _TaskCard(
                title: 'Finish project presentation',
                time: '2:00 PM',
                priority: 'high',
                isDone: false,
              ),
              _TaskCard(
                title: 'Buy groceries',
                time: '4:30 PM',
                priority: 'medium',
                isDone: true,
              ),
              _TaskCard(
                title: 'Call dentist',
                time: 'Tomorrow',
                priority: 'low',
                isDone: false,
              ),

              const SizedBox(height: 24),

              // Journal Highlight
              Text(
                'Latest Journal Entry',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Today was productive',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Icon(Icons.sentiment_satisfied,
                              color: Colors.green),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'I managed to complete most of my tasks today. Feeling accomplished and ready for tomorrow...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Today, 6:45 PM',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.5),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Placeholder pages
  class TasksPage extends StatelessWidget {
    const TasksPage({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tasks')),
        body: const Center(child: Text('Tasks Screen - Coming Soon')),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
      );
    }
  }

  class JournalPage extends StatelessWidget {
    const JournalPage({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Journal')),
        body: const Center(child: Text('Journal Screen - Coming Soon')),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.edit),
        ),
      );
    }
  }

  class WishlistPage extends StatelessWidget {
    const WishlistPage({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wishlist')),
        body: const Center(child: Text('Wishlist Screen - Coming Soon')),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
      );
    }
  }

  // Stat Item Widget
  class _StatItem extends StatelessWidget {
    final IconData icon;
    final String count;
    final String label;
    final Color color;

    const _StatItem({
      required this.icon,
      required this.count,
      required this.label,
      required this.color,
    });

    @override
    Widget build(BuildContext context) {
      return Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.6),
                ),
          ),
        ],
      );
    }
  }

  // Quick Action Card Widget
  class _QuickActionCard extends StatelessWidget {
    final IconData icon;
    final String title;
    final Color color;
    final VoidCallback onTap;

    const _QuickActionCard({
      required this.icon,
      required this.title,
      required this.color,
      required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
      return Card(
        color: color,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              children: [
                Icon(icon, size: 32, color: const Color(0xFF1E1E1E)),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF1E1E1E),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // Task Card Widget
  class _TaskCard extends StatelessWidget {
    final String title;
    final String time;
    final String priority;
    final bool isDone;

    const _TaskCard({
      required this.title,
      required this.time,
      required this.priority,
      required this.isDone,
    });

    Color _getPriorityColor() {
      switch (priority) {
        case 'high':
          return Colors.red;
        case 'medium':
          return Colors.orange;
        case 'low':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }

    @override
    Widget build(BuildContext context) {
      return Card(
        child: ListTile(
          leading: Icon(
            isDone ? Icons.check_circle : Icons.circle_outlined,
            color: isDone ? Colors.green : Colors.grey,
          ),
          title: Text(
            title,
            style: TextStyle(
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(time),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getPriorityColor(),
                  ),
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      );
    }
  }
