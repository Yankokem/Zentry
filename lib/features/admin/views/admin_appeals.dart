import 'package:flutter/material.dart';

import 'package:zentry/features/admin/admin.dart';

class AdminAppealsPage extends StatelessWidget {
  const AdminAppealsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appealService = AccountAppealService();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Appeals',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E1E1E),
                ),
          ),
          const SizedBox(height: 16),
          
          // Stats Row
          StreamBuilder<List<AccountAppealModel>>(
            stream: appealService.getAppealsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final appeals = snapshot.data ?? [];
              final pendingAppeals = appeals.where((a) => a.status == 'Pending').length;
              final resolvedAppeals = appeals.where((a) => a.status != 'Pending').length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatChip(
                          context,
                          icon: Icons.hourglass_bottom_rounded,
                          label: 'Pending',
                          count: pendingAppeals,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatChip(
                          context,
                          icon: Icons.check_circle_outlined,
                          label: 'Resolved',
                          count: resolvedAppeals,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: appeals.length,
                      itemBuilder: (context, i) {
                        final appeal = appeals[i];
                        return _buildAppealCard(context, appeal);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppealCard(BuildContext context, AccountAppealModel appeal) {
    final reasonDisplay = appeal.reason == 'suspension' ? 'Suspension' : 'Ban';
    final statusColor = appeal.status == 'Pending' ? Colors.orange : 
                        appeal.status == 'Approved' ? Colors.green :
                        Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.security_rounded,
            color: statusColor,
          ),
        ),
        title: Text(
          appeal.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '$reasonDisplay Appeal • ${appeal.userEmail}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 6),
            Chip(
              label: Text(
                appeal.status,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
              backgroundColor: statusColor.withOpacity(0.1),
              labelStyle: TextStyle(color: statusColor),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          // Navigate to appeal details
        },
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
        ],
      ),
    );
  }
}
