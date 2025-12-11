import 'package:flutter/material.dart';

import 'package:zentry/features/admin/admin.dart';
import 'package:zentry/features/admin/widgets/skeleton_loader.dart';

class AdminAppealsPage extends StatefulWidget {
  const AdminAppealsPage({super.key});

  @override
  State<AdminAppealsPage> createState() => _AdminAppealsPageState();
}

class _AdminAppealsPageState extends State<AdminAppealsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final AccountAppealService _appealService = AccountAppealService();
  String _statusFilter = 'Pending'; // Filter by 'Pending' or 'Closed'

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<AccountAppealModel>>(
              stream: _appealService.getAppealsStream(),
              builder: (context, snapshot) {
                // Debug logging
                print('🔒 Appeals Stream State:');
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
                        Text('Failed to load appeals'),
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

                final appeals = snapshot.data ?? [];
                final pendingAppeals = appeals.where((a) => a.status == 'Pending').toList();
                final closedAppeals = appeals.where((a) => a.status == 'Closed').toList();
                
                // Filter based on selected status
                final filteredAppeals = _statusFilter == 'Pending' ? pendingAppeals : closedAppeals;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _statusFilter = 'Pending';
                              });
                            },
                            child: _buildStatChip(
                              context,
                              icon: Icons.hourglass_bottom_rounded,
                              label: 'Pending',
                              count: pendingAppeals.length,
                              color: Colors.orange,
                              isSelected: _statusFilter == 'Pending',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _statusFilter = 'Closed';
                              });
                            },
                            child: _buildStatChip(
                              context,
                              icon: Icons.done_outline_rounded,
                              label: 'Closed',
                              count: closedAppeals.length,
                              color: Colors.green,
                              isSelected: _statusFilter == 'Closed',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredAppeals.isEmpty
                          ? Center(
                              child: Text(
                                _statusFilter == 'Pending'
                                    ? 'No pending appeals'
                                    : 'No closed appeals',
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: filteredAppeals.length,
                              itemBuilder: (context, i) {
                                final appeal = filteredAppeals[i];
                                return _buildAppealCard(context, appeal);
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

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppealCard(BuildContext context, AccountAppealModel appeal) {
    final reasonDisplay = appeal.reason == 'suspension' ? 'Suspension' : 'Ban';
    
    // Status color: Orange for Pending, Green for active durations, Gray for Closed
    Color statusColor;
    if (appeal.status == 'Pending') {
      statusColor = Colors.orange;
    } else if (appeal.status == 'Closed') {
      statusColor = Colors.green;
    } else if (appeal.status == 'Rejected') {
      statusColor = Colors.red;
    } else {
      // Active durations (1 day, 3 days, etc.) or Lift Ban/Lift Suspension
      statusColor = Colors.green;
    }

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
              builder: (context) => AdminAppealDetailsScreen(appeal: appeal),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title and status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    appeal.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1E1E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appeal.status,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Reason badge and email row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reasonDisplay.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    appeal.userEmail,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.shield_rounded, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  '$reasonDisplay Appeal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
