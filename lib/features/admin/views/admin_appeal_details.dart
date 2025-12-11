import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zentry/features/admin/admin.dart';
import 'package:zentry/features/journal/widgets/rich_text_viewer.dart';

class AdminAppealDetailsScreen extends StatefulWidget {
  final AccountAppealModel appeal;

  const AdminAppealDetailsScreen({
    super.key,
    required this.appeal,
  });

  @override
  State<AdminAppealDetailsScreen> createState() =>
      _AdminAppealDetailsScreenState();
}

class _AdminAppealDetailsScreenState extends State<AdminAppealDetailsScreen> {
  late final AccountAppealService _service = AccountAppealService();
  String _selectedStatus = '';
  bool _isUpdating = false;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Only set status if it's a valid option for this appeal type
    final isSuspension = widget.appeal.reason == 'suspension';
    final validOptions = isSuspension
        ? ['1 day', '3 days', '7 days', '14 days', '30 days', 'Lift Suspension', 'Rejected']
        : ['Lift Ban', 'Rejected'];
    
    if (validOptions.contains(widget.appeal.status)) {
      _selectedStatus = widget.appeal.status;
    } else {
      _selectedStatus = '';
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • hh:mm a');
    final isSuspension = widget.appeal.reason == 'suspension';
    final statusColor = _getStatusColor(widget.appeal.status);
    final isClosed = widget.appeal.status == 'Closed';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Appeal Details'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Suspension/Ban Badge at top
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSuspension
                          ? Colors.orange.withOpacity(0.15)
                          : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isSuspension ? 'SUSPENSION' : 'BAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSuspension ? Colors.orange[700] : Colors.red[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.appeal.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.appeal.userEmail,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.appeal.status,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        dateFormat.format(widget.appeal.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Appeal Content - Show for all appeals
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appeal Statement',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichTextViewer(content: widget.appeal.content),
                  if (widget.appeal.evidenceUrls.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Evidence Provided',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: widget.appeal.evidenceUrls.length,
                      itemBuilder: (context, index) {
                        final imageUrl = widget.appeal.evidenceUrls[index];
                        return GestureDetector(
                          onTap: () => _showImageFullscreen(context, imageUrl),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.image_not_supported_rounded,
                                          color: Colors.grey[400],
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.zoom_in_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Admin Decision Panel
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isClosed ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                        color: isClosed ? Colors.green[600] : Colors.orange[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isClosed ? 'Appeal Closed' : 'Appeal Decision',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Show admin response and decision when closed
                  if (isClosed) ...[
                    if (widget.appeal.adminResponse != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.message_rounded,
                                  color: Colors.black,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Admin Response',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.appeal.adminResponse!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.appeal.decision != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.gavel_rounded,
                                  color: Colors.green[600],
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Decision Made',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.appeal.decision!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    // Show decision form when pending

                    // Decision Selection - disabled if closed
                    Text(
                      'Adjust Appeal Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: isClosed ? 0.5 : 1.0,
                      child: IgnorePointer(
                        ignoring: isClosed,
                        child: _buildDecisionDropdown(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Reason Field (Always Visible and Required)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Reason',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '*',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _reasonController,
                          enabled: !isClosed,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Provide your reasoning for this decision...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF5B4CFF),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons - disabled if closed
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (isClosed || _isUpdating) ? null : _submitDecision,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF9ED69),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: _isUpdating
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.check_circle_rounded),
                            label: Text(
                              _isUpdating ? 'Submitting...' : 'Submit Decision',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: (isClosed || _isUpdating) ? null : _deleteAppeal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red[600],
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.red[200]!),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.delete_rounded, size: 18),
                          label: const Text(
                            'Delete',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionDropdown() {
    final isSuspension = widget.appeal.reason == 'suspension';
    
    final options = isSuspension
        ? ['1 day', '3 days', '7 days', '14 days', '30 days', 'Lift Suspension', 'Rejected']
        : ['Lift Ban', 'Rejected'];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedStatus.isNotEmpty ? _selectedStatus : null,
        hint: Text(
          'Select suspension adjustment',
          style: TextStyle(color: Colors.grey[400]),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        items: options
            .map((status) => DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        status,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedStatus = value ?? '';
          });
        },
      ),
    );
  }

  Future<void> _submitDecision() async {
    // Validate required fields
    if (_selectedStatus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a decision')),
      );
      return;
    }

    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for this decision')),
      );
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await _service.updateAppealWithResponse(
        widget.appeal.id,
        'Closed',
        _reasonController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appeal decision submitted successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting decision: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _deleteAppeal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appeal'),
        content: const Text('Are you sure you want to delete this appeal? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appeal deletion not yet implemented')),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status.toLowerCase()) {
      '1 day' || '3 days' || '7 days' || '14 days' || '30 days' => Colors.green,
      'lift suspension' || 'lift ban' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.grey,
    };
  }

  void _showImageFullscreen(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_rounded,
                          color: Colors.grey[400],
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load image',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
