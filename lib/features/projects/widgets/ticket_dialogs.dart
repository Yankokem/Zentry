 import 'package:flutter/material.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/projects/projects.dart';

class MultiSelectDialog extends StatefulWidget {
  final String title;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onSelectionChanged;

  const MultiSelectDialog({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItems,
    required this.onSelectionChanged,
  });

  @override
  State<MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<String> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.items.map((item) {
            return CheckboxListTile(
              title: Text(item),
              value: _selectedItems.contains(item),
              onChanged: (bool? checked) {
                setState(() {
                  if (checked == true) {
                    _selectedItems.add(item);
                  } else {
                    _selectedItems.remove(item);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onSelectionChanged(_selectedItems);
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

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
    List<String> selectedAssignees = [];
    DateTime? selectedDeadline;

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
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Deadline',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDeadline ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (pickedDate != null) {
                                    setDialogState(() {
                                      selectedDeadline = pickedDate;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 16),
                                      const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      selectedDeadline != null
                                          ? '${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                                          : 'Select deadline',
                                      style: TextStyle(
                                        color: selectedDeadline != null ? Colors.black : Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                    ],
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
                                'Assign To',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => MultiSelectDialog(
                                      title: 'Assign To',
                                      items: project.acceptedMemberEmails,
                                      selectedItems: selectedAssignees,
                                      onSelectionChanged: (selected) {
                                        setDialogState(() {
                                          selectedAssignees = selected;
                                        });
                                      },
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, color: Colors.grey.shade600, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          selectedAssignees.isNotEmpty
                                              ? selectedAssignees.join(', ')
                                              : 'Select assignees',
                                          style: TextStyle(
                                            color: selectedAssignees.isNotEmpty ? Colors.black : Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                  // Validate all assignees are accepted members
                  final pendingAssignees = selectedAssignees
                      .where((email) => !project.acceptedMemberEmails.contains(email))
                      .toList();
                  
                  if (pendingAssignees.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cannot assign to pending members: ${pendingAssignees.join(", ")}',
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    return;
                  }

                  // Generate ticket number
                  final ticketNumber = 'TICK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

                  final newTicket = Ticket(
                    ticketNumber: ticketNumber,
                    userId: '', // This will be set by ProjectManager
                    title: titleController.text,
                    description: descController.text,
                    priority: selectedPriority,
                    status: selectedStatus,
                    assignedTo: selectedAssignees,
                    projectId: project.id,
                    deadline: selectedDeadline,
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
    Project project,
    VoidCallback refreshTickets,
  ) {
    final titleController = TextEditingController(text: ticket.title);
    final descController = TextEditingController(text: ticket.description);
    String selectedPriority = ticket.priority;
    String selectedStatus = ticket.status;
    List<String> selectedAssignees = ticket.assignedTo;
    DateTime? selectedDeadline = ticket.deadline;

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
                  children: [
                    Icon(Icons.edit, color: _getProjectColorFromTicket(ticket), size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Edit Ticket',
                        style: TextStyle(
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
                            'Deadline',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDeadline ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (pickedDate != null) {
                                setDialogState(() {
                                  selectedDeadline = pickedDate;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedDeadline != null
                                        ? '${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                                        : 'Select deadline',
                                    style: TextStyle(
                                      color: selectedDeadline != null ? Colors.black : Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
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
                            'Assign To',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => MultiSelectDialog(
                                  title: 'Assign To',
                                  items: project.acceptedMemberEmails,
                                  selectedItems: selectedAssignees,
                                  onSelectionChanged: (selected) {
                                    setDialogState(() {
                                      selectedAssignees = selected;
                                    });
                                  },
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: Colors.grey.shade600, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedAssignees.isNotEmpty
                                          ? selectedAssignees.join(', ')
                                          : 'Select assignees',
                                      style: TextStyle(
                                        color: selectedAssignees.isNotEmpty ? Colors.black : Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                ],
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
                  // Validate all assignees are accepted members
                  final pendingAssignees = selectedAssignees
                      .where((email) => !project.acceptedMemberEmails.contains(email))
                      .toList();
                  
                  if (pendingAssignees.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cannot assign to pending members: ${pendingAssignees.join(", ")}',
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    return;
                  }

                  final updatedTicket = ticket.copyWith(
                    title: titleController.text,
                    description: descController.text,
                    priority: selectedPriority,
                    status: selectedStatus,
                    assignedTo: selectedAssignees,
                    deadline: selectedDeadline,
                  );

                  ProjectManager().updateTicket(ticket.projectId, ticket.ticketNumber, updatedTicket);
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
