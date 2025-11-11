import 'package:flutter/material.dart';
import 'package:zentry/models/project_model.dart';
import 'package:zentry/models/ticket_model.dart';
import 'package:zentry/services/project_manager.dart';

class TicketDialogs {
  static void showAddTicketDialog(
    BuildContext context,
    Project project,
    VoidCallback refreshTickets,
  ) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'medium';
    String selectedStatus = 'todo';
    String selectedAssignee = project.teamMembers.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.add_circle, color: _getProjectColor(project), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Add New Ticket',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Ticket Title',
                          hintText: 'Enter a clear, descriptive title',
                          labelStyle: TextStyle(color: Colors.grey.shade600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _getProjectColor(project), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: titleController.text.isEmpty
                              ? const Icon(Icons.error_outline, color: Colors.red, size: 20)
                              : const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Provide detailed information about this ticket',
                          labelStyle: TextStyle(color: Colors.grey.shade600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _getProjectColor(project), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Configuration Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings_outlined, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Configuration',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Priority',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedPriority,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'low',
                                        child: Row(
                                          children: [
                                            Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                                            SizedBox(width: 8),
                                            Text('Low'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'medium',
                                        child: Row(
                                          children: [
                                            Icon(Icons.remove, color: Colors.orange, size: 16),
                                            SizedBox(width: 8),
                                            Text('Medium'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'high',
                                        child: Row(
                                          children: [
                                            Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                                            SizedBox(width: 8),
                                            Text('High'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedPriority = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedStatus,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'todo',
                                        child: Row(
                                          children: [
                                            Icon(Icons.circle_outlined, color: Colors.grey, size: 16),
                                            SizedBox(width: 8),
                                            Text('To Do'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'in_progress',
                                        child: Row(
                                          children: [
                                            Icon(Icons.play_arrow, color: Colors.orange, size: 16),
                                            SizedBox(width: 8),
                                            Text('In Progress'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'in_review',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility, color: Colors.purple, size: 16),
                                            SizedBox(width: 8),
                                            Text('In Review'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'done',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                                            SizedBox(width: 8),
                                            Text('Done'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedStatus = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign To',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedAssignee,
                                isExpanded: true,
                                items: project.teamMembers
                                    .map((member) => DropdownMenuItem(
                                          value: member,
                                          child: Row(
                                            children: [
                                              Icon(Icons.person, color: Colors.grey.shade600, size: 16),
                                              const SizedBox(width: 8),
                                              Text(member),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedAssignee = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    descController.text.isNotEmpty) {
                  // Generate ticket number
                  final ticketNumber = 'TICK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

                  final newTicket = Ticket(
                    ticketNumber: ticketNumber,
                    title: titleController.text,
                    description: descController.text,
                    priority: selectedPriority,
                    status: selectedStatus,
                    assignedTo: selectedAssignee,
                    projectId: project.id,
                  );

                  ProjectManager().addTicket(newTicket);
                  Navigator.pop(context);
                  refreshTickets();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ticket $ticketNumber created'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getProjectColor(project),
                foregroundColor: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Add Ticket',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showEditTicketDialog(
    BuildContext context,
    Ticket ticket,
    List<String> teamMembers,
    VoidCallback refreshTickets,
  ) {
    final titleController = TextEditingController(text: ticket.title);
    final descController = TextEditingController(text: ticket.description);
    String selectedPriority = ticket.priority;
    String selectedStatus = ticket.status;
    String selectedAssignee = ticket.assignedTo;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: _getProjectColorFromTicket(ticket), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Edit Ticket',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.ticketNumber,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Ticket Title',
                          hintText: 'Enter a clear, descriptive title',
                          labelStyle: TextStyle(color: Colors.grey.shade600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _getProjectColorFromTicket(ticket), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: titleController.text.isNotEmpty
                              ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Provide detailed information about this ticket',
                          labelStyle: TextStyle(color: Colors.grey.shade600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _getProjectColorFromTicket(ticket), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Configuration Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings_outlined, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Configuration',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Priority',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedPriority,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'low',
                                        child: Row(
                                          children: [
                                            Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                                            SizedBox(width: 8),
                                            Text('Low'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'medium',
                                        child: Row(
                                          children: [
                                            Icon(Icons.remove, color: Colors.orange, size: 16),
                                            SizedBox(width: 8),
                                            Text('Medium'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'high',
                                        child: Row(
                                          children: [
                                            Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                                            SizedBox(width: 8),
                                            Text('High'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedPriority = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedStatus,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'todo',
                                        child: Row(
                                          children: [
                                            Icon(Icons.circle_outlined, color: Colors.grey, size: 16),
                                            SizedBox(width: 8),
                                            Text('To Do'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'in_progress',
                                        child: Row(
                                          children: [
                                            Icon(Icons.play_arrow, color: Colors.orange, size: 16),
                                            SizedBox(width: 8),
                                            Text('In Progress'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'in_review',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility, color: Colors.purple, size: 16),
                                            SizedBox(width: 8),
                                            Text('In Review'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'done',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                                            SizedBox(width: 8),
                                            Text('Done'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedStatus = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign To',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedAssignee,
                                isExpanded: true,
                                items: teamMembers
                                    .map((member) => DropdownMenuItem(
                                          value: member,
                                          child: Row(
                                            children: [
                                              Icon(Icons.person, color: Colors.grey.shade600, size: 16),
                                              const SizedBox(width: 8),
                                              Text(member),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedAssignee = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    descController.text.isNotEmpty) {
                  final updatedTicket = ticket.copyWith(
                    title: titleController.text,
                    description: descController.text,
                    priority: selectedPriority,
                    status: selectedStatus,
                    assignedTo: selectedAssignee,
                  );

                  ProjectManager().updateTicket(ticket.ticketNumber, updatedTicket);
                  Navigator.pop(context);
                  refreshTickets();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Ticket updated successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getProjectColorFromTicket(ticket),
                foregroundColor: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _getProjectColor(Project project) {
    switch (project.color) {
      case 'yellow':
        return const Color(0xFFF9ED69);
      case 'blue':
        return Colors.blue.shade300;
      case 'green':
        return Colors.green.shade300;
      case 'purple':
        return Colors.purple.shade300;
      case 'red':
        return Colors.red.shade300;
      default:
        return const Color(0xFFF9ED69);
    }
  }

  static Color _getProjectColorFromTicket(Ticket ticket) {
    // This is a placeholder - in a real app, you'd get the project color from the project
    // For now, return default yellow
    return const Color(0xFFF9ED69);
  }
}
