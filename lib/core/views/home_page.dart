import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/core/services/firebase/notification_manager.dart';
import 'package:zentry/features/projects/projects.dart';
import 'package:zentry/features/journal/journal.dart';
import 'package:zentry/features/wishlist/wishlist.dart';

class HomePage extends StatefulWidget {
  final Function(String? filter)? onNavigateToProjects;
  final Function(int index)? onNavigateToTab;

  const HomePage({super.key, this.onNavigateToProjects, this.onNavigateToTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final JournalService _journalService = JournalService();

  StreamSubscription<List<JournalEntry>>? _journalSubscription;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<Project>>? _projectsSubscription;
  StreamSubscription<void>? _ticketsSubscription;

  String _firstName = '';
  List<Project> _recentProjects = [];
  List<JournalEntry> _recentJournalEntries = [];
  bool _isLoading = true;
  String? _currentUserEmail;
  String? _currentUserId;

  // Quick insights metrics
  int _tasksDueToday = 0;
  int _activeProjects = 0;
  int _completedTasksThisWeek = 0;
  Map<DateTime, List<DateTicket>> _ticketsByDate = {};

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadData();
    _subscribeToJournalEntries();
    _subscribeToTickets();
  }

  void _subscribeToJournalEntries() {
    // If user is already signed in, subscribe immediately
    if (_authService.currentUser != null) {
      _journalSubscription =
          _journalService.getEntriesStream().listen((entries) {
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

        _journalSubscription =
            _journalService.getEntriesStream().listen((entries) {
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

  void _subscribeToTickets() {
    // If user is already signed in, subscribe immediately
    if (_authService.currentUser != null) {
      _subscribeToTicketsStream();
      return;
    }

    // Otherwise wait for auth state to become available, then subscribe
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null && _ticketsSubscription == null) {
        // Cancel auth listener once we have a user
        _authSubscription?.cancel();
        _authSubscription = null;

        _subscribeToTicketsStream();
      }
    }, onError: (err) {
      debugPrint('Auth state stream error: $err');
    });
  }

  Future<void> _subscribeToTicketsStream() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // Create a combined stream of all project tickets
      // by listening to projects and then subscribing to their tickets
      _projectsSubscription?.cancel();
      _projectsSubscription = _firestoreService
          .getUserProjectsStream(user.uid, user.email ?? '')
          .listen((projects) async {
        if (!mounted) return;

        // Merge all ticket streams from active projects
        final activeProjects = projects
            .where((p) => p.status != 'completed')
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        if (activeProjects.isEmpty) {
          if (mounted) {
            setState(() {
              _ticketsByDate = {};
              _recentProjects = [];
              _activeProjects = 0;
              _tasksDueToday = 0;
              _completedTasksThisWeek = 0;
              _isLoading = false;
            });
          }
          return;
        }

        // Take only the 4 most recent active projects
        final limitedProjects = activeProjects.take(4).toList();

        // Subscribe to real-time ticket updates for all active projects
        // Cancel previous subscription
        _ticketsSubscription?.cancel();

        // Combine all ticket streams into one
        final ticketStreams = activeProjects
            .map((project) => _firestoreService
                .listenToProjectTickets(project.id)
                .map((tickets) => {
                      'projectId': project.id,
                      'tickets': tickets,
                    }))
            .toList();

        if (ticketStreams.isEmpty) {
          if (mounted) {
            setState(() {
              _ticketsByDate = {};
              _recentProjects = limitedProjects;
              _activeProjects = activeProjects.length;
              _tasksDueToday = 0;
              _completedTasksThisWeek = 0;
              _isLoading = false;
            });
          }
          return;
        }

        // Listen to the first stream (we'll update the logic to combine all streams properly)
        // For now, we'll process tickets whenever any project's tickets change
        _ticketsSubscription =
            Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
          // Fetch all tickets from all active projects
          Map<DateTime, List<DateTicket>> ticketsByDate = {};
          int tasksDueToday = 0;
          int completedThisWeek = 0;

          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final weekStart = DateTime.now()
              .subtract(Duration(days: DateTime.now().weekday - 1));

          for (var project in activeProjects) {
            try {
              final tickets =
                  await _firestoreService.getProjectTickets(project.id);

              for (var ticket in tickets) {
                if (ticket.deadline != null) {
                  var deadline = ticket.deadline!;

                  // Set default time to 11:59 PM if no time is set (for existing tickets)
                  if (deadline.hour == 0 &&
                      deadline.minute == 0 &&
                      deadline.second == 0) {
                    deadline = DateTime(
                      deadline.year,
                      deadline.month,
                      deadline.day,
                      23,
                      59,
                    );
                  }

                  final deadlineDate =
                      DateTime(deadline.year, deadline.month, deadline.day);

                  // Determine ticket status
                  TicketStatus ticketStatus;
                  if (ticket.status == 'done') {
                    ticketStatus = TicketStatus.done;
                  } else if (deadlineDate.isBefore(todayDate)) {
                    ticketStatus = TicketStatus.late;
                  } else {
                    ticketStatus = TicketStatus.pending;
                  }

                  // Add ticket to the map
                  final dateTicket = DateTicket(
                    title: ticket.title,
                    status: ticketStatus,
                    deadline: deadline,
                    ticketId: ticket.ticketNumber,
                    projectName: project.title,
                    projectId: project.id,
                  );

                  if (ticketsByDate.containsKey(deadlineDate)) {
                    ticketsByDate[deadlineDate]!.add(dateTicket);
                  } else {
                    ticketsByDate[deadlineDate] = [dateTicket];
                  }

                  // Count tasks due today
                  if (deadline.year == today.year &&
                      deadline.month == today.month &&
                      deadline.day == today.day &&
                      ticket.status != 'done') {
                    tasksDueToday++;
                  }

                  // Count completed tasks this week
                  if (ticket.status == 'done' &&
                      ticket.updatedAt.isAfter(weekStart)) {
                    completedThisWeek++;
                  }
                }
              }
            } catch (e) {
              debugPrint(
                  'Error fetching tickets for project ${project.id}: $e');
            }
          }

          return {
            'ticketsByDate': ticketsByDate,
            'tasksDueToday': tasksDueToday,
            'completedThisWeek': completedThisWeek,
            'activeProjects': activeProjects.length,
            'recentProjects': limitedProjects,
          };
        }).listen((data) {
          if (!mounted) return;
          setState(() {
            _ticketsByDate =
                data['ticketsByDate'] as Map<DateTime, List<DateTicket>>;
            _tasksDueToday = data['tasksDueToday'] as int;
            _completedTasksThisWeek = data['completedThisWeek'] as int;
            _activeProjects = data['activeProjects'] as int;
            _recentProjects = data['recentProjects'] as List<Project>;
            _isLoading = false;
          });
        }, onError: (err) {
          debugPrint('Tickets periodic stream error: $err');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      }, onError: (err) {
        debugPrint('Projects stream error: $err');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Error subscribing to tickets: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    _projectsSubscription?.cancel();
    _ticketsSubscription?.cancel();
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

      // Store current user info for use in build methods
      _currentUserEmail = user.email ?? '';
      _currentUserId = user.uid;

      // Data loading is now handled by _subscribeToTickets() and _subscribeToJournalEntries()
      // which set up real-time listeners for automatic updates
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

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Colors.yellow.shade400;
      case 'sad':
        return Colors.blue.shade400;
      case 'angry':
        return Colors.red.shade400;
      case 'excited':
        return Colors.purple.shade400;
      case 'calm':
      default:
        return Colors.green.shade400;
    }
  }

  IconData _getWishIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tech':
        return Icons.devices;
      case 'fashion':
        return Icons.checkroom;
      case 'travel':
        return Icons.flight;
      case 'home':
        return Icons.home;
      default:
        return Icons.star;
    }
  }

  String _getPlainTextFromQuill(String content) {
    try {
      // Simple extraction - remove Quill formatting
      final regex = RegExp(r'"insert":"([^"]*)"');
      final matches = regex.allMatches(content);
      final textParts = matches.map((m) => m.group(1) ?? '').toList();
      return textParts.join(' ').trim();
    } catch (e) {
      return content;
    }
  }

  Widget _buildQuickInsightCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSharedProjectCard(Project project) {
    Color getProjectColor() {
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

    final progress = project.totalTickets > 0
        ? project.completedTickets / project.totalTickets
        : 0.0;
    final projectColor = getProjectColor();

    // Determine project type
    String projectType = 'Personal';
    if (project.category == 'workspace') {
      projectType = 'Workspace';
    } else if (_currentUserId != null &&
        _currentUserEmail != null &&
        _currentUserId!.isNotEmpty &&
        _currentUserEmail!.isNotEmpty &&
        project.userId != _currentUserId &&
        project.teamMembers.contains(_currentUserEmail!)) {
      projectType = 'Shared';
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
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: projectColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: projectColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    projectType,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: projectColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    project.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (project.isPinned)
                  Icon(Icons.push_pin, size: 12, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              project.description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.people_outline, size: 12, color: projectColor),
                const SizedBox(width: 4),
                Text(
                  '${project.teamMembers.length}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: getProjectColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    project.status,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: getProjectColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(getProjectColor()),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${project.completedTickets} of ${project.totalTickets} tasks',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade500,
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Gradient Header
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
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.paddingLarge,
                      12,
                      AppConstants.paddingLarge,
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compact Top Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            StreamBuilder<int>(
                              stream: NotificationManager()
                                  .getUnreadCountStream(_currentUserId ?? ''),
                              builder: (context, snapshot) {
                                final unreadCount = snapshot.data ?? 0;
                                return Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.notifications_outlined,
                                          size: 20),
                                      color: const Color(0xFF1E1E1E),
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        Navigator.pushNamed(
                                            context, AppRoutes.notifications);
                                      },
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            unreadCount > 9
                                                ? '9+'
                                                : unreadCount.toString(),
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
                              icon: const Icon(Icons.person_outline, size: 20),
                              color: const Color(0xFF1E1E1E),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.profile);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Compact Greeting
                        Text(
                          '$greeting, $_firstName!',
                          style: const TextStyle(
                            color: Color(0xFF1E1E1E),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Let\'s make a productive day today',
                          style: TextStyle(
                            color: const Color(0xFF1E1E1E).withOpacity(0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick Insights Row (Single Row)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium),
                child: _isLoading
                    ? const Row(
                        children: [
                          Expanded(child: SkeletonQuickInsights()),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildQuickInsightCard(
                              'Tasks Due',
                              '$_tasksDueToday',
                              Icons.today_outlined,
                              Colors.orange.shade400,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildQuickInsightCard(
                              'Active Projects',
                              '$_activeProjects',
                              Icons.folder_outlined,
                              Colors.blue.shade400,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildQuickInsightCard(
                              'Done This Week',
                              '$_completedTasksThisWeek',
                              Icons.check_circle_outline,
                              Colors.green.shade400,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // Compact Calendar Widget
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tickets Calendar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 400,
                      child: _isLoading
                          ? const SkeletonCalendar()
                          : CompactCalendarWidget(
                              ticketsByDate: _ticketsByDate,
                              onDateSelected: (date) {
                                // Optional: Navigate to tasks for selected date
                                debugPrint('Selected date: $date');
                              },
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Recent Projects Section - Horizontal Scroll
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Projects',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    if (!_isLoading)
                      TextButton(
                        onPressed: () {
                          widget.onNavigateToProjects?.call(null);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('See All',
                            style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              if (_isLoading)
                SizedBox(
                  height: 155,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMedium),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SkeletonProjectCard(),
                      );
                    },
                  ),
                )
              else if (_recentProjects.isNotEmpty)
                SizedBox(
                  height: 155,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMedium),
                    itemCount: _recentProjects.length + 1,
                    itemBuilder: (context, index) {
                      if (index < _recentProjects.length) {
                        return _buildCompactSharedProjectCard(
                            _recentProjects[index]);
                      } else {
                        // View All card
                        return GestureDetector(
                          onTap: () {
                            widget.onNavigateToProjects?.call(null);
                          },
                          child: Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_forward,
                                    color: Colors.grey.shade700, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'View All Projects',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder_outlined,
                          color: Colors.grey.shade400, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'No projects yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Recent Journal Entry
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Journal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    if (!_isLoading)
                      TextButton(
                        onPressed: () {
                          widget.onNavigateToTab
                              ?.call(2); // Journal is tab index 2
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('View All',
                            style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium),
                  child: SkeletonJournalCard(),
                )
              else if (_recentJournalEntries.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium),
                  child: Builder(
                    builder: (context) {
                      final moodColor =
                          _getMoodColor(_recentJournalEntries.first.mood);
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: moodColor.withOpacity(0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getMoodEmoji(_recentJournalEntries.first.mood),
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 12, color: moodColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        _recentJournalEntries.first.date,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _recentJournalEntries.first.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getPlainTextFromQuill(
                                        _recentJournalEntries.first.content),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.book_outlined,
                            color: Colors.green.shade400, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'No journal entries yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // My Wishlist (Personal)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Wishlist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onNavigateToTab
                            ?.call(3); // Wishlist is tab index 3
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('View All',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 145,
                child: Consumer<WishlistProvider>(
                  builder: (context, wishlistProvider, child) {
                    // Filter out completed wishlist items and take only first 3
                    final activeWishes = wishlistProvider.isInitialized
                        ? wishlistProvider.controller.wishes
                            .where((w) => !w.completed)
                            .take(3)
                            .toList()
                        : <Wish>[];

                    return ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMedium),
                      children: activeWishes.isNotEmpty
                          ? [
                              ...activeWishes.map((wish) {
                                final categoryColor = wishlistProvider
                                    .controller
                                    .getCategoryColor(wish.category);
                                return Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: WishCard(
                                    title: wish.title,
                                    price: '₱${wish.price}',
                                    image: _getWishIcon(wish.category),
                                    backgroundColor: categoryColor,
                                  ),
                                );
                              }),
                              // View All card
                              GestureDetector(
                                onTap: () {
                                  widget.onNavigateToTab
                                      ?.call(3); // Wishlist is tab index 3
                                },
                                child: Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1.5),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.arrow_forward,
                                          color: Colors.grey.shade700,
                                          size: 24),
                                      const SizedBox(height: 8),
                                      Text(
                                        'View All',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ]
                          : [
                              Container(
                                width: 140,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.purple.withOpacity(0.2),
                                      width: 1),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.star_border,
                                        color: Colors.purple.shade400,
                                        size: 20),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No wishlist',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.purple.shade600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 100), // Space for floating nav
            ],
          ),
        ),
      ),
      // Uncomment to enable test notifications (development only)
       floatingActionButton: const TestNotificationButton(),
    );
  }
}
