import 'package:flutter/material.dart';
import 'package:zentry/models/project_model.dart';
import 'package:zentry/models/ticket_model.dart';
import 'package:zentry/services/project_manager.dart';

class EditTicketPage extends StatefulWidget {
  final Ticket ticket;
  final Project project;
  final VoidCallback refreshTickets;

  const EditTicketPage({
    super.key,
    required this.ticket,
    required this.project,
    required this.refreshTickets,
  });

  @override
  State<EditTicketPage> createState() => _EditTicketPageState();
}

class _EditTicketPageState extends State<EditTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descController = TextEditingController();
  String selectedPriority = '';
  String selectedStatus = '';
  String selectedAssignee = '';
  DateTime? selectedDeadline;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.ticket.title;
    descController.text = widget.ticket.description;
    selectedPriority = widget.ticket.priority;
    selectedStatus = widget.ticket.status;
    selectedAssignee = widget.ticket.assignedTo;
    selectedDeadline = widget.ticket.deadline;
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
          'Edit Ticket',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveChanges,
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
              // Ticket Number Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.tag, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      widget.ticket.ticketNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

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
                    _buildDropdownField(
                      label: 'Assign To',
                      value: selectedAssignee,
                      items: widget.project.teamMembers
                          .map((member) => DropdownMenuItem(
                                value: member,
                                child: Row(
                                  children: [
                                    Icon(Icons.person, color: Colors.grey.shade600, size: 18),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        member,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => selectedAssignee = value!),
                    ),
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

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedTicket = widget.ticket.copyWith(
        title: titleController.text,
        description: descController.text,
        priority: selectedPriority,
        status: selectedStatus,
        assignedTo: selectedAssignee,
        deadline: selectedDeadline,
      );

      ProjectManager().updateTicket(widget.ticket.ticketNumber, updatedTicket);
      widget.refreshTickets();
      Navigator.pop(context);

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
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }
}
