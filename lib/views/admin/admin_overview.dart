import 'package:flutter/material.dart';

class AdminOverviewPage extends StatelessWidget {
  const AdminOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    final Map<String, int> counts = {
      'Users': 124,
      'Projects': 42,
      'Tickets': 18,
      'Journal Entries': 276,
      'Wishlists': 39,
      'Bug Reports': 0,
    };
    final items = counts.entries.toList();

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 20, 
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Dashboard Overview',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E1E1E),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Monitor your platform statistics',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Cards Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 900 
                          ? 5 
                          : constraints.maxWidth > 600 
                              ? 3 
                              : 2;
                      
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final entry = items[index];
                          return _buildStatCard(context, entry.key, entry.value);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, int count) {
    final icons = {
      'Users': Icons.people_rounded,
      'Projects': Icons.folder_rounded,
      'Tickets': Icons.confirmation_number_rounded,
      'Journal Entries': Icons.book_rounded,
      'Wishlists': Icons.star_rounded,
      'Bug Reports': Icons.bug_report,
    };

    final accentColors = {
      'Users': const Color(0xFF667EEA),
      'Projects': const Color(0xFFF093FB),
      'Tickets': const Color(0xFF4FACFE),
      'Journal Entries': const Color(0xFF43E97B),
      'Wishlists': const Color(0xFFFA709A),
      'Bug Reports': const Color(0xFFFF9A9E),
    };

    final accentColor = accentColors[label] ?? Colors.grey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Handle card tap - navigate to specific page based on label
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigating to $label'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              top: BorderSide(
                color: accentColor,
                width: 4,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icons[label] ?? Icons.analytics_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}