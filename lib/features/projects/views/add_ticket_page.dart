import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/core/services/firebase/notification_manager.dart';
import 'package:zentry/features/journal/widgets/rich_text_editor.dart';
import 'package:zentry/features/projects/projects.dart';

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
  final _descriptionController = RichTextEditorController();
  final _cloudinaryService = CloudinaryService();
  
  String selectedPriority = 'medium';
  String selectedStatus = 'todo';
  List<String> selectedAssignees = [];
  List<XFile> _selectedImages = [];
  DateTime? selectedDeadline;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // Check if current user is the project manager
    final projectManager = ProjectManager();
    final currentUserId = projectManager.getCurrentUserId();
    if (currentUserId != widget.project.userId) {
      // If not the project manager, show error and navigate back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showErrorDialog('Access Denied', 'Only project managers can create tickets');
          Navigator.pop(context);
        }
      });
      return;
    }
    
    _descriptionController.clear();
    
    // Get team members who have accepted the project invitation
    final currentUser = FirebaseAuth.instance.currentUser;
    final assignableMembers = widget.project.acceptedMemberEmails
        .where((email) => email != currentUser?.email)
        .toList();

    if (assignableMembers.isNotEmpty) {
      selectedAssignees = [assignableMembers.first];
    }
  }

  Color _getProjectColor() {
    switch (widget.project.color) {
      case 'yellow':
        return const Color(0xFFF9ED69);
      case 'blue':
        return const Color(0xFF42A5F5);
      case 'green':
        return const Color(0xFF66BB6A);
      case 'purple':
        return const Color(0xFFAB47BC);
      case 'red':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFFF9ED69);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        icon: const Icon(Icons.error, color: Colors.red, size: 32),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
            onPressed: _isSaving ? null : _saveTicket,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1E1E1E),
                    ),
                  )
                : const Text(
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
                      'Add Images (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedImages.isNotEmpty)
                      Column(
                        children: [
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
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
                                        child: kIsWeb
                                            ? Image.network(
                                                _selectedImages[index].path,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File(_selectedImages[index].path),
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 16,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
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
                    // Rich Text Description Editor
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
        Row(
          children: [
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDeadline ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDeadline = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        selectedDeadline?.hour ?? 11,
                        selectedDeadline?.minute ?? 59,
                      );
                    });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: Colors.grey.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedDeadline != null
                              ? '${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                              : 'Date',
                          style: TextStyle(
                            color: selectedDeadline != null
                                ? Colors.black
                                : Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: selectedDeadline?.hour ?? 11,
                      minute: selectedDeadline?.minute ?? 59,
                    ),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      if (selectedDeadline != null) {
                        selectedDeadline = DateTime(
                          selectedDeadline!.year,
                          selectedDeadline!.month,
                          selectedDeadline!.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      } else {
                        // If no date selected yet, default to today
                        selectedDeadline = DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      }
                    });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: Colors.grey.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedDeadline != null
                              ? '${selectedDeadline!.hour.toString().padLeft(2, '0')}:${selectedDeadline!.minute.toString().padLeft(2, '0')}'
                              : 'Time',
                          style: TextStyle(
                            color: selectedDeadline != null
                                ? Colors.black
                                : Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _saveTicket() async {
    if (_formKey.currentState!.validate()) {
      // Prevent double-tap
      if (_isSaving) return;

      if (selectedDeadline == null) {
        _showErrorDialog('Deadline Required', 'Please select a deadline for the ticket');
        return;
      }

      // Validate description is not empty
      if (_descriptionController.getPlainText().trim().isEmpty) {
        _showErrorDialog('Description Required', 'Please enter a description for the ticket');
        return;
      }

      // Validate at least one assignee is selected
      if (selectedAssignees.isEmpty) {
        _showErrorDialog('Assignee Required', 'Please select at least one assignee for the ticket');
        return;
      }

      // Validate all assignees are accepted members
      final pendingAssignees = selectedAssignees
          .where(
              (email) => !widget.project.acceptedMemberEmails.contains(email))
          .toList();

      if (pendingAssignees.isNotEmpty) {
        _showErrorDialog('Pending Members', 'Cannot assign to pending members: ${pendingAssignees.join(", ")}. They must accept the project invitation first.');
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        // Upload images if selected
        List<String> imageUrls = [];
        if (_selectedImages.isNotEmpty) {
          try {
            imageUrls = await _uploadTicketImages();
          } catch (e) {
            _showErrorDialog('Image Upload Failed', 'Failed to upload images. Please try again or create ticket without images.');
            return;
          }
        }

        // Generate ticket number
        final ticketNumber =
            'TICK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

        final newTicket = Ticket(
          ticketNumber: ticketNumber,
          userId: '',
          title: titleController.text,
          description: _descriptionController.getJsonContent(),
          richDescription: _descriptionController.getJsonContent(),
          imageUrls: imageUrls,
          priority: selectedPriority,
          status: selectedStatus,
          assignedTo: selectedAssignees,
          projectId: widget.project.id,
          deadline: selectedDeadline!,
        );

        await ProjectManager().addTicket(newTicket);

        // Send notifications to assigned users
        final currentUser = FirebaseAuth.instance.currentUser;
        final firestoreService = FirestoreService();

        if (currentUser != null) {
          try {
            final currentUserData =
                await firestoreService.getUserData(currentUser.uid);
            final currentUserName = currentUserData?['firstName'] ?? currentUser.email ?? 'Someone';

            // Notify each assigned user (except current user)
            for (final assigneeEmail in selectedAssignees) {
              if (assigneeEmail != currentUser.email) {
                // Query Firestore to get user ID from email
                final assigneeUserDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: assigneeEmail.toLowerCase())
                    .limit(1)
                    .get();

                if (assigneeUserDoc.docs.isNotEmpty) {
                  final assigneeUserId = assigneeUserDoc.docs.first.id;
                  await NotificationManager().notifyTaskAssigned(
                    recipientUserId: assigneeUserId,
                    taskTitle: titleController.text,
                    projectTitle: widget.project.title,
                    taskId: ticketNumber,
                    projectId: widget.project.id,
                    assignerName: currentUserName,
                  );
                }
              }
            }
          } catch (e) {
            print('Error sending notifications: $e');
          }
        }

        widget.refreshTickets();

        // Show success dialog and navigate back
        if (mounted) {
          Navigator.pop(context);
          _showSuccessDialog('Ticket Created', 'Your ticket $ticketNumber has been successfully created.');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
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
          _selectedImages = images;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Image Error', 'Error picking images: ${e.toString()}');
      }
    }
  }

  Future<List<String>> _uploadTicketImages() async {
    if (_selectedImages.isEmpty) return [];

    try {
      final List<String> uploadedUrls = [];
      for (final image in _selectedImages) {
        final imageUrl = await _cloudinaryService.uploadXFile(
          image,
          uploadType: CloudinaryUploadType.projectImage,
        );
        uploadedUrls.add(imageUrl);
      }
      return uploadedUrls;
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Upload Error', 'Error uploading images: ${e.toString()}');
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

      _userDetails =
          await _userService.getUsersDetailsByEmails(assignableMembers);
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
