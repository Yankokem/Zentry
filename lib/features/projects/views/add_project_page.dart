import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/core/services/firebase/notification_manager.dart';
import 'package:zentry/features/projects/projects.dart';

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
  bool _isSaving = false; // Prevent double-tap

  final List<String> _statusOptions = [
    'Planning',
    'In Progress',
    'Completed',
    'On Hold'
  ];
  final List<String> _colorOptions = [
    'yellow',
    'blue',
    'green',
    'purple',
    'red'
  ];
  final List<String> _typeOptions = ['workspace', 'personal'];

  final ProjectManager _projectManager = ProjectManager();
  final FirestoreService _firestoreService = FirestoreService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (widget.projectToEdit != null) {
      _titleController.text = widget.projectToEdit!.title;
      _descriptionController.text = widget.projectToEdit!.description;
      // Load team members but remove the creator's email if present
      _teamMembers = (widget.projectToEdit!.teamMembers)
          .where((email) => email != currentUser?.email)
          .toList();
      _selectedStatus = widget.projectToEdit!.status;
      _selectedColor = widget.projectToEdit!.color;
      _selectedType = widget.projectToEdit!.category;
      _roles = List.from(widget.projectToEdit!.roles);
    } else {
      // For new projects, don't add the creator to team members
      // The creator is separate from team members
      _teamMembers = [];
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

    // Prevent adding the project creator as a member
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.email == member) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You are the project creator and cannot be added as a member'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

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
      final currentUser = FirebaseAuth.instance.currentUser;
      if (mounted) {
        setState(() {
          _suggestedEmails = suggestions
              .where((email) =>
                  !_teamMembers.contains(email) &&
                  email != currentUser?.email) // Filter out current user
              .toList();
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
    // Prevent adding the project creator as a member
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.email == email) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You are the project creator and cannot be added as a member'),
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
    if (_roles
        .any((role) => role.name.toLowerCase() == roleName.toLowerCase())) {
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
        final updatedMembers =
            _roles[roleIndex].members.where((m) => m != member).toList();
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

  // Helper method to find role for a member
  String? _getMemberRole(String email) {
    for (final role in _roles) {
      if (role.members.contains(email)) {
        return role.name;
      }
    }
    return null;
  }

  /// Clean roles to ensure only the creator is in the Project Manager role
  List<ProjectRole> _cleanRoles(String creatorEmail) {
    return _roles.map((role) {
      if (role.name == 'Project Manager') {
        // Project Manager role should only contain the creator
        return role.copyWith(members: []);
      }
      return role;
    }).toList();
  }

  // Helper method to create teamMemberDetails from teamMembers
  List<TeamMember> _buildTeamMemberDetails(String currentUserEmail) {
    return _teamMembers.map((email) {
      final role = _getMemberRole(email);
      // Current user (creator) is always accepted, others start as pending
      final status = email == currentUserEmail ? 'accepted' : 'pending';
      return TeamMember(
        email: email,
        status: status,
        role: role,
        invitedAt: DateTime.now(),
      );
    }).toList();
  }

  void _saveProject() async {
    if (_formKey.currentState!.validate()) {
      // Prevent double-tap
      if (_isSaving) return;

      // Validate that workspace projects have at least one team member
      if (_selectedType == 'workspace' && _teamMembers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Workspace projects require at least one team member'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;

        // Ensure creator is not in team members
        final cleanTeamMembers =
            _teamMembers.where((email) => email != currentUser.email).toList();

        // Clean roles - ensure only creator is Project Manager
        final cleanedRoles = _cleanRoles(currentUser.email!);

        if (widget.projectToEdit != null) {
          // Track which members were added/removed
          final oldMembers = widget.projectToEdit!.teamMembers.toSet();
          final newMembers = cleanTeamMembers.toSet();
          final addedMembers = newMembers.difference(oldMembers);
          final removedMembers = oldMembers.difference(newMembers);

          // Build updated teamMemberDetails
          final teamMemberDetails = _buildTeamMemberDetails(currentUser.email!);

          // Update existing project
          final updatedProject = widget.projectToEdit!.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            teamMembers: cleanTeamMembers,
            teamMemberDetails: teamMemberDetails,
            status: _selectedStatus,
            color: _selectedColor,
            roles: cleanedRoles,
          );
          await _projectManager.updateProject(updatedProject);

          // Send notifications for added members
          if (addedMembers.isNotEmpty) {
            try {
              final currentUserData =
                  await _firestoreService.getUserData(currentUser.uid);
              final currentUserName = currentUserData?['firstName'] ??
                  currentUser.email ??
                  'Someone';

              for (final memberEmail in addedMembers) {
                if (memberEmail != currentUser.email) {
                  final memberDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: memberEmail)
                      .limit(1)
                      .get();

                  if (memberDoc.docs.isNotEmpty) {
                    final memberId = memberDoc.docs.first.id;
                    final memberRole = _getMemberRole(memberEmail);
                    await NotificationManager().notifyProjectInvitation(
                      recipientUserId: memberId,
                      projectTitle: _titleController.text.trim(),
                      projectId: widget.projectToEdit!.id,
                      inviterName: currentUserName,
                      role: memberRole,
                    );
                  }
                }
              }
            } catch (e) {
              print('Error sending project invitation notifications: $e');
            }
          }

          // Send notifications for removed members
          if (removedMembers.isNotEmpty) {
            try {
              final currentUserData =
                  await _firestoreService.getUserData(currentUser.uid);
              final currentUserName = currentUserData?['firstName'] ??
                  currentUser.email ??
                  'Someone';

              for (final memberEmail in removedMembers) {
                if (memberEmail != currentUser.email) {
                  final memberDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: memberEmail)
                      .limit(1)
                      .get();

                  if (memberDoc.docs.isNotEmpty) {
                    final memberId = memberDoc.docs.first.id;
                    await NotificationManager().notifyProjectRemoval(
                      recipientUserId: memberId,
                      projectTitle: widget.projectToEdit!.title,
                      projectId: widget.projectToEdit!.id,
                      removerName: currentUserName,
                    );
                  }
                }
              }
            } catch (e) {
              print('Error sending project removal notifications: $e');
            }
          }

          // Check for status change and notify team members
          if (widget.projectToEdit!.status != _selectedStatus) {
            try {
              final currentUserData =
                  await _firestoreService.getUserData(currentUser.uid);
              final currentUserName = currentUserData?['firstName'] ??
                  currentUser.email ??
                  'Someone';

              for (final memberEmail in _teamMembers) {
                if (memberEmail != currentUser.email) {
                  final memberDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: memberEmail)
                      .limit(1)
                      .get();

                  if (memberDoc.docs.isNotEmpty) {
                    final memberId = memberDoc.docs.first.id;
                    await NotificationManager().notifyProjectStatusChanged(
                      recipientUserId: memberId,
                      projectTitle: _titleController.text.trim(),
                      projectId: widget.projectToEdit!.id,
                      newStatus: _selectedStatus,
                      changedByName: currentUserName,
                    );
                  }
                }
              }
            } catch (e) {
              print('Error sending project status change notifications: $e');
            }
          }

          // Check for project milestone
          if (_selectedStatus == 'Completed') {
            try {
              final project = await _firestoreService
                  .getProjectById(widget.projectToEdit!.id);
              if (project != null && project.totalTickets > 0) {
                final percentage =
                    (project.completedTickets / project.totalTickets * 100)
                        .round();

                // Notify all team members about completion
                for (final memberEmail in _teamMembers) {
                  final memberDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: memberEmail)
                      .limit(1)
                      .get();

                  if (memberDoc.docs.isNotEmpty) {
                    final memberId = memberDoc.docs.first.id;
                    await NotificationManager().notifyProjectMilestone(
                      userId: memberId,
                      projectTitle: _titleController.text.trim(),
                      projectId: widget.projectToEdit!.id,
                      milestoneType: 'completed',
                      percentage: 100,
                    );
                  }
                }
              }
            } catch (e) {
              print('Error sending project milestone notifications: $e');
            }
          }
        } else {
          // Build teamMemberDetails for new project
          final teamMemberDetails = _buildTeamMemberDetails(currentUser.email!);

          // Create new project
          final newProject = Project(
            id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
            userId: '', // This will be set by ProjectManager
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            teamMembers: cleanTeamMembers,
            teamMemberDetails: teamMemberDetails,
            status: _selectedStatus,
            totalTickets: 0,
            completedTickets: 0,
            color: _selectedColor,
            category: _selectedType,
            roles: cleanedRoles,
          );
          await _projectManager.addProject(newProject);

          // Send project invitation notifications to all team members except creator
          if (cleanTeamMembers.isNotEmpty) {
            try {
              final currentUserData =
                  await _firestoreService.getUserData(currentUser.uid);
              final currentUserName = currentUserData?['firstName'] ??
                  currentUser.email ??
                  'Someone';

              for (final memberEmail in cleanTeamMembers) {
                if (memberEmail != currentUser.email) {
                  final memberDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: memberEmail)
                      .limit(1)
                      .get();

                  if (memberDoc.docs.isNotEmpty) {
                    final memberId = memberDoc.docs.first.id;
                    final memberRole = _getMemberRole(memberEmail);
                    await NotificationManager().notifyProjectInvitation(
                      recipientUserId: memberId,
                      projectTitle: _titleController.text.trim(),
                      projectId: newProject.id,
                      inviterName: currentUserName,
                      role: memberRole,
                    );
                  }
                }
              }
            } catch (e) {
              print('Error sending project invitation notifications: $e');
            }
          }
        }

        if (mounted) {
          Navigator.pop(context);
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedType == 'workspace'
                          ? Icons.business
                          : Icons.person,
                      color: _selectedType == 'workspace'
                          ? Colors.blue
                          : Colors.orange,
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
                  initialValue: _selectedType,
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
                        final currentUserEmail =
                            FirebaseAuth.instance.currentUser?.email;
                        _teamMembers =
                            currentUserEmail != null ? [currentUserEmail] : [];
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
                      'Team Members',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
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
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusLarge),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      suffixIcon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value.trim())) {
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
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusLarge),
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
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _createRole,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.textDark,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
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
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 20, color: Colors.red),
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
                                        .where((member) =>
                                            !role.members.contains(member))
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
                                          label: Text(member,
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                          deleteIcon:
                                              const Icon(Icons.close, size: 14),
                                          onDeleted: () =>
                                              _removeMemberFromRole(
                                                  role.name, member),
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
                        Icon(_getStatusIcon(status),
                            color: statusColor, size: 20),
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
                  widget.projectToEdit != null
                      ? 'Save Changes'
                      : 'Create Project',
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
