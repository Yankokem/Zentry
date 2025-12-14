import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/projects/projects.dart';

class ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPinToggle;
  final VoidCallback? onStatusChanged;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onPinToggle,
    this.onStatusChanged,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  final UserService _userService = UserService();
  Map<String, Map<String, String>> _userDetails = {};
  bool _isLoadingUsers = true;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // Avoid adding properties that might cause LegacyJavaScriptObject issues
    properties.add(StringProperty('title', widget.project.title));
    properties.add(StringProperty('description', widget.project.description));
    properties.add(StringProperty('status', widget.project.status));
  }

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final details = <String, Map<String, String>>{};
    
    // Always load team members by email
    if (widget.project.teamMembers.isNotEmpty) {
      final teamDetails = await _userService.getUsersDetailsByEmails(widget.project.teamMembers);
      details.addAll(teamDetails);
    }

    // Load project creator/manager by UID
    // project.userId is a UID, we need to fetch and store by email
    if (widget.project.userId.isNotEmpty) {
      try {
        final creatorDetails = await _userService.getUserDetailsByUid(widget.project.userId);
        if (creatorDetails != null && creatorDetails['email'] != null) {
          // Store creator details keyed by their email so avatar lookup works
          details[creatorDetails['email']!] = creatorDetails;
          print('✅ Loaded creator details: ${creatorDetails['email']} (UID: ${widget.project.userId})');
        }
      } catch (e) {
        print('⚠️ Error loading creator details by UID: $e');
      }
    }

    print('🔍 ProjectCard loaded ${details.length} user details for project: ${widget.project.title}');
    
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

  Color _getStatusColor() {
    switch (widget.project.status) {
      case 'In Progress':
        return Colors.orange;
      case 'Planning':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  double _calculateStackWidth() {
    // Filter out the project creator for workspace projects
    final currentUser = FirebaseAuth.instance.currentUser;
    final displayMembers = widget.project.category == 'workspace'
        ? widget.project.teamMembers
            .where((email) => email != currentUser?.email)
            .toList()
        : widget.project.teamMembers;

    final count = displayMembers.length > 10 ? 10 : displayMembers.length;
    // Each avatar overlaps by 8px (18px spacing on 26px diameter)
    return count > 0 ? (count - 1) * 18.0 + 28.0 : 28.0;
  }

  List<Widget> _buildAvatarStack() {
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

    final count = displayEmails.length > 10 ? 10 : displayEmails.length;

    for (int i = 0; i < count; i++) {
      final email = displayEmails[i];
      final details = _userDetails[email] ?? {};
      final displayName = _userService.getDisplayName(details, email);
      final profileUrl = details['profilePictureUrl'] ?? '';

      avatarWidgets.add(
        Positioned(
          left: i * 18.0,
          child: Tooltip(
            message: displayName,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 12,
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
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
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
      for (final email in [...widget.project.teamMembers]) {
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
                  if (creatorDetails != null && creatorEmail != null)
                    _buildMemberTile(
                      creatorDetails['fullName'] ??
                          creatorDetails['email'] ??
                          'Unknown',
                      creatorEmail,
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
                          final displayName =
                              _userService.getDisplayName(details, email);
                          final profileUrl = details['profilePictureUrl'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildMemberTile(
                                displayName, email, profileUrl),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),

                  // Members without roles (if any)
                  if (widget.project.roles.isNotEmpty) ...[
                    // Find members not in any role
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

                        if (membersWithoutRoles.isEmpty) {
                          return const SizedBox.shrink();
                        }

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
                              final displayName =
                                  _userService.getDisplayName(details, email);
                              final profileUrl =
                                  details['profilePictureUrl'] ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildMemberTile(
                                    displayName, email, profileUrl),
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
                      final displayName =
                          _userService.getDisplayName(details, email);
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
          backgroundImage:
              profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
          onBackgroundImageError: profileUrl.isNotEmpty
              ? (exception, stackTrace) {
                  print('Error loading profile image: $exception');
                }
              : null,
          backgroundColor: Colors.grey.shade300,
          child: profileUrl.isEmpty
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
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

  void _showStatusChangeSheet() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isProjectCreator = currentUser?.uid == widget.project.userId;

    if (!isProjectCreator) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Only project creators can change status')),
      );
      return;
    }

    final statuses = ['Planning', 'In Progress', 'Completed'];

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
              'Change Project Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...statuses.map((status) => ListTile(
                  leading: Icon(
                    status == 'Completed'
                        ? Icons.check_circle
                        : status == 'In Progress'
                            ? Icons.play_circle
                            : Icons.schedule,
                    color: _getStatusColorForStatus(status),
                  ),
                  title: Text(status),
                  trailing: widget.project.status == status
                      ? Icon(Icons.check,
                          color: _getStatusColorForStatus(status))
                      : null,
                  onTap: () async {
                    if (widget.project.status == status) {
                      Navigator.of(context).pop();
                      return;
                    }

                    try {
                      final projectManager = ProjectManager();
                      final updatedProject =
                          widget.project.copyWith(status: status);
                      await projectManager.updateProject(updatedProject);
                      Navigator.of(context).pop();
                      widget.onStatusChanged?.call();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Project status changed to $status')),
                      );
                    } catch (e) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating status: $e')),
                      );
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  Color _getStatusColorForStatus(String status) {
    switch (status) {
      case 'In Progress':
        return Colors.orange;
      case 'Planning':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with colored accent and action buttons
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: _getProjectColor(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title, Status and Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.project.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E1E1E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.project.isPinned) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.push_pin,
                                size: 16,
                                color: Color(0xFFF9ED69),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showStatusChangeSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.project.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'edit') {
                            widget.onEdit?.call();
                          } else if (value == 'delete') {
                            widget.onDelete?.call();
                          } else if (value == 'pin') {
                            widget.onPinToggle?.call();
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          final currentUser = FirebaseAuth.instance.currentUser;
                          final isProjectCreator =
                              currentUser?.uid == widget.project.userId;

                          return [
                            PopupMenuItem<String>(
                              value: 'pin',
                              child: Row(
                                children: [
                                  Icon(
                                      widget.project.isPinned
                                          ? Icons.push_pin
                                          : Icons.push_pin_outlined,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Text(widget.project.isPinned
                                      ? 'Unpin'
                                      : 'Pin'),
                                ],
                              ),
                            ),
                            // Only show Manage button to project creator
                            if (isProjectCreator)
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.settings, size: 18),
                                    SizedBox(width: 8),
                                    Text('Manage'),
                                  ],
                                ),
                              ),
                            // Only show Delete button to project creator
                            if (isProjectCreator)
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                          ];
                        },
                        icon: const Icon(Icons.more_vert, size: 20),
                        tooltip: 'More options',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    widget.project.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Team Members - Avatar Group
                  if (widget.project.teamMembers.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                // Overlapping avatars using Stack
                                SizedBox(
                                  height: 28,
                                  width: _calculateStackWidth(),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: _buildAvatarStack(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Show badge for additional members when > 10
                                Builder(builder: (context) {
                                  final currentUser =
                                      FirebaseAuth.instance.currentUser;
                                  final displayMembers =
                                      widget.project.category == 'workspace'
                                          ? widget.project.teamMembers
                                              .where((email) =>
                                                  email != currentUser?.email)
                                              .toList()
                                          : widget.project.teamMembers;

                                  if (displayMembers.length > 10) {
                                    return Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '+${displayMembers.length - 10}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 16),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${widget.project.completedTickets}/${widget.project.totalTickets} tickets',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: widget.project.totalTickets > 0
                              ? widget.project.completedTickets /
                                  widget.project.totalTickets
                              : 0,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProjectColor(),
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
