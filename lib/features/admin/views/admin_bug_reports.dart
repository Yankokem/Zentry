import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:zentry/features/admin/admin.dart';
import 'package:zentry/features/admin/widgets/skeleton_loader.dart';

class AdminBugReportsPage extends StatefulWidget {
  const AdminBugReportsPage({super.key});

  @override
  State<AdminBugReportsPage> createState() => _AdminBugReportsPageState();
}

class _AdminBugReportsPageState extends State<AdminBugReportsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final BugReportService _bugReportService = BugReportService();
  String _selectedStatusFilter = ''; // Empty string means show all

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<BugReportModel>>(
              stream: _bugReportService.getBugReportsStream(),
              builder: (context, snapshot) {
                // Debug logging
                print('🐛 Bug Reports Stream State:');
                print('  ConnectionState: ${snapshot.connectionState}');
                print('  Has Data: ${snapshot.hasData}');
                print('  Has Error: ${snapshot.hasError}');
                print('  Data Length: ${snapshot.data?.length ?? 0}');
                if (snapshot.hasError) {
                  print('  Error: ${snapshot.error}');
                }

                // Error state - check first!
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text('Failed to load bug reports'),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Loading state - only when waiting for first data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: SkeletonStatCard()),
                          const SizedBox(width: 12),
                          Expanded(child: SkeletonStatCard()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 5,
                          itemBuilder: (context, index) => const SkeletonListItem(),
                        ),
                      ),
                    ],
                  );
                }

                // Data state
                final reports = snapshot.data ?? [];
                final openReports = reports.where((r) => r.status == 'Open').length;
                final inProgressReports = reports.where((r) => r.status == 'In Progress').length;
                final closedReports = reports.where((r) => r.status == 'Closed').length;

                // Filter reports based on selected status
                final filteredReports = _selectedStatusFilter.isEmpty
                    ? reports
                    : reports.where((r) => r.status == _selectedStatusFilter).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row with 3 cards
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStatusFilter = _selectedStatusFilter == 'Open' ? '' : 'Open';
                              });
                            },
                            child: _buildStatChip(
                              context,
                              icon: Icons.error_outline_rounded,
                              label: 'Open',
                              count: openReports,
                              color: Colors.orange,
                              isSelected: _selectedStatusFilter == 'Open',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStatusFilter = _selectedStatusFilter == 'In Progress' ? '' : 'In Progress';
                              });
                            },
                            child: _buildStatChip(
                              context,
                              icon: Icons.pending_outlined,
                              label: 'In Progress',
                              count: inProgressReports,
                              color: Colors.blue,
                              isSelected: _selectedStatusFilter == 'In Progress',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStatusFilter = _selectedStatusFilter == 'Closed' ? '' : 'Closed';
                              });
                            },
                            child: _buildStatChip(
                              context,
                              icon: Icons.check_circle_rounded,
                              label: 'Closed',
                              count: closedReports,
                              color: Colors.green,
                              isSelected: _selectedStatusFilter == 'Closed',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Reports List
                    Expanded(
                      child: filteredReports.isEmpty
                          ? const Center(
                              child: Text('No bug reports'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: filteredReports.length,
                              itemBuilder: (context, i) {
                                final report = filteredReports[i];
                                return _buildReportCard(context, report);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, BugReportModel report) {
    final statusColor = _getStatusColor(report.status);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminBugReportDetailsScreen(report: report),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  report.category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.status,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.userEmail,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(report.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (report.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${report.imageUrls.length} image(s) attached',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    bool isSelected = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.15) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color.withOpacity(0.6) : color.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
