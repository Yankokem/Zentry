import 'package:flutter/material.dart';
import 'package:zentry/core/core.dart';

/// Widget that protects admin routes by verifying admin access
/// Redirects to home if user is not an admin
class AdminGuard extends StatelessWidget {
  final Widget child;
  final AdminService _adminService = AdminService();

  AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminService.verifyAdminAccess(),
      builder: (context, snapshot) {
        // Show loading while checking admin status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Verifying Access')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Check if user is admin
        final isAdmin = snapshot.data ?? false;

        if (!isAdmin) {
          // Not an admin - show access denied and redirect
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Access Denied: Admin privileges required'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          });

          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('You do not have permission to access this page.'),
                ],
              ),
            ),
          );
        }

        // User is admin - show the protected content
        return child;
      },
    );
  }
}
