import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zentry/config/constants.dart';
import 'package:zentry/config/theme.dart';
import 'package:zentry/models/project_model.dart';
import 'package:zentry/models/project_role_model.dart';
import 'package:zentry/services/firebase/firestore_service.dart';
import 'package:zentry/services/firebase/user_service.dart';
import 'package:zentry/services/project_manager.dart';

class AddProjectPage extends StatefulWidget {
  final Project? projectToEdit;

  const AddProjectPage({super.key, this.projectToEdit});

  @override
  State<AddProjectPage> createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newMemberController = TextEditingController();
  final _newRoleController = TextEditingController();
  String _selectedStatus = 'Planning';
  String _selectedColor = 'yellow';
  String _selectedType = 'workspace';
  List<String> _teamMembers = [];
  List<String> _suggestedEmails = [];
  bool _isSearching = false;
  List<ProjectRole> _roles = [];
  String? _selectedRoleForAssignment;

  final List<String> _statusOptions = ['Planning', 'In Progress', 'Completed', 'On Hold'];
  final List<String> _colorOptions = ['yellow', 'blue', 'green', 'purple', 'red'];
  final List<String> _typeOptions = ['workspace', 'personal'];

  final ProjectManager _projectManager = ProjectManager();
  final FirestoreService _firestoreService = FirestoreService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    if (widget.projectToEdit != null) {
      _titleController.text = widget.projectToEdit!.title;
      _descriptionController.text = widget.projectToEdit!.description;
      _teamMembers = List.from(widget.projectToEdit!.teamMembers);
      _selectedStatus = widget.projectToEdit!.status;
      _selectedColor = widget.projectToEdit!.color;
      _selectedType = widget.projectToEdit!.category;
      _roles = List.from(widget.projectToEdit!.roles);
    } else {
      // For new projects, automatically add the current user as a team member
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.email != null) {
        _teamMembers.add(currentUser.email!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _newMemberController.dispose();
    _newRoleController.dispose();
    super.dispose();
  }

  Future<void> _addTeamMember() async {
    final member = _newMemberController.text.trim();
    if (member.isEmpty) return;

    if (_teamMembers.contains(member)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This email is already added to the team'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final exists = await _firestoreService.userExistsByEmail(member);
      if (mounted) {
        if (exists) {
          setState(() {
            _teamMembers.add(member);
            _newMemberController.clear();
            _suggestedEmails.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email added successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No account found with this email'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking account: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestedEmails.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final suggestions = await _userService.searchUsers(query);
      if (mounted) {
        setState(() {
          _suggestedEmails = suggestions.where((email) => !_teamMembers.contains(email)).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestedEmails.clear();
          _isSearching = false;
        });
      }
    }
  }

  void _selectSuggestedEmail(String email) async {
    // Add immediately when email is selected from suggestions
    if (_teamMembers.contains(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This email is already added to the team'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        _newMemberController.clear();
        _suggestedEmails.clear();
      });
      return;
    }

    setState(() {
      _teamMembers.add(email);
      _newMemberController.clear();
      _suggestedEmails.clear();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email added successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeTeamMember(String member) {
    setState(() {
      _teamMembers.remove(member);
    });
  }

  void _createRole() {
    final roleName = _newRoleController.text.trim();
    if (roleName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a role name'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check if role already exists
    if (_roles.any((role) => role.name.toLowerCase() == roleName.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This role already exists'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _roles.add(ProjectRole(name: roleName, members: []));
      _newRoleController.clear();
      _selectedRoleForAssignment = roleName;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Role created successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addMemberToRole(String roleName, String member) {
    final roleIndex = _roles.indexWhere((role) => role.name == roleName);
    if (roleIndex != -1) {
      if (_roles[roleIndex].members.contains(member)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This member already has this role'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        final updatedMembers = [..._roles[roleIndex].members, member];
        _roles[roleIndex] = _roles[roleIndex].copyWith(members: updatedMembers);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Member added to role'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeMemberFromRole(String roleName, String member) {
    final roleIndex = _roles.indexWhere((role) => role.name == roleName);
    if (roleIndex != -1) {
      setState(() {
        final updatedMembers = _roles[roleIndex].members.where((m) => m != member).toList();
        _roles[roleIndex] = _roles[roleIndex].copyWith(members: updatedMembers);
      });
    }
  }

  void _deleteRole(String roleName) {
    setState(() {
      _roles.removeWhere((role) => role.name == roleName);
      if (_selectedRoleForAssignment == roleName) {
        _selectedRoleForAssignment = null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Role deleted'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveProject() async {
    if (_formKey.currentState!.validate()) {
      if (widget.projectToEdit != null) {
        // Update existing project
        final updatedProject = widget.projectToEdit!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          teamMembers: _teamMembers,
          status: _selectedStatus,
          color: _selectedColor,
          roles: _roles,
        );
        await _projectManager.updateProject(updatedProject);
      } else {
        // Create new project
        final newProject = Project(
          id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
          userId: '', // This will be set by ProjectManager
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          teamMembers: _teamMembers,
          status: _selectedStatus,
          totalTickets: 0,
          completedTickets: 0,
          color: _selectedColor,
          category: _selectedType,
          roles: _roles,
        );
        await _projectManager.addProject(newProject);
      }
      Navigator.pop(context);
    }
  }

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
        title: Text(
          widget.projectToEdit != null ? 'Edit Project' : 'New Project',
          style: const TextStyle(
            color: Color(0xFF1E1E1E),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
              // Title Field
              Row(
                children: [
                  Icon(Icons.title, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Project Title',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                  Expanded(
                    child: Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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

              // Project Type Dropdown
              Row(
                children: [
                  Icon(Icons.category, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Project Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.projectToEdit != null)
                // Disabled state - show as a read-only container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedType == 'workspace' ? Icons.business : Icons.person,
                        color: _selectedType == 'workspace' ? Colors.blue : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedType.capitalize(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.lock,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                )
              else
                // Editable dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    items: _typeOptions.map((type) {
                      final isWorkspace = type == 'workspace';
                      final color = isWorkspace ? Colors.blue : Colors.orange;
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              isWorkspace ? Icons.business : Icons.person,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Text(type.capitalize()),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        // Clear team members if switching to personal
                        if (_selectedType == 'personal') {
                          final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
                          _teamMembers = currentUserEmail != null ? [currentUserEmail] : [];
                        }
                      });
                    },
                  ),
                ),
              const SizedBox(height: 32),

              // Team Members Field (only show for workspace)
              if (_selectedType == 'workspace') ...[
              Row(
                children: [
                  Icon(Icons.group, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Team Members (emails, optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Add new member input
              Column(
                children: [
                  TextFormField(
                    controller: _newMemberController,
                    onChanged: _searchUsers,
                    decoration: InputDecoration(
                      hintText: 'Enter team member email',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                      }
                      return null;
                    },
                  ),
                  // Suggestions dropdown
                  if (_suggestedEmails.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestedEmails.length,
                        itemBuilder: (context, index) {
                          final email = _suggestedEmails[index];
                          return ListTile(
                            title: Text(email),
                            onTap: () => _selectSuggestedEmail(email),
                            dense: true,
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Display current team members
              if (_teamMembers.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _teamMembers.map((member) {
                    return Chip(
                      label: Text(member),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeTeamMember(member),
                      backgroundColor: Colors.grey.shade100,
                      deleteIconColor: Colors.red.shade600,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ],
              const SizedBox(height: 16),

              // Role Management Section (only for workspace projects)
              if (_selectedType == 'workspace') ...[
                Row(
                  children: [
                    Icon(Icons.badge, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Team Roles (Optional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Text(
                'Assign roles to organize your team by responsibilities',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              // Create New Role
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Role',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _newRoleController,
                            decoration: InputDecoration(
                              hintText: 'e.g., Backend Developer, Designer',
                              filled: true,
                              fillColor: AppTheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _createRole,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.textDark,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: const Text('Add Role'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Display Roles with Members
              if (_roles.isNotEmpty) ...[
                Text(
                  'Roles & Members',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          title: Text(
                            role.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${role.members.length} member${role.members.length != 1 ? 's' : ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            onPressed: () => _deleteRole(role.name),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Add member to role dropdown
                                  DropdownButton<String>(
                                    hint: const Text('Select member to add'),
                                    isExpanded: true,
                                    items: _teamMembers
                                        .where((member) => !role.members.contains(member))
                                        .map((member) {
                                      return DropdownMenuItem(
                                        value: member,
                                        child: Text(member),
                                      );
                                    }).toList(),
                                    onChanged: (member) {
                                      if (member != null) {
                                        _addMemberToRole(role.name, member);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // List of members in this role
                                  if (role.members.isNotEmpty) ...[
                                    Text(
                                      'Members in this role:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: role.members.map((member) {
                                        return Chip(
                                          label: Text(member, style: const TextStyle(fontSize: 12)),
                                          deleteIcon: const Icon(Icons.close, size: 14),
                                          onDeleted: () => _removeMemberFromRole(role.name, member),
                                          backgroundColor: Colors.blue.shade50,
                                          deleteIconColor: Colors.red.shade600,
                                        );
                                      }).toList(),
                                    ),
                                  ] else
                                    Text(
                                      'No members assigned yet',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
              const SizedBox(height: 16),
              ], // End workspace-only roles section

              // Status Dropdown
              Row(
                children: [
                  Icon(Icons.flag, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  items: _statusOptions.map((status) {
                    final statusColor = _getStatusColor(status);
                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(_getStatusIcon(status), color: statusColor, size: 20),
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
                  Expanded(
                    child: Text(
                      'Color Theme',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                  initialValue: _selectedColor,
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



              // Save Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.projectToEdit != null ? 'Save Changes' : 'Create Project',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
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

  static Color _getStatusColor(String status) {
    switch (status) {
      case 'Planning':
        return Colors.blue;
      case 'In Progress':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'On Hold':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
