import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zentry/models/project_model.dart';
import 'package:zentry/models/ticket_model.dart';
import 'package:zentry/services/firebase/user_service.dart';
import 'package:zentry/services/project_manager.dart';
import 'package:zentry/views/home/add_ticket_page.dart';
import 'package:zentry/views/home/edit_ticket_page.dart';
import 'package:zentry/widgets/home/ticket_card.dart';
import 'package:zentry/widgets/home/ticket_dialogs.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;

  const ProjectDetailPage({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final ProjectManager _projectManager = ProjectManager();
  final UserService _userService = UserService();
  Map<String, Map<String, String>> _userDetails = {};
  bool _isLoadingUsers = true;

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
  }

  Future<void> _loadUserDetails() async {
    if (widget.project.teamMembers.isNotEmpty) {
      final details = await _userService.getUsersDetailsByEmails(widget.project.teamMembers);
      if (mounted) {
        setState(() {
          _userDetails = details;
          _isLoadingUsers = false;
        });
      }
    } else {
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
    
    for (int i = 0; i < widget.project.teamMembers.length; i++) {
      final member = widget.project.teamMembers[i];
      final details = _userDetails[member] ?? {};
      final displayName = _userService.getDisplayName(details, member);
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
                backgroundImage: profileUrl.isNotEmpty
                    ? NetworkImage(profileUrl)
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCreator = currentUser?.uid == widget.project.userId;
    
    if (isCreator && currentUser?.email != null) {
      // If current user is the creator, use their details
      creatorDetails = await _userService.getUserDetailsByEmail(currentUser!.email!);
    } else {
      // Find creator from team members or fetch by userId
      for (final email in widget.project.teamMembers) {
        final userDetails = _userDetails[email];
        if (userDetails != null) {
          creatorDetails = userDetails;
          break;
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
              'Team Members',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Project Manager Section
                  Text(
                    'Project Manager',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (creatorDetails != null)
                    _buildMemberTile(
                      creatorDetails['fullName'] ?? creatorDetails['email'] ?? 'Unknown',
                      currentUser?.email ?? '',
                      creatorDetails['profilePictureUrl'] ?? '',
                    ),
                  const SizedBox(height: 16),

                  // Roles and their members
                  ...widget.project.roles.map((role) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...role.members.map((email) {
                          final details = _userDetails[email] ?? {};
                          final displayName = _userService.getDisplayName(details, email);
                          final profileUrl = details['profilePictureUrl'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildMemberTile(displayName, email, profileUrl),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),

                  // Members without roles (if any)
                  if (widget.project.roles.isNotEmpty) ...[
                    Builder(
                      builder: (context) {
                        final membersInRoles = widget.project.roles
                            .expand((role) => role.members)
                            .toSet();
                        final creatorEmail = currentUser?.email;
                        final membersWithoutRoles = widget.project.teamMembers
                            .where((email) => 
                                email != creatorEmail && 
                                !membersInRoles.contains(email))
                            .toList();

                        if (membersWithoutRoles.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Other Members',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...membersWithoutRoles.map((email) {
                              final details = _userDetails[email] ?? {};
                              final displayName = _userService.getDisplayName(details, email);
                              final profileUrl = details['profilePictureUrl'] ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildMemberTile(displayName, email, profileUrl),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ] else ...[
                    // No roles defined, show all other members
                    ...widget.project.teamMembers
                        .where((email) => email != currentUser?.email)
                        .map((email) {
                      final details = _userDetails[email] ?? {};
                      final displayName = _userService.getDisplayName(details, email);
                      final profileUrl = details['profilePictureUrl'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMemberTile(displayName, email, profileUrl),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(String displayName, String email, String profileUrl) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: profileUrl.isNotEmpty
              ? NetworkImage(profileUrl)
              : null,
          backgroundColor: Colors.grey.shade300,
          child: profileUrl.isEmpty
              ? Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
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
                                  color: const Color(0xFF1E1E1E).withOpacity(0.7),
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
                                    left: widget.project.teamMembers.length * 20.0,
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
                                            border: Border.all(color: Colors.white, width: 2),
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
                            return TicketCard(
                              ticket: tickets[index],
                              onTap: () {
                                _showTicketDetailsSheet(tickets[index]);
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            _buildDetailRow(Icons.flag_outlined, 'Priority', ticket.priority.toUpperCase()),
            const SizedBox(height: 12),
            
            // Assigned To with Avatar Stack
            Row(
              children: [
                Icon(Icons.person_outline, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Text(
                  'Assigned To: ',
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
              child: _buildAssigneeAvatarStack(
                ticket.assignedTo,
                onViewMore: () => _showAssigneesModal(ticket.assignedTo),
              ),
            ),
            const SizedBox(height: 12),
            
            _buildDetailRow(Icons.assignment_outlined, 'Status', _formatStatus(ticket.status)),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToEditTicketPage(ticket);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getProjectColor(),
                      foregroundColor: const Color(0xFF1E1E1E),
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
                    onPressed: () {
                      Navigator.pop(context);
                      _showChangeStatusDialog(ticket);
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Delete Button
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
    TicketDialogs.showEditTicketDialog(context, ticket, widget.project.teamMembers, _refreshTickets);
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

  Widget _buildAssigneeAvatarStack(List<String> assignees, {VoidCallback? onViewMore}) {
    if (assignees.isEmpty) {
      return Row(
        children: [
          Icon(Icons.person_outline, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          const Text('Unassigned'),
        ],
      );
    }

    // Show max 4 avatars stacked plus a "View" button
    final visibleCount = assignees.length > 4 ? 4 : assignees.length;
    final hasMore = assignees.length > 4;
    final stackWidth = hasMore ? (visibleCount * 16.0) + 28 : (visibleCount * 16.0) + 16;

    return Row(
      children: [
        SizedBox(
          width: stackWidth,
          height: 32,
          child: Stack(
            children: [
            ...List.generate(visibleCount, (index) {
              final email = assignees[index];
              final details = _userDetails[email] ?? {};
              final displayName = _userService.getDisplayName(details, email);
              final profileUrl = details['profilePictureUrl'] ?? '';
              final firstLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : email[0].toUpperCase();

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
                      backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
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
                  message: '${assignees.length - 4} more',
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
                        '+${assignees.length - 4}',
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
                'View Assignees',
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

  void _showAssigneesModal(List<String> assignees) {
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
            Text(
              'Assignees (${assignees.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              itemCount: assignees.length,
              itemBuilder: (context, index) {
                final email = assignees[index];
                final details = _userDetails[email] ?? {};
                final displayName = _userService.getDisplayName(details, email);
                final profileUrl = details['profilePictureUrl'] ?? '';
                final firstLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : email[0].toUpperCase();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                          backgroundColor: _getColorForEmail(email),
                          child: profileUrl.isEmpty
                              ? Text(
                                  firstLetter,
                                  style: const TextStyle(
                                    fontSize: 13,
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
                            ),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
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

  void _showChangeStatusDialog(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('todo', 'To Do', Colors.grey.shade400, ticket),
            _buildStatusOption('in_progress', 'In Progress', Colors.orange.shade400, ticket),
            _buildStatusOption('in_review', 'In Review', Colors.purple.shade400, ticket),
            _buildStatusOption('done', 'Done', Colors.green.shade400, ticket),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(String statusValue, String statusLabel, Color color, Ticket ticket) {
    final isCurrentStatus = ticket.status == statusValue;
    
    return InkWell(
      onTap: () {
        if (!isCurrentStatus) {
          final updatedTicket = ticket.copyWith(status: statusValue);
          _projectManager.updateTicket(ticket.projectId, ticket.ticketNumber, updatedTicket);
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
              _projectManager.deleteTicket(ticket.projectId, ticket.ticketNumber);
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