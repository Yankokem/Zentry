import 'package:flutter/material.dart';
import 'package:zentry/config/constants.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String time;
  final String priority;
  final String? assignedTo;
  final bool isDone;

  const TaskCard({
    super.key,
    required this.title,
    required this.time,
    required this.priority,
    required this.assignedTo,
    required this.isDone,
  });

  Color _getPriorityColor() {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPriorityColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDone
                  ? Colors.green.withOpacity(0.1)
                  : _getPriorityColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDone ? Icons.check_circle : Icons.circle_outlined,
              color: isDone ? Colors.green : _getPriorityColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (assignedTo != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        assignedTo!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getPriorityColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              priority.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getPriorityColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}