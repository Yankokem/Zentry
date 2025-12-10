import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:zentry/core/core.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _adminService.getUserStatistics(widget.userId);
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        centerTitle: true,
        actions: [
          if (_userData != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) => _handleAction(value),
              itemBuilder: (context) => [
                if (_userData!['status'] == 'active') ...[
                  const PopupMenuItem(
                    value: 'suspend',
                    child: Row(
                      children: [
                        Icon(Icons.pause_circle_outline,
                            color: Colors.orange, size: 20),
                        SizedBox(width: 12),
                        Text('Suspend User'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'ban',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text('Ban User'),
                      ],
                    ),
                  ),
                ],
                if (_userData!['status'] == 'suspended') ...[
                  const PopupMenuItem(
                    value: 'activate',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.green, size: 20),
                        SizedBox(width: 12),
                        Text('Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'ban',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text('Ban User'),
                      ],
                    ),
                  ),
                ],
                if (_userData!['status'] == 'banned')
                  const PopupMenuItem(
                    value: 'activate',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.green, size: 20),
                        SizedBox(width: 12),
                        Text('Activate'),
                      ],
                    ),
                  ),
                if (_userData!['role'] == 'member')
                  const PopupMenuItem(
                    value: 'promote',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward, color: Colors.blue, size: 20),
                        SizedBox(width: 12),
                        Text('Promote to Admin'),
                      ],
                    ),
                  )
                else if (_userData!['role'] == 'admin')
                  const PopupMenuItem(
                    value: 'demote',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward,
                            color: Colors.grey, size: 20),
                        SizedBox(width: 12),
                        Text('Demote to Member'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading user data',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _userData == null
                  ? const Center(child: Text('User not found'))
                  : RefreshIndicator(
                      onRefresh: _loadUserData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Profile Card
                            _buildProfileCard(),
                            const SizedBox(height: 24),

                            // Statistics Cards
                            Text(
                              'Activity Statistics',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildStatisticsGrid(),
                            const SizedBox(height: 24),

                            // Account Information
                            Text(
                              'Account Information',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildAccountInfoCard(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildProfileCard() {
    final name = _userData!['name'] ?? 'Unknown User';
    final email = _userData!['email'] ?? '';
    final role = _userData!['role'] ?? 'member';
    final status = _userData!['status'] ?? 'active';
    final profileImageUrl = _userData!['profileImageUrl'];
    final initials =
        name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join();

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          // Profile Image
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFF9ED69),
                      const Color(0xFFF9ED69).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: profileImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          profileImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Color(0xFF1E1E1E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFF1E1E1E),
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                          ),
                        ),
                      ),
              ),
              // Status Indicator
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name and Role
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              if (role == 'admin') ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9ED69),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor(status).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 16,
                  color: _getStatusColor(status),
                ),
                const SizedBox(width: 8),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
              ],
            ),
          ),

          // Suspension/Ban Info
          if (status == 'suspended' &&
              _userData!['suspensionReason'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suspension Reason:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData!['suspensionReason'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  if (_userData!['suspensionDuration'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Duration: ${_userData!['suspensionDuration']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (status == 'banned' && _userData!['banReason'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ban Reason:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData!['banReason'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Journal Entries',
          _userData!['journalCount'].toString(),
          Icons.book_outlined,
          Colors.blue,
        ),
        _buildStatCard(
          'Projects',
          '${_userData!['projects']}',
          Icons.folder_outlined,
          Colors.purple,
        ),
        _buildStatCard(
          'Tickets',
          _userData!['tickets'].toString(),
          Icons.assignment_outlined,
          Colors.orange,
        ),
        _buildStatCard(
          'Wishlists',
          _userData!['wishlists'].toString(),
          Icons.star_outline,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    final createdAt = _userData!['createdAt'];
    final lastActive = _userData!['lastActiveFormatted'] ?? 'Never';
    final phoneNumber = _userData!['phoneNumber'] ?? 'Not provided';
    final country = _userData!['country'] ?? 'Not provided';

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          _buildInfoRow(
              Icons.calendar_today,
              'Member Since',
              createdAt != null
                  ? DateFormat('MMM d, yyyy').format(createdAt)
                  : 'Unknown'),
          const Divider(height: 24),
          _buildInfoRow(Icons.access_time, 'Last Active', lastActive),
          const Divider(height: 24),
          _buildInfoRow(Icons.phone, 'Phone Number', phoneNumber),
          const Divider(height: 24),
          _buildInfoRow(Icons.public, 'Country', country),
          const Divider(height: 24),
          _buildInfoRow(Icons.folder_shared, 'Shared Projects',
              '${_userData!['sharedProjects']}'),
          const Divider(height: 24),
          _buildInfoRow(Icons.star_half, 'Shared Wishlists',
              '${_userData!['sharedWishlists']}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9ED69).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF1E1E1E)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'banned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'suspended':
        return Icons.pause_circle;
      case 'banned':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  void _handleAction(String action) {
    switch (action) {
      case 'suspend':
      case 'ban':
        Navigator.pushNamed(
          context,
          '/admin/account-action',
          arguments: {'user': _userData, 'action': action},
        ).then((_) => _loadUserData());
        break;
      case 'activate':
        _showActivateConfirmation();
        break;
      case 'promote':
        _showRoleChangeConfirmation('admin');
        break;
      case 'demote':
        _showRoleChangeConfirmation('member');
        break;
    }
  }

  void _showActivateConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Activate User'),
        content:
            Text('Are you sure you want to activate ${_userData!['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _adminService.updateUserStatus(
                  userId: widget.userId,
                  status: 'active',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('User activated successfully')),
                  );
                  _loadUserData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  void _showRoleChangeConfirmation(String newRole) {
    final action = newRole == 'admin' ? 'promote' : 'demote';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${action == 'promote' ? 'Promote' : 'Demote'} User'),
        content: Text(
            'Are you sure you want to $action ${_userData!['name']} to ${newRole == 'admin' ? 'admin' : 'member'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _adminService.updateUserRole(
                  userId: widget.userId,
                  role: newRole,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'User ${action == 'promote' ? 'promoted' : 'demoted'} successfully')),
                  );
                  _loadUserData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(action == 'promote' ? 'Promote' : 'Demote'),
          ),
        ],
      ),
    );
  }
}
