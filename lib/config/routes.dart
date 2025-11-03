import 'package:flutter/material.dart';
import 'package:zentry/screens/auth/login_screen.dart';
import 'package:zentry/screens/auth/signup_screen.dart';
import 'package:zentry/screens/home/home_screen.dart';
import 'package:zentry/screens/launch_screen.dart';
import 'package:zentry/screens/profile/profile_screen.dart';

class AppRoutes {
  // Route Names
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';

  // Tasks
  static const String tasks = '/tasks';
  static const String taskDetail = '/task-detail';

  // Journal
  static const String journal = '/journal';
  static const String journalEditor = '/journal-editor';

  // Wishlist
  static const String wishlist = '/wishlist';

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

      case tasks:
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // Replace with TasksScreen()
        );

      case journal:
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // Replace with JournalScreen()
        );

      case wishlist:
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // Replace with WishlistScreen()
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
