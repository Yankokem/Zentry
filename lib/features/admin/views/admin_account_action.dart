import 'package:flutter/material.dart';

import 'package:zentry/core/core.dart';

class AdminAccountActionPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String action; // 'suspend' or 'ban'

  const AdminAccountActionPage({
    super.key,
    required this.user,
    required this.action,
  });

  @override
  State<AdminAccountActionPage> createState() => _AdminAccountActionPageState();
}

class _AdminAccountActionPageState extends State<AdminAccountActionPage> {
  final AdminService _adminService = AdminService();
  final reasonController = TextEditingController();
  String selectedDuration = '7 days';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isSuspend = widget.action == 'suspend';
    final actionColor = isSuspend ? Colors.orange : Colors.red;
    final actionIcon = isSuspend ? Icons.pause_circle_outline : Icons.block;
    final actionTitle = isSuspend ? 'Suspend User' : 'Ban User';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Yellow Header - matching bug report details design
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF9ED69),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: const Color(0xFF1E1E1E),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: actionColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            isSuspend ? 'SUSPEND' : 'BAN',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      actionTitle,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E1E1E),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user['name'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF1E1E1E).withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Information Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Information',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E1E1E),
                                  ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFFF9ED69),
                                    const Color(0xFFF9ED69).withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: Text(
                                  widget.user['name']
                                      .toString()
                                      .split(' ')
                                      .map((s) => s.isNotEmpty ? s[0] : '')
                                      .take(2)
                                      .join(),
                                  style: const TextStyle(
                                    color: Color(0xFF1E1E1E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.user['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Last active: ${widget.user['lastActive']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(Icons.tag_rounded, 'User ID',
                            widget.user['id']?.toString() ?? ''),
                        const SizedBox(height: 16),
                        _buildDetailRow(Icons.person_outline_rounded, 'Role',
                            widget.user['role']?.toString() ?? ''),
                        const SizedBox(height: 16),
                        _buildDetailRow(Icons.calendar_today_rounded, 'Status',
                            widget.user['status']?.toString() ?? ''),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Details Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: actionColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                actionIcon,
                                color: actionColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Action Details',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E1E1E),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Warning for Ban
                        if (!isSuspend)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.red[700], size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This action is permanent and cannot be undone.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!isSuspend) const SizedBox(height: 20),

                        // Duration for Suspend
                        if (isSuspend) ...[
                          const Text(
                            'Suspension Duration',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedDuration,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                items: [
                                  '1 day',
                                  '3 days',
                                  '7 days',
                                  '14 days',
                                  '30 days',
                                ].map((duration) {
                                  return DropdownMenuItem(
                                    value: duration,
                                    child: Text(duration),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedDuration = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Reason
                        const Text(
                          'Reason',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: reasonController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                'Enter reason for ${isSuspend ? 'suspension' : 'ban'}...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () async {
                                  if (reasonController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Please provide a reason'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() => _isProcessing = true);

                                  try {
                                    if (isSuspend) {
                                      await _adminService.updateUserStatus(
                                        userId: widget.user['id'],
                                        status: 'suspended',
                                        reason: reasonController.text.trim(),
                                        duration: selectedDuration,
                                        userEmail: widget.user['email'],
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '${widget.user['name']} suspended for $selectedDuration'),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    } else {
                                      await _adminService.updateUserStatus(
                                        userId: widget.user['id'],
                                        status: 'banned',
                                        reason: reasonController.text.trim(),
                                        userEmail: widget.user['email'],
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '${widget.user['name']} has been banned'),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                    if (mounted) {
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isProcessing = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: actionColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  isSuspend ? 'Suspend User' : 'Ban User',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
