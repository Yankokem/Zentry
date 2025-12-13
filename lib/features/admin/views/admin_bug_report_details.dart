import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zentry/features/admin/admin.dart';
import 'package:zentry/features/journal/widgets/rich_text_viewer.dart';

class AdminBugReportDetailsScreen extends StatefulWidget {
  final BugReportModel report;

  const AdminBugReportDetailsScreen({
    super.key,
    required this.report,
  });

  @override
  State<AdminBugReportDetailsScreen> createState() =>
      _AdminBugReportDetailsScreenState();
}

class _AdminBugReportDetailsScreenState
    extends State<AdminBugReportDetailsScreen> {
  late final BugReportService _service = BugReportService();
  String _selectedStatus = '';
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • hh:mm a');
    final statusColor = _getStatusColor(widget.report.status);
    final isClosed = widget.report.status == 'Closed';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Bug Report Details'),
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
                  Text(
                    widget.report.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Category: ${widget.report.category}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
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
                          widget.report.status,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        dateFormat.format(widget.report.createdAt),
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

            // Report Content
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Description',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichTextViewer(content: widget.report.content),
                  if (widget.report.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Attachments',
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
                      itemCount: widget.report.imageUrls.length,
                      itemBuilder: (context, index) {
                        final imageUrl = widget.report.imageUrls[index];
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

            // Admin Actions Panel
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Actions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status Selection
                  Text(
                    'Update Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildStatusDropdown(),
                  const SizedBox(height: 20),

                  // Action Buttons (disabled if closed)
                  if (isClosed)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outlined, color: Colors.grey[600], size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This report is closed and cannot be modified',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUpdating ? null : _updateReport,
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
                              _isUpdating ? 'Updating...' : 'Save Changes',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _isUpdating ? null : _deleteReport,
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
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    final isClosed = widget.report.status == 'Closed';
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedStatus.isNotEmpty ? _selectedStatus : null,
        hint: Text(
          'Select a status',
          style: TextStyle(color: Colors.grey[400]),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        disabledHint: Text(
          'This report is closed',
          style: TextStyle(color: Colors.grey[500]),
        ),
        items: isClosed ? null : ['Open', 'In Progress', 'Closed']
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
        onChanged: isClosed ? null : (value) {
          setState(() {
            _selectedStatus = value ?? '';
          });
        },
      ),
    );
  }

  Future<void> _updateReport() async {
    setState(() => _isUpdating = true);
    try {
      await _service.updateBugReportStatus(
        widget.report.id, 
        _selectedStatus,
        oldStatus: widget.report.status,
        title: widget.report.title,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report updated successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating report: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _deleteReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
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
      const SnackBar(content: Text('Report deletion not yet implemented')),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status.toLowerCase()) {
      'open' => Colors.orange,
      'in progress' => Colors.blue,
      'closed' => Colors.green,
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
