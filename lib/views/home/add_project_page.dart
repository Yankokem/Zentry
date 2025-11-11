import 'package:flutter/material.dart';
import 'package:zentry/config/constants.dart';
import 'package:zentry/models/project_model.dart';
import 'package:zentry/services/project_manager.dart';

class AddProjectPage extends StatefulWidget {
  const AddProjectPage({super.key});

  @override
  State<AddProjectPage> createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _teamMembersController = TextEditingController();
  String _selectedStatus = 'Planning';
  String _selectedColor = 'yellow';

  final List<String> _statusOptions = ['Planning', 'In Progress', 'Completed', 'On Hold'];
  final List<String> _colorOptions = ['yellow', 'blue', 'green', 'purple', 'red'];

  final ProjectManager _projectManager = ProjectManager();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _teamMembersController.dispose();
    super.dispose();
  }

  void _saveProject() {
    if (_formKey.currentState!.validate()) {
      final newProject = Project(
        id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        teamMembers: _teamMembersController.text.isEmpty
            ? []
            : _teamMembersController.text.split(',').map((e) => e.trim()).toList(),
        status: _selectedStatus,
        totalTickets: 0,
        completedTickets: 0,
        color: _selectedColor,
      );

      _projectManager.addProject(newProject);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9ED69),
        elevation: 0,
        title: Text(
          'Add New Project',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E1E1E),
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveProject,
            child: Text(
              'Save',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1E1E),
                  ),
            ),
          ),
            ],
          ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          ),
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Title Field
              Row(
                children: [
                  Icon(Icons.title, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Project Title',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter project title',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a project title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Description Field
              Row(
                children: [
                  Icon(Icons.description, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter project description',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a project description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Team Members Field
              Row(
                children: [
                  Icon(Icons.group, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Team Members (optional)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _teamMembersController,
                decoration: InputDecoration(
                  hintText: 'Enter team members separated by commas',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Status Dropdown
              Row(
                children: [
                  Icon(Icons.flag, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(_getStatusIcon(status), color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(status),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Color Dropdown
              Row(
                children: [
                  Icon(Icons.palette, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Color Theme',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedColor,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  items: _colorOptions.map((color) {
                    return DropdownMenuItem(
                      value: color,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getColorFromString(color),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(color.capitalize()),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedColor = value!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _getColorFromString(String color) {
    switch (color) {
      case 'yellow':
        return Colors.yellow;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      default:
        return Colors.yellow;
    }
  }

  static IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Planning':
        return Icons.lightbulb;
      case 'In Progress':
        return Icons.play_arrow;
      case 'Completed':
        return Icons.check_circle;
      case 'On Hold':
        return Icons.pause;
      default:
        return Icons.flag;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
