import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/projects/projects.dart';

class TicketCard extends StatefulWidget {
  final Ticket ticket;
  final Project? project;
  final VoidCallback? onTap;
  final bool isHighlighted;

  const TicketCard({
    super.key,
    required this.ticket,
    this.project,
    this.onTap,
    this.isHighlighted = false,
  });

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  late Map<String, Map<String, String>> _userDetails;
  bool _isLoading = true;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    
    // Initialize highlight animation controller
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _highlightAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeOut),
    );
    
    // Start animation if highlighted
    if (widget.isHighlighted) {
      _highlightController.forward();
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetails() async {
    try {
      print('🎫 TicketCard loading user details for ${widget.ticket.assignedTo.length} assignees');
      _userDetails = await _userService.getUsersDetailsByEmails(widget.ticket.assignedTo);
      print('✅ Loaded ${_userDetails.length} user details for ticket');
      _userDetails.forEach((email, data) {
        print('   $email -> profileUrl: ${data['profilePictureUrl']}');
      });
    } catch (e) {
      print('❌ Error loading user details: $e');
      _userDetails = {};
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getPriorityColor() {
    switch (widget.ticket.priority) {
      case 'high':
        return Colors.red.shade400;
      case 'medium':
        return Colors.purple.shade300;
      case 'low':
        return Colors.green.shade400;
      default:
        return Colors.grey;
    }
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

  Widget _buildAvatarStack() {
    final assignees = widget.ticket.assignedTo;
    
    // Filter out the project creator for workspace projects
    final currentUser = FirebaseAuth.instance.currentUser;
    final displayAssignees = widget.project?.category == 'workspace'
        ? assignees
            .where((email) => email != currentUser?.email)
            .toList()
        : assignees;
    
    if (displayAssignees.isEmpty) {
      return Tooltip(
        message: 'Unassigned',
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 1),
            color: Colors.grey.shade100,
          ),
          child: Icon(
            Icons.person_outline,
            size: 14,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    // Show max 3 avatars stacked
    final visibleCount = displayAssignees.length > 3 ? 3 : displayAssignees.length;
    final hasMore = displayAssignees.length > 3;
    final stackWidth = (visibleCount * 12.0) + 24; // Calculate total width needed

    return SizedBox(
      width: stackWidth,
      height: 28,
      child: Stack(
        children: [
          ...List.generate(visibleCount, (index) {
            final email = displayAssignees[index];
            final details = _userDetails[email] ?? {};
            final displayName = _userService.getDisplayName(details, email);
            final profileUrl = details['profilePictureUrl'] ?? '';
            final firstLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : email[0].toUpperCase();

            return Positioned(
              left: index * 12.0,
              child: Tooltip(
                message: displayName,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
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
                              fontSize: 10,
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
              left: visibleCount * 12.0,
              child: Tooltip(
                message: '${displayAssignees.length - 3} more',
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    color: Colors.grey.shade300,
                  ),
                  child: Center(
                    child: Text(
                      '+${displayAssignees.length - 3}',
                      style: const TextStyle(
                        fontSize: 8,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        final highlightOpacity = widget.isHighlighted ? _highlightAnimation.value : 0.0;
        
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.lerp(
                Colors.white,
                Colors.blue.shade50,
                highlightOpacity * 0.6,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color.lerp(
                  Colors.grey.shade200,
                  Colors.blue.shade300,
                  highlightOpacity,
                ) ?? Colors.grey.shade200,
                width: 1 + (highlightOpacity * 1.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(
                    Colors.black.withOpacity(0.04),
                    Colors.blue.withOpacity(0.2),
                    highlightOpacity,
                  ) ?? Colors.black.withOpacity(0.04),
                  blurRadius: 8 + (highlightOpacity * 4),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ticket Number
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.ticket.ticketNumber,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  widget.ticket.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  _getPlainTextFromDescription(widget.ticket.description),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Priority and Assigned To
                Row(
                  children: [
                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getPriorityColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.ticket.priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Avatar Stack
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _isLoading
                            ? SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
                                ),
                              )
                            : _buildAvatarStack(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}