import 'package:flutter/material.dart';
import 'package:zentry/auth/login_screen.dart';
import 'package:zentry/auth/signup_screen.dart';
import 'package:zentry/views/home/home_screen.dart';
import 'package:zentry/views/admin/admin_dashboard.dart';
import 'package:zentry/views/home/tasks_page.dart';
import 'package:zentry/views/home/journal_page.dart';
import 'package:zentry/views/home/wishlist_page.dart';
import 'package:zentry/views/launch_screen.dart';
import 'package:zentry/views/profile/profile_screen.dart';
import 'package:zentry/views/profile/about_screen.dart';
import 'package:zentry/views/profile/help_support_screen.dart';
import 'package:zentry/views/admin/admin_bug_report_details.dart';
import 'package:zentry/views/admin/admin_account_action.dart';

class AppRoutes {
  // Route Names
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String about = '/about';
  static const String helpSupport = '/help-support';
  static const String adminDashboard = '/admin';

  // Tasks
  static const String tasks = '/tasks';
  static const String taskDetail = '/task-detail';

  // Journal
  static const String journal = '/journal';
  static const String journalEditor = '/journal-editor';

  // Wishlist
  static const String wishlist = '/wishlist';

  // Admin
  static const String adminBugReportDetails = '/admin/bug-report-details';
  static const String adminAccountAction = '/admin/account-action';

  // Route Generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const LaunchScreen(),
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case signup:
        return MaterialPageRoute(
          builder: (_) => const SignupScreen(),
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );

      case about:
        return MaterialPageRoute(
          builder: (_) => const AboutScreen(),
        );

      case helpSupport:
        return MaterialPageRoute(
          builder: (_) => const HelpSupportScreen(),
        );

      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
        );

      case tasks:
        return MaterialPageRoute(
          builder: (_) => const TasksPage(),
        );

      case journal:
        return MaterialPageRoute(
          builder: (_) => const JournalPage(),
        );

      case wishlist:
        return MaterialPageRoute(
          builder: (_) => const WishlistPage(),
        );

      case adminBugReportDetails:
        return MaterialPageRoute(
          builder: (_) => AdminBugReportDetailsPage(report: settings.arguments as Map<String, dynamic>),
        );

      case adminAccountAction:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AdminAccountActionPage(
            user: args['user'] as Map<String, dynamic>,
            action: args['action'] as String,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  // Helper method for navigation with arguments
  static void pushNamed(BuildContext context, String routeName,
      {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  // Helper method for replacing current route
  static void pushReplacementNamed(BuildContext context, String routeName) {
    Navigator.pushReplacementNamed(context, routeName);
  }

  // Helper method for clearing stack and navigating
  static void pushNamedAndRemoveUntil(BuildContext context, String routeName) {
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
  }
}
