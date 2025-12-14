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
  StreamSubscription<List<Wish>>? _wishesSubscription;

  String _firstName = '';
  List<Project> _recentProjects = [];
  List<JournalEntry> _recentJournalEntries = [];
  List<Wish> _recentWishes = [];
  bool _isLoading = true;
  String? _currentUserEmail;
  String? _currentUserId;

  // Quick insights metrics
  int _tasksDueToday = 0;
  int _activeProjects = 0;
  int _completedTasksThisWeek = 0;
  Map<DateTime, List<DateTicket>> _ticketsByDate = {};

  // Cache for project tickets to avoid constant recalculation
  final Map<String, List<Ticket>> _projectTicketsCache = {};
  // Track individual subscriptions to cancel them properly
  final List<StreamSubscription> _ticketSubscriptions = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadData();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        _subscribeToTicketsStream();
        _journalSubscription?.cancel();
        _journalSubscription =
            _journalService.getEntriesStream().listen((entries) {
          if (!mounted) return;
          setState(() {
            _recentJournalEntries = entries.take(1).toList();
          });
        }, onError: (err) {
          debugPrint('Journal stream error: $err');
        });
        
        // Subscribe to wishlist stream for real-time updates
        _wishesSubscription?.cancel();
        final wishlistService = WishlistService();
        _wishesSubscription =
            wishlistService.getWishesStream().listen((wishes) {
          if (!mounted) return;
          debugPrint('\ud83c\udf81 Home page received ${wishes.length} wishes from stream');
          for (final wish in wishes) {
            debugPrint('  - ${wish.title} (completed=${wish.completed}, sharedWith=${wish.sharedWith})');
          }
          // Sort by creation date descending and take first 5 (uncompleted)
          final sorted = wishes
              .where((w) => !w.completed)
              .toList()
            ..sort((a, b) => _parseDateAdded(b.dateAdded)
                .compareTo(_parseDateAdded(a.dateAdded)));
          debugPrint('\ud83d\udcc4 After filtering uncompleted: ${sorted.length} wishes');
          setState(() {
            _recentWishes = sorted.take(5).toList();
          });
        }, onError: (err) {
          debugPrint('Wishlist stream error: $err');
        });
      } else {
        // user logged out
        _journalSubscription?.cancel();
        _journalSubscription = null;
        _projectsSubscription?.cancel();
        _projectsSubscription = null;
        _ticketsSubscription?.cancel();
        _ticketsSubscription = null;
        _wishesSubscription?.cancel();
        _wishesSubscription = null;
        _debounceTimer?.cancel();
        _debounceTimer = null;

        if (mounted) {
          setState(() {
            _recentJournalEntries = [];
            _ticketsByDate = {};
            _recentProjects = [];
            _recentWishes = [];
            _activeProjects = 0;
            _tasksDueToday = 0;
            _completedTasksThisWeek = 0;
          });
        }
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

        // Take only the 4 most recent active projects
        final limitedProjects = activeProjects.take(4).toList();

        // Subscribe to real-time ticket updates for all active projects
        // Cancel previous subscriptions
        for (var sub in _ticketSubscriptions) {
          sub.cancel();
        }
        _ticketSubscriptions.clear();
        _projectTicketsCache.clear();

        // If no active projects, just update state
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

        // Subscribe to each project's ticket stream
        for (var project in activeProjects) {
          final sub = _firestoreService
              .listenToProjectTickets(project.id)
              .listen((tickets) {
            if (!mounted) return;

            // Update cache for this project
            _projectTicketsCache[project.id] = tickets;

            // Debounce the update: wait for 300ms of silence before processing
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 300), () {
              if (mounted) {
                _processTicketUpdates(activeProjects, limitedProjects);
              }
            });
          });

          _ticketSubscriptions.add(sub);
        }
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

  void _processTicketUpdates(
      List<Project> activeProjects, List<Project> limitedProjects) {
    // Recalculate aggregates from cache
    Map<DateTime, List<DateTicket>> ticketsByDate = {};
    int tasksDueToday = 0;
    int completedThisWeek = 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final weekStart =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

    // Iterate over all cached tickets from all projects
    _projectTicketsCache.forEach((projectId, projectTickets) {
      // Find project name for these tickets
      final projectTitle = activeProjects
          .firstWhere((p) => p.id == projectId,
              orElse: () => activeProjects.isNotEmpty
                  ? activeProjects.first
                  : Project(
                      id: 'unknown',
                      userId: '',
                      title: 'Unknown',
                      description: '',
                      teamMembers: [],
                      status: 'active',
                      totalTickets: 0,
                      completedTickets: 0,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    )) // Fallback safe
          .title;

      for (var ticket in projectTickets) {
        if (ticket.deadline != null) {
          var deadline = ticket.deadline!;

          // Set default time to 11:59 PM if no time is set
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

          // Determine ticket status based on USER'S completion status
          TicketStatus ticketStatus;
          final currentUserEmail = _currentUserEmail?.toLowerCase();
          final isAssignedToCurrentUser = currentUserEmail != null && 
              ticket.assignedTo.any((email) => email.toLowerCase() == currentUserEmail);
          
          // Check if current user is the project owner/creator
          final isProjectOwner = activeProjects.any((p) => p.id == projectId && p.userId == _currentUserId);

          // Process if: assigned to user OR user is project owner (for in_review/done status visibility)
          if (!isAssignedToCurrentUser && !isProjectOwner) continue;

          // Status logic for current user:
          // 1. If ticket is 'done' -> Done (PM moved it to Done)
          // 2. If ticket is 'in_review' -> In Review (PM moved to In Review, waiting for review)
          // 3. If deadline passed and status is 'todo' or 'in_progress' -> Late
          // 4. If status is 'todo' or 'in_progress' -> Pending
          
          if (ticket.status == 'done') {
            // Only mark as Done when PM moves ticket to Done status
            ticketStatus = TicketStatus.done;
          } else if (ticket.status == 'in_review') {
            // In Review means assignee's work is done, waiting for PM review
            ticketStatus = TicketStatus.inReview;
          } else if (deadlineDate.isBefore(todayDate) && 
                     (ticket.status == 'todo' || ticket.status == 'in_progress')) {
            // Late only if deadline passed and still in todo/in-progress
            ticketStatus = TicketStatus.late;
          } else {
            // Future deadline or today, not done yet (status is todo or in_progress)
            ticketStatus = TicketStatus.pending;
          }

          // Add ticket to the map
          final dateTicket = DateTicket(
            title: ticket.title,
            status: ticketStatus,
            deadline: deadline,
            ticketId: ticket.ticketNumber,
            projectName: projectTitle,
            projectId: projectId,
          );

          if (ticketsByDate.containsKey(deadlineDate)) {
            ticketsByDate[deadlineDate]!.add(dateTicket);
          } else {
            ticketsByDate[deadlineDate] = [dateTicket];
          }

          // Count pending tasks - only for assigned tasks, not all project tickets
          if (isAssignedToCurrentUser && ticketStatus == TicketStatus.pending) {
            tasksDueToday++;
          }

          // Count completed tasks this week - only when ticket status is 'done'
          if (isAssignedToCurrentUser && ticket.status == 'done' && ticket.updatedAt.isAfter(weekStart)) {
            completedThisWeek++;
          }
        }
      }
    });

    // Only call setState if actual data has changed
    final stateChanged = 
        _ticketsByDate.length != ticketsByDate.length ||
        _tasksDueToday != tasksDueToday ||
        _completedTasksThisWeek != completedThisWeek ||
        _activeProjects != activeProjects.length ||
        _recentProjects.length != limitedProjects.length ||
        _isLoading == true;
    
    if (stateChanged && mounted) {
      setState(() {
        _ticketsByDate = ticketsByDate;
        _tasksDueToday = tasksDueToday;
        _completedTasksThisWeek = completedThisWeek;
        _activeProjects = activeProjects.length;
        _recentProjects = limitedProjects;
        _isLoading = false;
      });
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
    _authSubscription?.cancel();
    _journalSubscription?.cancel();
    _projectsSubscription?.cancel();
    _debounceTimer?.cancel();
    // Cancel all individual ticket subscriptions
    for (var sub in _ticketSubscriptions) {
      sub.cancel();
    }
    _ticketSubscriptions.clear();
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

      // Initialize providers to ensure they have the correct data and listeners
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Provider.of<WishlistProvider>(context, listen: false).initialize();
            Provider.of<NotificationProvider>(context, listen: false)
                .initialize();
          }
        });
      }

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
      case 'grateful':
        return Colors.brown.shade400;
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tech':
        return const Color(0xFF42A5F5); // Blue
      case 'travel':
        return const Color(0xFF66BB6A); // Green
      case 'fashion':
        return const Color(0xFFAB47BC); // Purple
      case 'home':
        return const Color(0xFFFFA726); // Orange
      default:
        return const Color(0xFF78909C); // Gray
    }
  }

  DateTime _parseDateAdded(String dateAdded) {
    try {
      // Parse format: "MMM dd, yyyy" (e.g., "Nov 13, 2025")
      return DateTime.parse(dateAdded);
    } catch (e) {
      // If parsing fails, try more lenient approach
      try {
        // Extract year, month, day from string like "Nov 13, 2025"
        final parts = dateAdded.split(' ');
        if (parts.length >= 3) {
          final monthStr = parts[0];
          final dayStr = parts[1].replaceAll(',', '');
          final yearStr = parts[2];
          
          const months = {
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
            'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
          };
          
          final month = months[monthStr] ?? 1;
          final day = int.tryParse(dayStr) ?? 1;
          final year = int.tryParse(yearStr) ?? 2000;
          
          return DateTime(year, month, day);
        }
      } catch (e) {
        // Silent catch
      }
      // If all parsing fails, return a default date (year 2000)
      return DateTime(2000);
    }
  }

  String _getPlainTextFromQuill(String content) {
    try {
      // Extract plain text from Quill JSON format
      if (content.isEmpty) return '';
      
      // Match both plain and formatted text: {"insert":"text"} or {"insert":"text","attributes":{...}}
      // This regex extracts text between "insert":" and the closing quote before any comma or }
      final insertRegex = RegExp(r'"insert":"([^"\\]*(?:\\.[^"\\]*)*)');
      final matches = insertRegex.allMatches(content);
      
      if (matches.isEmpty) {
        // If no matches, return content with some basic cleanup
        return content.replaceAll(RegExp(r'[\\n\\t]'), ' ').trim();
      }
      
      final textParts = <String>[];
      for (final match in matches) {
        final text = match.group(1) ?? '';
        // Stop at first newline
        if (text.contains('\\n') || text == '\n') {
          break;
        }
        if (text.isNotEmpty && text != '\\n') {
          textParts.add(text);
        }
      }
      
      // Join all text parts from the first line
      final firstLine = textParts.join('');
      
      // Clean up escaped characters
      return firstLine
          .replaceAll('\\n', ' ')
          .replaceAll('\\t', ' ')
          .replaceAll('  ', ' ')
          .trim();
    } catch (e) {
      return 'Journal entry';
    }
  }

  void _showJournalDetail(JournalEntry entry) {
    final moodColor = _getMoodColor(entry.mood);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: moodColor.withOpacity(0.2),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: moodColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.mood.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: moodColor.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        entry.date,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        entry.time,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Images Section
            if (entry.imageUrls.isNotEmpty)
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: entry.imageUrls.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // Show full-screen image viewer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _FullScreenImageViewer(
                              imageUrls: entry.imageUrls,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            entry.imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                '${index + 1}/${entry.imageUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  backgroundColor: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: RichTextViewer(content: entry.content),
              ),
            ),
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditJournalScreen(entry: entry),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9ED69),
                        foregroundColor: const Color(0xFF1E1E1E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                              icon: const Icon(Icons.settings, size: 20),
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

              // Quick Insights Row (3 Responsive Cards)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium),
                child: _isLoading
                    ? const Row(
                        children: [
                          Expanded(child: SkeletonQuickInsights()),
                        ],
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            children: [
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 0.95,
                                  child: _buildQuickInsightCard(
                                    'Active Projects',
                                    '$_activeProjects',
                                    Icons.folder_outlined,
                                    Colors.blue.shade400,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 0.95,
                                  child: _buildQuickInsightCard(
                                    'Pending Tasks',
                                    '$_tasksDueToday',
                                    Icons.today_outlined,
                                    Colors.orange.shade400,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 0.95,
                                  child: _buildQuickInsightCard(
                                    'Completed Tasks',
                                    '$_completedTasksThisWeek',
                                    Icons.check_circle_outline,
                                    Colors.green.shade400,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
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
                      return GestureDetector(
                        onTap: () {
                          _showJournalDetail(_recentJournalEntries.first);
                        },
                        child: Container(
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

              // Recent Wishlist
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Wishlist',
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

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium),
                  child: SizedBox(
                    height: 145,
                    child: SkeletonJournalCard(),
                  ),
                )
              else if (_recentWishes.isNotEmpty)
                SizedBox(
                  height: 145,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMedium),
                    children: [
                      ..._recentWishes.map((wish) {
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              // Navigate to wishlist page and show modal for this wish
                              Navigator.pushNamed(
                                context,
                                '/wishlist',
                                arguments: {
                                  'showModalForWishId': wish.id,
                                },
                              );
                            },
                            child: WishCard(
                              title: wish.title,
                              price: '₱${wish.price}',
                              image: _getWishIcon(wish.category),
                              backgroundColor: _getCategoryColor(wish.category),
                            ),
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
                            mainAxisAlignment:
                                MainAxisAlignment.center,
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
                    ],
                  ),
                )
              else if (!_isLoading)
                SizedBox(
                  height: 145,
                  child: Center(
                    child: Text(
                      'No wishes yet. Create one to get started!',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
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

/// Full-screen image viewer with carousel
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1}/${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Image.network(
              widget.imageUrls[index],
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade900,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
