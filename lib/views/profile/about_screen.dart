import 'package:flutter/material.dart';
import 'package:zentry/config/constants.dart';
import 'package:zentry/config/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9ED69),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // App Icon Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'App Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // App Icon Display
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.book_outlined,
                    size: 40,
                    color: Color(0xFF1E1E1E),
                  ),
                ),

                const SizedBox(height: 16),

                // App Name
                Text(
                  'Zentry',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                ),

                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Your life, organized.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),

                const SizedBox(height: 8),

                // Version
                Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Description Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'About Zentry',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Zentry is your personal productivity companion designed to help you organize your life, track your tasks, journal your thoughts, and manage your wishes. With a clean and intuitive interface, Zentry makes it easy to stay on top of your goals and maintain a balanced lifestyle.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E1E1E),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Features Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Features',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFeatureItem('Task Management', 'Create, edit, and track your daily tasks'),
                _buildFeatureItem('Journaling', 'Write and organize your thoughts and experiences'),
                _buildFeatureItem('Wish Lists', 'Keep track of your aspirations and goals'),
                _buildFeatureItem('Project Management', 'Organize complex projects with tickets and roles'),
                _buildFeatureItem('Dark Mode', 'Switch between light and dark themes'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Developer Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.code, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Developer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Built with ❤️ by the Zentry Team',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'For support or feedback, please contact us at support@zentry.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
