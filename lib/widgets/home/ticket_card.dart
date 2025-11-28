import 'package:flutter/material.dart';
import 'package:zentry/models/ticket_model.dart';
import 'package:zentry/services/firebase/user_service.dart';

class TicketCard extends StatefulWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const TicketCard({
    super.key,
    required this.ticket,
    this.onTap,
  });

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard> {
  final UserService _userService = UserService();
  late Map<String, Map<String, String>> _userDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      _userDetails = await _userService.getUsersDetailsByEmails(widget.ticket.assignedTo);
    } catch (e) {
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

  Widget _buildAvatarStack() {
    final assignees = widget.ticket.assignedTo;
    if (assignees.isEmpty) {
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
    final visibleCount = assignees.length > 3 ? 3 : assignees.length;
    final hasMore = assignees.length > 3;
    final stackWidth = (visibleCount * 12.0) + 24; // Calculate total width needed

    return SizedBox(
      width: stackWidth,
      height: 28,
      child: Stack(
        children: [
          ...List.generate(visibleCount, (index) {
            final email = assignees[index];
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
              message: '${assignees.length - 3} more',
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
                    '+${assignees.length - 3}',
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
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
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
              widget.ticket.description,
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
  }
}