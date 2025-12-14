import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/projects/projects.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;
  final String? highlightTicketId;

  const ProjectDetailPage({
    super.key,
    required this.project,
    this.highlightTicketId,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final ProjectManager _projectManager = ProjectManager();
  final UserService _userService = UserService();
  final ProjectNotificationService _notificationService = ProjectNotificationService();
  Map<String, Map<String, String>> _userDetails = {};
  String? _highlightedTicketId;
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF9ED69),
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _loadUserDetails();

    // Set up highlight if ticket ID was provided
    if (widget.highlightTicketId != null) {
      _highlightedTicketId = widget.highlightTicketId;
    }
  }

  Future<void> _loadUserDetails() async {
    final details = <String, Map<String, String>>{};
    
    // Load team members by email
    if (widget.project.teamMembers.isNotEmpty) {
      final teamDetails = await _userService
          .getUsersDetailsByEmails(widget.project.teamMembers);
      details.addAll(teamDetails);
    }

    // Load project creator/manager by UID
    // project.userId is a UID, we need to fetch and store by email
    if (widget.project.userId.isNotEmpty) {
      try {
        final creatorDetails =
            await _userService.getUserDetailsByUid(widget.project.userId);
        if (creatorDetails != null && creatorDetails['email'] != null) {
          // Store creator details keyed by their email
          details[creatorDetails['email']!] = creatorDetails;
          print('✅ ProjectDetail loaded creator: ${creatorDetails['email']} (UID: ${widget.project.userId})');
        }
      } catch (e) {
        debugPrint('Error loading creator details: $e');
      }
    }

    if (mounted) {
      setState(() {
        _userDetails = details;
        _isLoadingUsers = false;
      });
    }
  }

  Color _getProjectColor() {
    switch (widget.project.color) {
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

  Future<List<Ticket>> _getTicketsByStatus(String status) async {
    return await _projectManager.getTicketsByStatus(widget.project.id, status);
  }

  void _refreshTickets() {
    setState(() {});
  }

  // Check if current user is the project manager (creator)
  bool _isCurrentUserProjectManager() {
    final currentUserId = _projectManager.getCurrentUserId();
    return currentUserId == widget.project.userId;
  }

  // Helper method to get member's assigned role from project.roles
  String _getMemberRole(String email) {
    // First check if this is the project creator (Project Manager)
    if (widget.project.userId.isNotEmpty) {
      for (final entry in _userDetails.entries) {
        if (entry.value['uid'] == widget.project.userId && entry.key == email) {
          return 'Project Manager';
        }
      }
    }
    
    // Check roles in project.roles for this member
    for (final role in widget.project.roles) {
      if (role.members.contains(email)) {
        return role.name;
      }
    }
    
    // Check teamMemberDetails for assigned role
    final teamMember = widget.project.teamMemberDetails
        .where((m) => m.email == email)
        .firstOrNull;
    if (teamMember?.role != null && teamMember!.role!.isNotEmpty) {
      return teamMember.role!;
    }
    
    // Default to Member if no role assigned
    return 'Member';
  }

  double _calculateAvatarStackWidthWithButton() {
    final count = widget.project.teamMembers.length;
    // Include space for all avatars plus the view all button
    return count > 0 ? count * 20.0 + 30.0 : 30.0;
  }

  List<Widget> _buildDetailAvatarStack() {
    final avatarWidgets = <Widget>[];

    // Build list of emails to display (in correct order)
    List<String> displayEmails = [];
    
    // Find project manager's email by looking through loaded details
    // project.userId is a UID, we need to find the corresponding email
    String? managerEmail;
    for (final entry in _userDetails.entries) {
      if (entry.value['uid'] == widget.project.userId) {
        managerEmail = entry.key;
        break;
      }
    }
    
    // Add manager first if found
    if (managerEmail != null && managerEmail.isNotEmpty) {
      displayEmails.add(managerEmail);
      print('✅ Found manager email: $managerEmail for UID: ${widget.project.userId}');
    } else {
      print('⚠️ Could not find manager email for UID: ${widget.project.userId}');
    }
    
    // Then add team members (excluding manager to avoid duplicate)
    for (final email in widget.project.teamMembers) {
      if (email != managerEmail) {
        displayEmails.add(email);
      }
    }

    for (int i = 0; i < displayEmails.length; i++) {
      final email = displayEmails[i];
      final details = _userDetails[email] ?? {};
      final displayName = _userService.getDisplayName(details, email);
      final profileUrl = details['profilePictureUrl'] ?? '';

      avatarWidgets.add(
        Positioned(
          left: i * 20.0,
          child: Tooltip(
            message: displayName,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 13,
                backgroundImage:
                    profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                onBackgroundImageError: profileUrl.isNotEmpty
                    ? (exception, stackTrace) {
                        print('Error loading profile image for $email: $exception');
                      }
                    : null,
                backgroundColor: Colors.grey.shade300,
                child: profileUrl.isEmpty
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      );
    }

    return avatarWidgets;
  }

  void _showMembersModal() async {
    // Get project creator details
    Map<String, String>? creatorDetails;
    String? creatorEmail;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCreator = currentUser?.uid == widget.project.userId;

    if (isCreator && currentUser?.email != null) {
      // If current user is the creator, use their details
      creatorDetails =
          await _userService.getUserDetailsByEmail(currentUser!.email!);
      creatorEmail = currentUser.email;
    } else {
      // Find creator's email by checking which team member's UID matches project.userId
      // First, try to find from already loaded user details
      for (final email in widget.project.teamMembers) {
        final userDetails = _userDetails[email];
        if (userDetails != null &&
            userDetails['uid'] == widget.project.userId) {
          creatorDetails = userDetails;
          creatorEmail = email;
          break;
        }
      }

      // If not found in team members, fetch creator details by UID
      if (creatorDetails == null) {
        try {
          creatorDetails =
              await _userService.getUserDetailsByUid(widget.project.userId);
          if (creatorDetails != null) {
            creatorEmail = creatorDetails['email'];
          }
        } catch (e) {
          debugPrint('Error fetching creator details: $e');
        }
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Members',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Members Section Header
                  Text(
                    'Members',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Project Manager (Creator) - show for all projects
                  if (creatorDetails != null && creatorEmail != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMemberTileWithRole(
                        creatorDetails['fullName'] ??
                            creatorDetails['email'] ??
                            'Unknown',
                        creatorEmail,
                        creatorDetails['profilePictureUrl'] ?? '',
                        'Project Manager',
                      ),
                    ),

                  // All other team members (excluding the creator)
                  ...widget.project.teamMemberDetails
                      .where((member) =>
                          member.email != creatorEmail && !member.isRejected)
                      .map((member) {
                    final email = member.email;
                    final details = _userDetails[email] ?? {};
                    final displayName =
                        _userService.getDisplayName(details, email);
                    final profileUrl = details['profilePictureUrl'] ?? '';
                    final role = _getMemberRole(email);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMemberTileWithRole(
                          displayName, email, profileUrl, role),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTileWithRole(
      String displayName, String email, String profileUrl, String role) {
    // Check if member is pending
    final isPending = widget.project.isMemberPending(email);

    // Get role colors
    Color getRoleColor(String role) {
      switch (role.toLowerCase()) {
        case 'project manager':
          return Colors.blue;
        case 'backend':
        case 'back end':
          return Colors.purple;
        case 'frontend':
        case 'front end':
          return Colors.green;
        case 'designer':
        case 'ui/ux':
          return Colors.pink;
        case 'developer':
          return Colors.orange;
        case 'tester':
        case 'qa':
          return Colors.red;
        case 'member':
          return Colors.green;
        default:
          return Colors.green;
      }
    }

    final roleColor = getRoleColor(role);

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage:
              profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
          onBackgroundImageError: profileUrl.isNotEmpty
              ? (exception, stackTrace) {
                  print('Error loading profile image for member: $exception');
                }
              : null,
          backgroundColor:
              isPending ? Colors.orange.shade100 : Colors.grey.shade300,
          child: profileUrl.isEmpty
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isPending ? Colors.orange : null,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: roleColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: roleColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                  if (isPending) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                email,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: _getProjectColor(),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.project.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E1E1E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.project.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      const Color(0xFF1E1E1E).withOpacity(0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Add Ticket Button - Only show for project manager
                        if (_isCurrentUserProjectManager())
                          GestureDetector(
                            onTap: () => _navigateToAddTicketPage(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Color(0xFFF9ED69),
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Team members - Avatar Group
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Project Members',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF1E1E1E).withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            height: 30,
                            width: _calculateAvatarStackWidthWithButton(),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ..._buildDetailAvatarStack(),
                                if (widget.project.teamMembers.isNotEmpty)
                                  Positioned(
                                    left: widget.project.teamMembers.length *
                                        20.0,
                                    child: GestureDetector(
                                      onTap: () => _showMembersModal(),
                                      child: Tooltip(
                                        message: 'View all members',
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(
                                            Icons.people,
                                            size: 16,
                                            color: Color(0xFF1E1E1E),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Kanban Board
          Expanded(
            child: StreamBuilder<List<Ticket>>(
              stream: _projectManager.listenToProjectTickets(widget.project.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final allTickets = snapshot.data ?? [];
                
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKanbanColumn(
                        'To Do',
                        allTickets.where((t) => t.status == 'todo').toList(),
                        Colors.grey.shade400,
                        'todo',
                      ),
                      const SizedBox(width: 16),
                      _buildKanbanColumn(
                        'In Progress',
                        allTickets.where((t) => t.status == 'in_progress').toList(),
                        Colors.orange.shade400,
                        'in_progress',
                      ),
                      const SizedBox(width: 16),
                      _buildKanbanColumn(
                        'In Review',
                        allTickets.where((t) => t.status == 'in_review').toList(),
                        Colors.purple.shade400,
                        'in_review',
                      ),
                      const SizedBox(width: 16),
                      _buildKanbanColumn(
                        'Done',
                        allTickets.where((t) => t.status == 'done').toList(),
                        Colors.green.shade400,
                        'done',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(
    String title,
    List<Ticket> tickets,
    Color color,
    String status,
  ) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tickets.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tickets List
          Flexible(
            child: tickets.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No tickets',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      final isHighlighted =
                          _highlightedTicketId == ticket.ticketNumber;
                      return TicketCard(
                        ticket: ticket,
                        project: widget.project,
                        isHighlighted: isHighlighted,
                        onTap: () {
                          _showTicketDetailsSheet(ticket);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showTicketDetailsSheet(Ticket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ticket Number
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ticket.ticketNumber,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              ticket.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Image Carousel (if images exist)
            if (ticket.imageUrls.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: ticket.imageUrls.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // Show full-screen image viewer
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.black,
                            child: Stack(
                              children: [
                                Center(
                                  child: InteractiveViewer(
                                    child: Image.network(
                                      ticket.imageUrls[index],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            ticket.imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            Text(
              _getPlainTextFromDescription(ticket.description),
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Details
            _buildDetailRow(
                Icons.flag_outlined, 'Priority', ticket.priority.toUpperCase()),
            const SizedBox(height: 12),

            _buildDetailRow(Icons.assignment_outlined, 'Status',
                _formatStatus(ticket.status)),
            const SizedBox(height: 12),

            // Status Section
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Text(
                  'Assignees',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: InkWell(
                onTap: () => _showAssigneesModal(
                    ticket.assignedTo, ticket.status, ticket),
                child: _buildAssigneeAvatarStack(
                  ticket.assignedTo,
                  onViewMore: () => _showAssigneesModal(
                      ticket.assignedTo, ticket.status, ticket),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(ticket),

            const SizedBox(height: 12),

            // Delete Button
            // Delete Button - Only for Project Creator
            if (FirebaseAuth.instance.currentUser?.uid ==
                widget.project.userId) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(ticket);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Ticket'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _navigateToAddTicketPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTicketPage(
          project: widget.project,
          refreshTickets: _refreshTickets,
        ),
      ),
    );
  }

  void _navigateToEditTicketPage(Ticket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTicketPage(
          ticket: ticket,
          project: widget.project,
          refreshTickets: _refreshTickets,
        ),
      ),
    );
  }

  Color _getColorForEmail(String email) {
    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.red.shade300,
      Colors.purple.shade300,
      Colors.orange.shade300,
      Colors.pink.shade300,
      Colors.cyan.shade300,
      Colors.amber.shade300,
    ];
    final hash = email.hashCode.abs();
    return colors[hash % colors.length];
  }

  /// Extract plain text from delta JSON content
  String _getPlainTextFromDescription(String description) {
    try {
      // Try to parse as delta JSON
      final decoded = json.decode(description);
      if (decoded is List) {
        // Extract text from delta operations
        final buffer = StringBuffer();
        for (var op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            buffer.write(op['insert']);
          }
        }
        return buffer.toString().trim();
      }
    } catch (e) {
      // If parsing fails, return as-is (backward compatibility)
    }
    return description;
  }

  Widget _buildAssigneeAvatarStack(List<String> assignees,
      {VoidCallback? onViewMore}) {
    // Do not filter out current user - they should see themselves assigned
    final teamAssignees = assignees;

    if (teamAssignees.isEmpty) {
      return Row(
        children: [
          Icon(Icons.person_outline, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          const Text('Unassigned'),
        ],
      );
    }

    // Show max 4 avatars stacked plus a "View" button
    final visibleCount = teamAssignees.length > 4 ? 4 : teamAssignees.length;
    final hasMore = teamAssignees.length > 4;
    final stackWidth =
        hasMore ? (visibleCount * 16.0) + 28 : (visibleCount * 16.0) + 16;

    return Row(
      children: [
        SizedBox(
          width: stackWidth,
          height: 32,
          child: Stack(
            children: [
              ...List.generate(visibleCount, (index) {
                final email = teamAssignees[index];
                final details = _userDetails[email] ?? {};
                final displayName = _userService.getDisplayName(details, email);
                final profileUrl = details['profilePictureUrl'] ?? '';
                final firstLetter = displayName.isNotEmpty
                    ? displayName[0].toUpperCase()
                    : email[0].toUpperCase();

                return Positioned(
                  left: index * 16.0,
                  child: Tooltip(
                    message: displayName,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundImage: profileUrl.isNotEmpty
                            ? NetworkImage(profileUrl)
                            : null,
                        onBackgroundImageError: profileUrl.isNotEmpty
                            ? (exception, stackTrace) {
                                print('Error loading avatar for $email: $exception');
                              }
                            : null,
                        backgroundColor: _getColorForEmail(email),
                        child: profileUrl.isEmpty
                            ? Text(
                                firstLetter,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              }),
              if (hasMore)
                Positioned(
                  left: visibleCount * 16.0,
                  child: Tooltip(
                    message: '${teamAssignees.length - 4} more',
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.grey.shade300,
                      ),
                      child: Center(
                        child: Text(
                          '+${teamAssignees.length - 4}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (onViewMore != null)
          InkWell(
            onTap: onViewMore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAssigneesModal(
      List<String> assignees, String ticketStatus, Ticket ticket) {
    // Do not filter out current user
    final teamAssignees = assignees;

    final currentUser = FirebaseAuth.instance.currentUser;
    final isAssigned =
        currentUser != null && ticket.assignedTo.contains(currentUser.email);
    final isAlreadyDone =
        currentUser != null && ticket.membersDone.contains(currentUser.email);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assignees Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ticket.progressDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ticket.allAssigneesDone
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mark as Done button for assigned users in todo status
            if (ticket.status == 'todo' && isAssigned && !isAlreadyDone) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Add current user to membersDone
                    List<String> updatedMembersDone =
                        List.from(ticket.membersDone);
                    if (currentUser.email != null &&
                        !updatedMembersDone.contains(currentUser.email)) {
                      updatedMembersDone.add(currentUser.email!);
                    }

                    final updatedTicket =
                        ticket.copyWith(membersDone: updatedMembersDone);
                    await _projectManager.updateTicket(
                        ticket.projectId, ticket.ticketNumber, updatedTicket);

                    // Send notification to PM
                    await _notificationService.notifyPMTicketReady(
                      ticket: updatedTicket,
                      project: widget.project,
                      action: 'marked_done',
                    );

                    // Check if this is the last assignee
                    final remainingAssignees = updatedTicket.assignedTo
                        .where((email) => !updatedTicket.membersDone.contains(email))
                        .toList();

                    if (remainingAssignees.length == 1) {
                      await _notificationService.notifyLastAssignee(
                        ticket: updatedTicket,
                        project: widget.project,
                        lastAssigneeEmail: remainingAssignees.first,
                      );
                    }

                    Navigator.pop(context);
                    _refreshTickets();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Marked as done'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            ListView.builder(
              shrinkWrap: true,
              itemCount: teamAssignees.length,
              itemBuilder: (context, index) {
                final email = teamAssignees[index];
                final details = _userDetails[email] ?? {};
                final displayName = _userService.getDisplayName(details, email);
                final profileUrl = details['profilePictureUrl'] ?? '';
                final firstLetter = displayName.isNotEmpty
                    ? displayName[0].toUpperCase()
                    : email[0].toUpperCase();

                // Check if this member has marked as done
                final isDone = ticket.membersDone.contains(email);
                final status = isDone ? 'Done' : 'Ongoing';
                final statusColor = isDone ? Colors.green : Colors.orange;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: profileUrl.isNotEmpty
                              ? NetworkImage(profileUrl)
                              : null,
                          onBackgroundImageError: profileUrl.isNotEmpty
                              ? (exception, stackTrace) {
                                  print('Error loading avatar for $email: $exception');
                                }
                              : null,
                          backgroundColor: _getColorForEmail(email),
                          child: profileUrl.isEmpty
                              ? Text(
                                  firstLetter,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          border: Border.all(color: statusColor, width: 1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeStatusDialog(Ticket ticket) async {
    final statuses = ['todo', 'in_progress', 'in_review', 'done'];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Ticket Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...statuses.map((status) {
              final isCurrentStatus = ticket.status == status;
              
              // Determine if this status option should be disabled
              bool isDisabled = false;
              String? disabledReason;
              
              // PM can only move to In Progress if assignees marked as done
              if (ticket.status == 'todo' && status == 'in_progress' && !ticket.allAssigneesDone) {
                isDisabled = true;
                disabledReason = 'Assignees must mark as done first';
              }
              // PM can only move to In Review if ticket was submitted for review
              else if (ticket.status == 'in_progress' && status == 'in_review' && !ticket.allAssigneesDone) {
                isDisabled = true;
                disabledReason = 'Assignees must submit for review first';
              }
              
              return ListTile(
                leading: _getStatusIcon(status),
                title: Text(_formatStatus(status)),
                subtitle: isDisabled && disabledReason != null
                    ? Text(
                        disabledReason,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      )
                    : null,
                trailing: isCurrentStatus ? const Icon(Icons.check) : null,
                enabled: !isDisabled && !isCurrentStatus,
                onTap: isCurrentStatus || isDisabled
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _handleStatusChange(ticket, status);
                      },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStatusChange(Ticket ticket, String newStatus) async {
    final oldStatus = ticket.status;
    
    // Show confirmation for specific transitions
    if (ticket.status == 'in_review') {
      if (newStatus == 'done') {
        // Confirm moving to Done
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Mark as Done?'),
            content: const Text(
              'When a ticket is marked as done, you cannot change its status or edit it anymore. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Mark as Done'),
              ),
            ],
          ),
        );
        
        if (confirmed != true) return;
      } else if (newStatus == 'todo' || newStatus == 'in_progress') {
        // Confirm reverting to previous status
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Revert Status?'),
            content: Text(
              'Are you sure you want to bring this ticket back to ${_formatStatus(newStatus)}? You can still edit the ticket as long as it\'s not marked as Done.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Revert Status'),
              ),
            ],
          ),
        );
        
        if (confirmed != true) return;
      }
    }
    
    // Update ticket status
    Ticket updatedTicket;
    
    // ALWAYS reset membersDone when PM changes status (except when moving to Done)
    // This ensures assignees must mark as done/submit for review at each stage
    if (newStatus != 'done') {
      updatedTicket = ticket.copyWith(
        status: newStatus,
        membersDone: [], // Clear so assignees must re-submit at each stage
      );
    } else {
      // When moving to Done, keep membersDone as is
      updatedTicket = ticket.copyWith(status: newStatus);
    }
    
    await _projectManager.updateTicket(
      ticket.projectId,
      ticket.ticketNumber,
      updatedTicket,
    );
    
    // Send notifications to assignees
    await _notificationService.notifyAssigneeStatusChanged(
      ticket: updatedTicket,
      project: widget.project,
      oldStatus: oldStatus,
      newStatus: newStatus,
    );
    
    _refreshTickets();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket status changed to ${_formatStatus(newStatus)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'todo':
        return const Icon(Icons.circle_outlined, color: Colors.grey);
      case 'in_progress':
        return const Icon(Icons.play_arrow, color: Colors.orange);
      case 'in_review':
        return const Icon(Icons.visibility, color: Colors.purple);
      case 'done':
        return const Icon(Icons.check_circle, color: Colors.green);
      default:
        return const Icon(Icons.circle);
    }
  }

  void _showDeleteConfirmation(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ticket'),
        content: Text('Are you sure you want to delete "${ticket.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _projectManager.deleteTicket(
                  ticket.projectId, ticket.ticketNumber);
              Navigator.pop(context);
              _refreshTickets();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${ticket.ticketNumber} deleted'),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: Colors.white,
                    onPressed: () {
                      _projectManager.addTicket(ticket);
                      _refreshTickets();
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Ticket ticket) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final isCreator = currentUser.uid == widget.project.userId;
    // Check if current user is assigned to this ticket
    final isAssigned = ticket.assignedTo.contains(currentUser.email);

    if (isCreator) {
      // Show Edit and Status buttons for project creator
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: ticket.status == 'done'
                  ? null
                  : () {
                      Navigator.pop(context);
                      _navigateToEditTicketPage(ticket);
                    },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E1E1E),
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                elevation: 0,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: ticket.status == 'done'
                  ? null
                  : (ticket.status == 'todo' || ticket.status == 'in_progress') && !ticket.allAssigneesDone
                      ? null
                      : () {
                          Navigator.pop(context);
                          _showChangeStatusDialog(ticket);
                        },
              icon: const Icon(Icons.change_circle_outlined),
              label: const Text('Change Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (isAssigned) {
      // Show workflow buttons based on status

      // Case 1: To Do -> Mark as Done (stays in todo)
      if (ticket.status == 'todo') {
        final isAlreadyDone = ticket.membersDone.contains(currentUser.email);
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isAlreadyDone
                ? null
                : () {
                    // Add user to membersDone, stay in todo
                    List<String> updatedMembersDone =
                        List.from(ticket.membersDone);
                    if (currentUser.email != null &&
                        !updatedMembersDone.contains(currentUser.email)) {
                      updatedMembersDone.add(currentUser.email!);
                    }

                    final updatedTicket =
                        ticket.copyWith(membersDone: updatedMembersDone);
                    _projectManager.updateTicket(
                        ticket.projectId, ticket.ticketNumber, updatedTicket);

                    // Send notification to PM
                    _notificationService.notifyPMTicketReady(
                      ticket: updatedTicket,
                      project: widget.project,
                      action: 'marked_done',
                    );

                    // Check if this is the last assignee
                    final remainingAssignees = updatedTicket.assignedTo
                        .where((email) => !updatedTicket.membersDone.contains(email))
                        .toList();

                    if (remainingAssignees.length == 1) {
                      _notificationService.notifyLastAssignee(
                        ticket: updatedTicket,
                        project: widget.project,
                        lastAssigneeEmail: remainingAssignees.first,
                      );
                    }

                    Navigator.pop(context);
                    _refreshTickets();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Marked as done'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
            icon: isAlreadyDone
                ? const Icon(Icons.check_circle)
                : const Icon(Icons.check_circle_outline),
            label: isAlreadyDone
                ? const Text('Already Marked Done')
                : const Text('Mark as Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isAlreadyDone ? Colors.green.shade600 : Colors.green.shade600,
              disabledBackgroundColor: Colors.green.shade600,
              disabledForegroundColor: Colors.white,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }
      // Case 2: In Progress -> Submit for Review
      else if (ticket.status == 'in_progress') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Add user to membersDone
              List<String> updatedMembersDone = List.from(ticket.membersDone);
              if (currentUser.email != null &&
                  !updatedMembersDone.contains(currentUser.email)) {
                updatedMembersDone.add(currentUser.email!);
              }

              // Update ticket but keep status as in_progress (PM controls status change)
              final updatedTicket = ticket.copyWith(
                membersDone: updatedMembersDone,
              );

              _projectManager.updateTicket(
                  ticket.projectId, ticket.ticketNumber, updatedTicket);

              // Send notification to PM
              _notificationService.notifyPMTicketReady(
                ticket: updatedTicket,
                project: widget.project,
                action: 'submitted_review',
              );

              Navigator.pop(context);
              _refreshTickets();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Submitted for review - PM can now change status'),
                  backgroundColor: Colors.purple,
                ),
              );
            },
            icon: const Icon(Icons.rate_review),
            label: const Text('Submit for Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }
      // Case 3: In Review -> Waiting
      else if (ticket.status == 'in_review') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: null, // Disabled
            icon: const Icon(Icons.hourglass_empty),
            label: const Text('Waiting for Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }
      // Case 4: Done -> Completed
      else if (ticket.status == 'done') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: null, // Disabled
            icon: const Icon(Icons.check_circle),
            label: const Text('Completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              disabledBackgroundColor: Colors.green.shade600,
              disabledForegroundColor: Colors.white,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'todo':
        return 'To Do';
      case 'in_progress':
        return 'In Progress';
      case 'in_review':
        return 'In Review';
      case 'done':
        return 'Done';
      default:
        return status;
    }
  }
}
