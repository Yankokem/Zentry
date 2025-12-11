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
  Map<String, Map<String, String>> _userDetails = {};
  bool _isLoadingUsers = true;
  String? _highlightedTicketId;

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
    // Load team members
    if (widget.project.teamMembers.isNotEmpty) {
      final details = await _userService
          .getUsersDetailsByEmails(widget.project.teamMembers);
      if (mounted) {
        setState(() {
          _userDetails = details;
        });
      }
    }

    // For shared projects, also load creator details by UID
    if (widget.project.category == 'shared') {
      try {
        final creatorDetails =
            await _userService.getUserDetailsByUid(widget.project.userId);
        if (creatorDetails != null && mounted) {
          setState(() {
            _userDetails[creatorDetails['email']!] = creatorDetails;
          });
        }
      } catch (e) {
        debugPrint('Error loading creator details: $e');
      }
    }

    if (mounted) {
      setState(() {
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

  double _calculateAvatarStackWidth() {
    final count = widget.project.teamMembers.length;
    // Each avatar overlaps by 10px (20px spacing on 30px diameter)
    return count > 0 ? (count - 1) * 20.0 + 30.0 : 30.0;
  }

  double _calculateAvatarStackWidthWithButton() {
    final count = widget.project.teamMembers.length;
    // Include space for all avatars plus the view all button
    return count > 0 ? count * 20.0 + 30.0 : 30.0;
  }

  List<Widget> _buildDetailAvatarStack() {
    final avatarWidgets = <Widget>[];

    // Get list of emails to display
    List<String> displayEmails = [];

    if (widget.project.category == 'shared') {
      // For shared projects, include all team members
      displayEmails = [...widget.project.teamMembers];

      // Add creator email if we have it loaded
      final creatorEmail = _userDetails.entries
          .firstWhere(
            (entry) => entry.value['uid'] == widget.project.userId,
            orElse: () => const MapEntry('', {}),
          )
          .key;

      if (creatorEmail.isNotEmpty && !displayEmails.contains(creatorEmail)) {
        displayEmails.add(creatorEmail);
      }
    } else {
      // For workspace, exclude creator
      displayEmails = widget.project.teamMembers
          .where(
              (email) => _userDetails[email]?['uid'] != widget.project.userId)
          .toList();
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMemberTileWithRole(
                          displayName, email, profileUrl, 'Member'),
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

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage:
              profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
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
                      color: role == 'Project Manager'
                          ? Colors.blue.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: role == 'Project Manager'
                            ? Colors.blue.shade300
                            : Colors.green.shade300,
                      ),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: role == 'Project Manager'
                            ? Colors.blue.shade700
                            : Colors.green.shade700,
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

  Widget _buildMemberTile(String displayName, String email, String profileUrl) {
    // Check if member is pending
    final isPending = widget.project.isMemberPending(email);

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage:
              profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
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
                        // Add Ticket Button
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKanbanColumn(
                    'To Do',
                    _getTicketsByStatus('todo'),
                    Colors.grey.shade400,
                    'todo',
                  ),
                  const SizedBox(width: 16),
                  _buildKanbanColumn(
                    'In Progress',
                    _getTicketsByStatus('in_progress'),
                    Colors.orange.shade400,
                    'in_progress',
                  ),
                  const SizedBox(width: 16),
                  _buildKanbanColumn(
                    'In Review',
                    _getTicketsByStatus('in_review'),
                    Colors.purple.shade400,
                    'in_review',
                  ),
                  const SizedBox(width: 16),
                  _buildKanbanColumn(
                    'Done',
                    _getTicketsByStatus('done'),
                    Colors.green.shade400,
                    'done',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(
    String title,
    Future<List<Ticket>> ticketsFuture,
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
                FutureBuilder<List<Ticket>>(
                  future: ticketsFuture,
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Tickets List
          Flexible(
            child: FutureBuilder<List<Ticket>>(
              future: ticketsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading tickets',
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                  );
                } else {
                  final tickets = snapshot.data ?? [];
                  return tickets.isEmpty
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
                        );
                }
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

            // Description
            Text(
              ticket.description,
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

  void _showAddTicketDialog() {
    TicketDialogs.showAddTicketDialog(context, widget.project, _refreshTickets);
  }

  void _showEditTicketDialog(Ticket ticket) {
    TicketDialogs.showEditTicketDialog(
        context, ticket, widget.project, _refreshTickets);
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
                    if (currentUser?.email != null &&
                        !updatedMembersDone.contains(currentUser!.email)) {
                      updatedMembersDone.add(currentUser.email!);
                    }

                    final updatedTicket =
                        ticket.copyWith(membersDone: updatedMembersDone);
                    await _projectManager.updateTicket(
                        ticket.projectId, ticket.ticketNumber, updatedTicket);

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

  String? _getRoleForEmail(String email) {
    // Check if this email belongs to the project creator
    // The project.userId contains the UID of the creator
    // We need to find the creator's email from _userDetails or teamMemberDetails

    // First, find if this email's user is the project creator by checking their UID
    for (final member in widget.project.teamMemberDetails) {
      if (member.email == email) {
        // This person is in the team - check if they're the creator
        // We'll need to verify by checking if their UID matches project.userId
        // For now, let's check from user details
        final details = _userDetails[email] ?? {};
        // We can't directly compare UID here, so we'll use a different approach
        break;
      }
    }

    // Check if this email is the current user and they are the project creator
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == widget.project.userId) {
      // Current user is the project creator
      // Check if the email being checked is the current user's email
      if (currentUser.email == email) {
        return 'Project Manager';
      }
    }

    // Find explicit roles from project roles
    for (final role in widget.project.roles) {
      if (role.members.contains(email)) {
        return role.name;
      }
    }

    // If they're in the team but not the creator and no explicit role, they're a member
    if (widget.project.teamMembers.contains(email)) {
      return 'Member';
    }

    return null;
  }

  void _showChangeStatusDialog(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('todo', 'To Do', Colors.grey.shade400, ticket),
            _buildStatusOption(
                'in_progress', 'In Progress', Colors.orange.shade400, ticket),
            _buildStatusOption(
                'in_review', 'In Review', Colors.purple.shade400, ticket),
            _buildStatusOption('done', 'Done', Colors.green.shade400, ticket),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
      String statusValue, String statusLabel, Color color, Ticket ticket) {
    final isCurrentStatus = ticket.status == statusValue;

    return InkWell(
      onTap: () {
        if (!isCurrentStatus) {
          final updatedTicket = ticket.copyWith(status: statusValue);
          _projectManager.updateTicket(
              ticket.projectId, ticket.ticketNumber, updatedTicket);
          Navigator.pop(context);
          _refreshTickets();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved to $statusLabel'),
              backgroundColor: color,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrentStatus ? color.withOpacity(0.2) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentStatus ? color : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCurrentStatus ? FontWeight.bold : FontWeight.w500,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            const Spacer(),
            if (isCurrentStatus)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
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
              onPressed: () {
                Navigator.pop(context);
                _navigateToEditTicketPage(ticket);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E1E1E),
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
              onPressed: ticket.status == 'todo' && !ticket.allAssigneesDone
                  ? null
                  : () {
                      Navigator.pop(context);
                      _showChangeStatusDialog(ticket);
                    },
              icon: const Icon(Icons.change_circle_outlined),
              label: ticket.status == 'todo'
                  ? const Text('Move to In Progress')
                  : const Text('Change Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    ticket.status == 'todo' && !ticket.allAssigneesDone
                        ? Colors.grey.shade400
                        : const Color(0xFF1E1E1E),
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

              // Move to In Review
              final updatedTicket = ticket.copyWith(
                status: 'in_review',
                membersDone: updatedMembersDone,
              );

              _projectManager.updateTicket(
                  ticket.projectId, ticket.ticketNumber, updatedTicket);

              Navigator.pop(context);
              _refreshTickets();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Submitted for review'),
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
