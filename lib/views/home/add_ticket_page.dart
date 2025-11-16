import 'package:flutter/material.dart';
import 'package:zentry/models/project_model.dart';
import 'package:zentry/models/ticket_model.dart';
import 'package:zentry/services/project_manager.dart';

class AddTicketPage extends StatefulWidget {
  final Project project;
  final VoidCallback refreshTickets;

  const AddTicketPage({
    super.key,
    required this.project,
    required this.refreshTickets,
  });

  @override
  State<AddTicketPage> createState() => _AddTicketPageState();
}

class _AddTicketPageState extends State<AddTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descController = TextEditingController();
  String selectedPriority = 'medium';
  String selectedStatus = 'todo';
  List<String> selectedAssignees = [];
  DateTime? selectedDeadline;

  @override
  void initState() {
    super.initState();
    selectedAssignees = [widget.project.teamMembers.first];
  }

  Color _getProjectColor() {
    switch (widget.project.color) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _getProjectColor(),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Ticket',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveTicket,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF1E1E1E),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Ticket Title',
                        hintText: 'Enter a clear, descriptive title',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _getProjectColor(), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Provide detailed information about this ticket',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _getProjectColor(), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Configuration Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 20, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Configuration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Priority',
                      value: selectedPriority,
                      items: const [
                        DropdownMenuItem(
                          value: 'low',
                          child: Row(
                            children: [
                              Icon(Icons.arrow_downward, color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text('Low'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Row(
                            children: [
                              Icon(Icons.remove, color: Colors.orange, size: 18),
                              SizedBox(width: 8),
                              Text('Medium'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Row(
                            children: [
                              Icon(Icons.arrow_upward, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('High'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => selectedPriority = value!),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Status',
                      value: selectedStatus,
                      items: const [
                        DropdownMenuItem(
                          value: 'todo',
                          child: Row(
                            children: [
                              Icon(Icons.circle_outlined, color: Colors.grey, size: 18),
                              SizedBox(width: 8),
                              Text('To Do'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Row(
                            children: [
                              Icon(Icons.play_arrow, color: Colors.orange, size: 18),
                              SizedBox(width: 8),
                              Text('In Progress'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'in_review',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, color: Colors.purple, size: 18),
                              SizedBox(width: 8),
                              Text('In Review'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'done',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text('Done'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => selectedStatus = value!),
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildMultiSelectField(),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deadline',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDeadline ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (pickedDate != null) {
              setState(() {
                selectedDeadline = pickedDate;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDeadline != null
                        ? '${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                        : 'Select deadline (optional)',
                    style: TextStyle(
                      color: selectedDeadline != null ? Colors.black : Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _saveTicket() {
    if (_formKey.currentState!.validate()) {
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
        projectId: widget.project.id,
        deadline: selectedDeadline,
      );

      ProjectManager().addTicket(newTicket);
      widget.refreshTickets();
      Navigator.pop(context);

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
  }

  Widget _buildMultiSelectField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign To',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await showDialog<List<String>>(
              context: context,
              builder: (context) => MultiSelectDialog(
                title: 'Select Assignees',
                items: widget.project.teamMembers,
                selectedItems: selectedAssignees,
              ),
            );
            if (result != null) {
              setState(() {
                selectedAssignees = result;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedAssignees.isEmpty
                        ? 'Select assignees'
                        : selectedAssignees.join(', '),
                    style: TextStyle(
                      color: selectedAssignees.isEmpty ? Colors.grey.shade600 : Colors.black,
                      fontSize: 16,
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
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }
}

class MultiSelectDialog extends StatefulWidget {
  final String title;
  final List<String> items;
  final List<String> selectedItems;

  const MultiSelectDialog({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItems,
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
          onPressed: () => Navigator.pop(context, _selectedItems),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
