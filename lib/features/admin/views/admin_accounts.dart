import 'package:flutter/material.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/admin/admin.dart';
import 'package:zentry/features/admin/widgets/skeleton_loader.dart';

class AdminAccountsPage extends StatefulWidget {
  const AdminAccountsPage({super.key});

  @override
  State<AdminAccountsPage> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends State<AdminAccountsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedFilter = 'active'; // active, suspended, banned
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _adminService.getAllUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
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

  List<Map<String, dynamic>> _getFilteredUsers() {
    final searchQuery = _searchController.text.toLowerCase();
    
    return _allUsers.where((user) {
      // Filter by status
      final status = (user['status'] ?? 'active').toString().toLowerCase();
      if (status != _selectedFilter) return false;
      
      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery) || email.contains(searchQuery);
      }
      
      return true;
    }).toList();
  }

  @override
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLoader(width: 200, height: 28, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 20),
            SkeletonLoader(width: double.infinity, height: 50, borderRadius: BorderRadius.circular(8)),
            const SizedBox(height: 16),
            SkeletonLoader(width: double.infinity, height: 48, borderRadius: BorderRadius.circular(8)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 6,
                itemBuilder: (context, index) => const SkeletonListItem(),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading users',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF9ED69).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_allUsers.length} users',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Filter Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildFilterTab('active', 'Active'),
                  _buildFilterTab('suspended', 'Suspended'),
                  _buildFilterTab('banned', 'Banned'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: Builder(
                builder: (context) {
                  final filteredUsers = _getFilteredUsers();
                
                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'No users found'
                                : 'No $_selectedFilter users',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, i) {
                      final u = filteredUsers[i];
                      final name = (u['name'] ?? '').toString();
                      final initials = name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join();
                      final role = (u['role'] ?? '').toString();
                      final status = (u['status'] ?? 'active').toString().toLowerCase();
                      final isAdmin = role == 'admin';
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailScreen(userId: u['id']),
                            ),
                          ).then((_) => _loadUsers());
                        },
                        child: Container(
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
                          child: Row(
                            children: [
                              Stack(
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
                                        initials,
                                        style: const TextStyle(
                                          color: Color(0xFF1E1E1E),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Status Indicator
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E1E1E),
                                            ),
                                          ),
                                        ),
                                        if (isAdmin)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Last active: ${u['lastActive']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildActionButtons(u, isAdmin, status),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String value, String label) {
    final isSelected = _selectedFilter == value;
    Color statusColor;
    
    switch (value) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'suspended':
        statusColor = Colors.orange;
        break;
      case 'banned':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? statusColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
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

  Widget _buildActionButtons(Map<String, dynamic> user, bool isAdmin, String status) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[700]),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        _handleUserAction(user, value);
      },
      itemBuilder: (context) => [
        if (status == 'active')
          const PopupMenuItem(
            value: 'suspend',
            child: Row(
              children: [
                Icon(Icons.pause_circle_outline, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Text('Suspend'),
              ],
            ),
          ),
        if (status == 'active')
          const PopupMenuItem(
            value: 'ban',
            child: Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 20),
                SizedBox(width: 12),
                Text('Ban'),
              ],
            ),
          ),
        if (status == 'suspended')
          const PopupMenuItem(
            value: 'activate',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                SizedBox(width: 12),
                Text('Activate'),
              ],
            ),
          ),
        if (status == 'suspended')
          const PopupMenuItem(
            value: 'ban',
            child: Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 20),
                SizedBox(width: 12),
                Text('Ban'),
              ],
            ),
          ),
        if (status == 'banned')
          const PopupMenuItem(
            value: 'activate',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                SizedBox(width: 12),
                Text('Activate'),
              ],
            ),
          ),
      ],
    );
  }

  void _handleUserAction(Map<String, dynamic> user, String action) {
    switch (action) {
      case 'suspend':
      case 'ban':
        Navigator.pushNamed(
          context,
          '/admin/account-action',
          arguments: {'user': user, 'action': action},
        ).then((_) => _loadUsers());
        break;
      case 'activate':
        _showActivateConfirmation(user);
        break;
    }
  }



  void _showActivateConfirmation(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Activate User',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to activate ${user['name']}?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await _adminService.updateUserStatus(
                            userId: user['id'],
                            status: 'active',
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${user['name']} has been activated'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadUsers();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error activating user: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Activate',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}