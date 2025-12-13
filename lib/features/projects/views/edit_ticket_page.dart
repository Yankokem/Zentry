import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/core/services/firebase/notification_manager.dart';
import 'package:zentry/features/journal/widgets/rich_text_editor.dart';
import 'package:zentry/features/projects/projects.dart';

class MultiSelectDialog extends StatefulWidget {
  final String title;
  final List<String> items;
  final List<String> selectedItems;
  final Project project;

  const MultiSelectDialog({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItems,
    required this.project,
  });

  @override
  State<MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<String> _selectedItems;
  final UserService _userService = UserService();
  late Map<String, Map<String, String>> _userDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      _userDetails = await _userService.getUsersDetailsByEmails(widget.items);
    } catch (e) {
      _userDetails = {};
    }
    setState(() {
      _isLoading = false;
    });
  }

  String _getDisplayName(String email) {
    final details = _userDetails[email] ?? {};
    return _userService.getDisplayName(details, email);
  }

  String _getProfilePictureUrl(String email) {
    return _userDetails[email]?['profilePictureUrl'] ?? '';
  }

  Widget _buildAvatar(String email) {
    final url = _getProfilePictureUrl(email);
    final displayName = _getDisplayName(email);
    final firstLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : email[0].toUpperCase();

    if (url.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(url),
      );
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.blue.shade300,
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AlertDialog(
        title: Text(widget.title),
        content: const SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Build role-based list
    final rolesList = <Widget>[];

    for (final role in widget.project.roles) {
      final roleMembers =
          role.members.where((email) => widget.items.contains(email)).toList();

      if (roleMembers.isNotEmpty) {
        // Role header with checkbox
        final allRoleSelected =
            roleMembers.every((email) => _selectedItems.contains(email));

        rolesList.add(
          Theme(
            data: Theme.of(context).copyWith(
              expansionTileTheme: ExpansionTileThemeData(
                backgroundColor: Colors.grey.shade50,
                collapsedBackgroundColor: Colors.transparent,
              ),
            ),
            child: ExpansionTile(
              leading: Checkbox(
                value: allRoleSelected,
                tristate: true,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      for (final email in roleMembers) {
                        if (!_selectedItems.contains(email)) {
                          _selectedItems.add(email);
                        }
                      }
                    } else {
                      for (final email in roleMembers) {
                        _selectedItems.remove(email);
                      }
                    }
                  });
                },
              ),
              title: Text(
                role.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${roleMembers.length} member${roleMembers.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12),
              ),
              children: roleMembers.map((email) {
                final isSelected = _selectedItems.contains(email);
                return Container(
                  color: Colors.grey.shade50,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedItems.add(email);
                              } else {
                                _selectedItems.remove(email);
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildAvatar(email),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDisplayName(email),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }
    }

    // Add "Other Members" section for users not in any role
    final unassignedMembers = widget.items
        .where((email) =>
            !widget.project.roles.any((role) => role.members.contains(email)))
        .toList();

    if (unassignedMembers.isNotEmpty) {
      rolesList.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Other Members',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      );

      for (final email in unassignedMembers) {
        final isSelected = _selectedItems.contains(email);
        rolesList.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (bool? checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedItems.add(email);
                      } else {
                        _selectedItems.remove(email);
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildAvatar(email),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDisplayName(email),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: rolesList,
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
  final _descriptionController = RichTextEditorController();
  final _cloudinaryService = CloudinaryService();
  
  String selectedPriority = '';
  String selectedStatus = '';
  List<String> selectedAssignees = [];
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  DateTime? selectedDeadline;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.ticket.title;
    // Load rich description into editor
    if (widget.ticket.richDescription != null && widget.ticket.richDescription!.isNotEmpty) {
      _descriptionController.setJsonContent(widget.ticket.richDescription!);
    } else {
      _descriptionController.setPlainText(widget.ticket.description);
    }
    selectedPriority = widget.ticket.priority;
    selectedStatus = widget.ticket.status;
    selectedAssignees = widget.ticket.assignedTo;
    selectedDeadline = widget.ticket.deadline;
    _uploadedImageUrls = List.from(widget.ticket.imageUrls);
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
                        Icon(Icons.info_outline,
                            size: 20, color: Colors.grey.shade600),
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
                          borderSide:
                              BorderSide(color: _getProjectColor(), width: 2),
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
                    // Image Attachment Section
                    Text(
                      'Images',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedImages.isNotEmpty || _uploadedImageUrls.isNotEmpty)
                      Column(
                        children: [
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length + _uploadedImageUrls.length,
                              itemBuilder: (context, index) {
                                final bool isNewImage = index < _selectedImages.length;
                                return Stack(
                                  children: [
                                    Container(
                                      width: 150,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: isNewImage
                                            ? Image.file(
                                                _selectedImages[index],
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                _uploadedImageUrls[index - _selectedImages.length],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey.shade300,
                                                    child: const Icon(Icons.broken_image),
                                                  );
                                                },
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 16,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isNewImage) {
                                              _selectedImages.removeAt(index);
                                            } else {
                                              _uploadedImageUrls.removeAt(index - _selectedImages.length);
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add images',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichTextEditor(
                      controller: _descriptionController,
                      hintText: 'Describe the ticket requirements and details...',
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
                        Icon(Icons.settings_outlined,
                            size: 20, color: Colors.grey.shade600),
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
                              Icon(Icons.arrow_downward,
                                  color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text('Low'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Row(
                            children: [
                              Icon(Icons.remove,
                                  color: Colors.orange, size: 18),
                              SizedBox(width: 8),
                              Text('Medium'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Row(
                            children: [
                              Icon(Icons.arrow_upward,
                                  color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('High'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => selectedPriority = value!),
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
                              Icon(Icons.circle_outlined,
                                  color: Colors.grey, size: 18),
                              SizedBox(width: 8),
                              Text('To Do'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Row(
                            children: [
                              Icon(Icons.play_arrow,
                                  color: Colors.orange, size: 18),
                              SizedBox(width: 8),
                              Text('In Progress'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'in_review',
                          child: Row(
                            children: [
                              Icon(Icons.visibility,
                                  color: Colors.purple, size: 18),
                              SizedBox(width: 8),
                              Text('In Review'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'done',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text('Done'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => selectedStatus = value!),
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
                Icon(Icons.calendar_today,
                    color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDeadline != null
                        ? '${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                        : 'Select deadline',
                    style: TextStyle(
                      color: selectedDeadline != null
                          ? Colors.black
                          : Colors.grey.shade600,
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
        _AssigneeSelector(
          project: widget.project,
          selectedAssignees: selectedAssignees,
          onSelectionChanged: (selected) {
            setState(() {
              selectedAssignees = selected;
            });
          },
        ),
      ],
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      if (selectedDeadline == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a deadline for the ticket'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Track assignee changes
      final oldAssignees = widget.ticket.assignedTo.toSet();
      final newAssignees = selectedAssignees.toSet();
      final addedAssignees = newAssignees.difference(oldAssignees);
      final removedAssignees = oldAssignees.difference(newAssignees);

      // Track status change
      final statusChanged = widget.ticket.status != selectedStatus;

      // Upload images if selected
      List<String> imageUrls = List.from(_uploadedImageUrls);
      if (_selectedImages.isNotEmpty) {
        imageUrls.addAll(await _uploadTicketImages());
      }

      final updatedTicket = widget.ticket.copyWith(
        title: titleController.text,
        description: _descriptionController.getJsonContent(),
        richDescription: _descriptionController.getJsonContent(),
        imageUrls: imageUrls,
        priority: selectedPriority,
        status: selectedStatus,
        assignedTo: selectedAssignees,
        deadline: selectedDeadline,
      );

      ProjectManager().updateTicket(
          widget.ticket.projectId, widget.ticket.ticketNumber, updatedTicket);
      widget.refreshTickets();

      // Send notifications for newly assigned members
      if (addedAssignees.isNotEmpty) {
        try {
          final firestoreService = FirestoreService();
          final currentUserData =
              await firestoreService.getUserData(currentUser.uid);
          final currentUserName =
              currentUserData?['firstName'] ?? currentUser.email ?? 'Someone';
          final project =
              await firestoreService.getProjectById(widget.ticket.projectId);

          for (final assigneeEmail in addedAssignees) {
            if (assigneeEmail != currentUser.email) {
              final assigneeDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: assigneeEmail)
                  .limit(1)
                  .get();

              if (assigneeDoc.docs.isNotEmpty) {
                final assigneeId = assigneeDoc.docs.first.id;
                await NotificationManager().notifyTaskAssigned(
                  recipientUserId: assigneeId,
                  taskTitle: titleController.text,
                  projectTitle: project?.title ?? 'Unknown Project',
                  taskId: widget.ticket.ticketNumber,
                  projectId: widget.ticket.projectId,
                  assignerName: currentUserName,
                );
              }
            }
          }
        } catch (e) {
          print('Error sending task assignment notifications: \$e');
        }
      }

      // Send notifications for unassigned members
      if (removedAssignees.isNotEmpty) {
        try {
          final firestoreService = FirestoreService();
          final currentUserData =
              await firestoreService.getUserData(currentUser.uid);
          final currentUserName =
              currentUserData?['firstName'] ?? currentUser.email ?? 'Someone';
          final project =
              await firestoreService.getProjectById(widget.ticket.projectId);

          for (final assigneeEmail in removedAssignees) {
            if (assigneeEmail != currentUser.email) {
              final assigneeDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: assigneeEmail)
                  .limit(1)
                  .get();

              if (assigneeDoc.docs.isNotEmpty) {
                final assigneeId = assigneeDoc.docs.first.id;
                await NotificationManager().notifyTaskUnassigned(
                  recipientUserId: assigneeId,
                  taskTitle: widget.ticket.title,
                  projectTitle: project?.title ?? 'Unknown Project',
                  taskId: widget.ticket.ticketNumber,
                  projectId: widget.ticket.projectId,
                  unassignerName: currentUserName,
                );
              }
            }
          }
        } catch (e) {
          print('Error sending task unassignment notifications: \$e');
        }
      }

      // Send notifications for status change to all assignees (except the person who made the change)
      if (statusChanged) {
        try {
          final firestoreService = FirestoreService();
          final currentUserData =
              await firestoreService.getUserData(currentUser.uid);
          final currentUserName =
              currentUserData?['firstName'] ?? currentUser.email ?? 'Someone';
          final project =
              await firestoreService.getProjectById(widget.ticket.projectId);

          for (final assigneeEmail in selectedAssignees) {
            if (assigneeEmail != currentUser.email) {
              final assigneeDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: assigneeEmail)
                  .limit(1)
                  .get();

              if (assigneeDoc.docs.isNotEmpty) {
                final assigneeId = assigneeDoc.docs.first.id;
                await NotificationManager().notifyTaskStatusChanged(
                  recipientUserId: assigneeId,
                  taskTitle: titleController.text,
                  projectTitle: project?.title ?? 'Unknown Project',
                  newStatus: selectedStatus,
                  taskId: widget.ticket.ticketNumber,
                  projectId: widget.ticket.projectId,
                  changedByName: currentUserName,
                );
              }
            }
          }

          // Check for project milestones after ticket update
          if (project != null && project.totalTickets > 0) {
            final newCompletedCount = selectedStatus == 'done'
                ? project.completedTickets + 1
                : project.completedTickets;
            final percentage =
                (newCompletedCount / project.totalTickets * 100).round();

            // Notify on 50%, 90%, or 100% completion
            String? milestoneType;
            if (percentage == 50) {
              milestoneType = 'halfway';
            } else if (percentage == 90) {
              milestoneType = 'almost_done';
            } else if (percentage == 100) {
              milestoneType = 'completed';
            }

            if (milestoneType != null) {
              // Notify all team members
              for (final memberEmail in project.teamMembers) {
                final memberDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: memberEmail)
                    .limit(1)
                    .get();

                if (memberDoc.docs.isNotEmpty) {
                  final memberId = memberDoc.docs.first.id;
                  await NotificationManager().notifyProjectMilestone(
                    userId: memberId,
                    projectTitle: project.title,
                    projectId: project.id,
                    milestoneType: milestoneType,
                    percentage: percentage,
                  );
                }
              }
            }
          }
        } catch (e) {
          print('Error sending task status change notifications: \$e');
        }
      }

      // Check for deadline notifications (24 hours warning)
      if (selectedDeadline != null) {
        final timeUntilDeadline = selectedDeadline!.difference(DateTime.now());
        if (timeUntilDeadline.inHours > 0 && timeUntilDeadline.inHours <= 24) {
          try {
            final firestoreService = FirestoreService();
            final project =
                await firestoreService.getProjectById(widget.ticket.projectId);

            for (final assigneeEmail in selectedAssignees) {
              final assigneeDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: assigneeEmail)
                  .limit(1)
                  .get();

              if (assigneeDoc.docs.isNotEmpty) {
                final assigneeId = assigneeDoc.docs.first.id;
                await NotificationManager().notifyTaskDeadlineApproaching(
                  userId: assigneeId,
                  taskTitle: titleController.text,
                  projectTitle: project?.title ?? 'Unknown Project',
                  taskId: widget.ticket.ticketNumber,
                  projectId: widget.ticket.projectId,
                  deadline: selectedDeadline!,
                );
              }
            }
          } catch (e) {
            print('Error sending deadline notifications: \$e');
          }
        }
      }

      // Check for overdue tasks
      if (selectedDeadline != null &&
          selectedDeadline!.isBefore(DateTime.now()) &&
          selectedStatus != 'done') {
        try {
          final firestoreService = FirestoreService();
          final project =
              await firestoreService.getProjectById(widget.ticket.projectId);

          for (final assigneeEmail in selectedAssignees) {
            final assigneeDoc = await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: assigneeEmail)
                .limit(1)
                .get();

            if (assigneeDoc.docs.isNotEmpty) {
              final assigneeId = assigneeDoc.docs.first.id;
              await NotificationManager().notifyTaskOverdue(
                userId: assigneeId,
                taskTitle: titleController.text,
                projectTitle: project?.title ?? 'Unknown Project',
                taskId: widget.ticket.ticketNumber,
                projectId: widget.ticket.projectId,
              );
            }
          }
        } catch (e) {
          print('Error sending overdue notifications: \$e');
        }
      }

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

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((img) => File(img.path)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<List<String>> _uploadTicketImages() async {
    if (_selectedImages.isEmpty) return [];

    try {
      final List<String> uploadedUrls = [];
      for (final image in _selectedImages) {
        final imageUrl = await _cloudinaryService.uploadImage(
          image,
          uploadType: CloudinaryUploadType.projectImage,
        );
        uploadedUrls.add(imageUrl);
      }
      return uploadedUrls;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading images: $e')),
        );
      }
      return [];
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class _AssigneeSelector extends StatefulWidget {
  final Project project;
  final List<String> selectedAssignees;
  final ValueChanged<List<String>> onSelectionChanged;

  const _AssigneeSelector({
    required this.project,
    required this.selectedAssignees,
    required this.onSelectionChanged,
  });

  @override
  State<_AssigneeSelector> createState() => _AssigneeSelectorState();
}

class _AssigneeSelectorState extends State<_AssigneeSelector> {
  final UserService _userService = UserService();
  late Map<String, Map<String, String>> _userDetails;
  bool _isLoading = true;
  late List<String> _selectedItems;

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
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedAssignees);
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      // Get team members who have accepted the project invitation, excluding the project creator
      final currentUser = FirebaseAuth.instance.currentUser;
      final assignableMembers = widget.project.acceptedMemberEmails
          .where((email) => email != currentUser?.email)
          .toList();
      
      _userDetails = await _userService
          .getUsersDetailsByEmails(assignableMembers);
    } catch (e) {
      _userDetails = {};
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDisplayName(String email) {
    final details = _userDetails[email] ?? {};
    return _userService.getDisplayName(details, email);
  }

  String _getProfilePictureUrl(String email) {
    return _userDetails[email]?['profilePictureUrl'] ?? '';
  }

  Color _getColorForEmail(String email) {
    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.red.shade300,
      Colors.purple.shade300,
      Colors.orange.shade300,
      Colors.pink.shade300,
      Colors.cyan.shade300,
      Colors.amber.shade300,
    ];
    final hash = email.hashCode.abs();
    return colors[hash % colors.length];
  }

  Widget _buildAvatar(String email, {double radius = 16}) {
    final url = _getProfilePictureUrl(email);
    final displayName = _getDisplayName(email);
    final firstLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : email[0].toUpperCase();

    if (url.isNotEmpty) {
      print('Loading avatar for $email with URL: $url');
    }
    
    return CircleAvatar(
      radius: radius,
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      onBackgroundImageError: url.isNotEmpty
          ? (exception, stackTrace) {
              print('Error loading avatar for $email: $exception');
              print('URL was: $url');
            }
          : null,
      backgroundColor: _getColorForEmail(email),
      child: url.isEmpty
          ? Text(
              firstLetter,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.6,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: SizedBox(
          height: 40,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_getProjectColor()),
            ),
          ),
        ),
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final assignableMembers = widget.project.acceptedMemberEmails
        .where((email) => email != currentUser?.email)
        .toList();

    if (assignableMembers.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Center(
          child: Text(
            'No team members available',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Selected assignees display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_outline, 
                         size: 18, 
                         color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Selected Assignees',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedItems.length} selected',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                if (_selectedItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedItems.map((email) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getProjectColor(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAvatar(email, radius: 10),
                            const SizedBox(width: 6),
                            Text(
                              _getDisplayName(email),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedItems.remove(email);
                                  widget.onSelectionChanged(_selectedItems);
                                });
                              },
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'No assignees selected',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Members list
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                children: _buildMemberSections(assignableMembers),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMemberSections(List<String> assignableMembers) {
    final sections = <Widget>[];
    
    // Build role-based sections
    for (final role in widget.project.roles) {
      final roleMembers = role.members
          .where((email) => assignableMembers.contains(email))
          .toList();

      if (roleMembers.isNotEmpty) {
        sections.add(_buildRoleSection(role, roleMembers));
      }
    }

    // Add "Other Members" section
    final unassignedMembers = assignableMembers
        .where((email) =>
            !widget.project.roles.any((role) => role.members.contains(email)))
        .toList();

    if (unassignedMembers.isNotEmpty) {
      sections.add(_buildOtherMembersSection(unassignedMembers));
    }

    return sections;
  }

  Widget _buildRoleSection(ProjectRole role, List<String> roleMembers) {
    final allRoleSelected = roleMembers.every((email) => _selectedItems.contains(email));
    
    return Container(
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Role header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Icon(Icons.group, 
                     size: 16, 
                     color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    role.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                ),
                Text(
                  '${roleMembers.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (allRoleSelected) {
                        for (final email in roleMembers) {
                          _selectedItems.remove(email);
                        }
                      } else {
                        for (final email in roleMembers) {
                          if (!_selectedItems.contains(email)) {
                            _selectedItems.add(email);
                          }
                        }
                      }
                      widget.onSelectionChanged(_selectedItems);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: allRoleSelected 
                          ? _getProjectColor() 
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      allRoleSelected ? Icons.check : Icons.add,
                      size: 14,
                      color: allRoleSelected ? Colors.black : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Role members
          ...roleMembers.map((email) => _buildMemberTile(email)),
        ],
      ),
    );
  }

  Widget _buildOtherMembersSection(List<String> members) {
    return Container(
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Icon(Icons.person, 
                     size: 16, 
                     color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Other Members',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Text(
                  '${members.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Members
          ...members.map((email) => _buildMemberTile(email)),
        ],
      ),
    );
  }

  Widget _buildMemberTile(String email) {
    final isSelected = _selectedItems.contains(email);
    
    return Container(
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedItems.remove(email);
              } else {
                _selectedItems.add(email);
              }
              widget.onSelectionChanged(_selectedItems);
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildAvatar(email, radius: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDisplayName(email),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? _getProjectColor() : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected ? _getProjectColor() : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.black,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
