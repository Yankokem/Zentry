import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:zentry/core/core.dart';
import 'package:flutter/services.dart';
import 'package:zentry/features/projects/projects.dart';

class ProjectsPage extends StatefulWidget {
  final String? initialFilter;
  final ValueNotifier<String>? filterNotifier;

  const ProjectsPage({super.key, this.initialFilter, this.filterNotifier});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ProjectManager _projectManager = ProjectManager();

  List<Project> _projects = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'all';
  StreamSubscription<List<Project>>? _projectsStreamSubscription;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF9ED69),
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Set initial filter if provided
    if (widget.initialFilter != null) {
      _selectedCategory = widget.initialFilter!;
    }

    // Listen to filter changes
    widget.filterNotifier?.addListener(_onFilterChanged);

    _setupProjectsStream();
  }

  void _onFilterChanged() {
    if (widget.filterNotifier != null) {
      setState(() {
        _selectedCategory = widget.filterNotifier!.value;
      });
    }
  }

  void _setupProjectsStream() {
    _projectsStreamSubscription?.cancel();
    
    try {
      _projectsStreamSubscription = _projectManager.listenToProjects().listen(
        (projects) {
          if (mounted) {
            setState(() {
              _projects = projects;
              _isLoading = false;
              _errorMessage = null;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = error.toString();
              _isLoading = false;
            });
          }
          print('Error in projects stream: $error');
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to set up projects stream: $e';
          _isLoading = false;
        });
      }
      print('Error setting up projects stream: $e');
    }
  }

  Future<void> _loadProjects() async {
    _setupProjectsStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    widget.filterNotifier?.removeListener(_onFilterChanged);
    _projectsStreamSubscription?.cancel();
    super.dispose();
  }



  List<Project> _getFilteredProjects() {
    List<Project> filtered = _projects;
    final currentUserId = _projectManager.getCurrentUserId();

    // Filter by ownership and sharing status
    if (_selectedCategory == 'workspace') {
      // Show workspace projects created by the user (owned workspace projects)
      filtered = filtered.where((project) =>
        project.category == 'workspace' && project.userId == currentUserId
      ).toList();
    } else if (_selectedCategory == 'shared') {
      // Show projects shared with the user (not created by them, but they're a team member)
      filtered = filtered.where((project) =>
        project.userId != currentUserId && project.teamMembers.contains(_projectManager.getCurrentUserEmail())
      ).toList();
    } else if (_selectedCategory == 'personal') {
      // Show personal projects the user created
      filtered = filtered.where((project) =>
        project.category == 'personal' && project.userId == currentUserId
      ).toList();
    }
    // If 'all', show everything (all accessible projects)

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((project) {
        return project.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            project.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort: pinned projects first, then by creation date (newest first)
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      // Both pinned or both unpinned: sort by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  void _showDeleteConfirmationDialog(Project project) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Project'),
          content: Text('Are you sure you want to delete "${project.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _projectManager.deleteProject(project.id);
                  Navigator.of(context).pop();
                  _loadProjects();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Project "${project.title}" deleted successfully')),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting project: $e')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, String category) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = category;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF1E1E1E),
      checkmarkColor: const Color(0xFFF9ED69),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFF9ED69) : const Color(0xFF1E1E1E),
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1E1E1E) : Colors.grey.shade300,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _getFilteredProjects();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Yellow Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF9ED69),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox.shrink(),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              color: const Color(0xFF1E1E1E),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddProjectPage(),
                                  ),
                                ).then((_) => _loadProjects());
                              },
                            ),
                            IconButton(
                              icon: Icon(_isSearching ? Icons.close : Icons.search),
                              color: const Color(0xFF1E1E1E),
                              onPressed: () {
                                setState(() {
                                  _isSearching = !_isSearching;
                                  if (!_isSearching) {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!_isSearching) ...[
                      Text(
                        'Projects',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E1E1E),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Manage your team projects and tickets',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF1E1E1E).withOpacity(0.7),
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_projects.length} projects',
                              style: const TextStyle(
                                color: Color(0xFFF9ED69),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Category Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryChip('All', 'all'),
                            const SizedBox(width: 8),
                            _buildCategoryChip('Workspace', 'workspace'),
                            const SizedBox(width: 8),
                            _buildCategoryChip('Shared', 'shared'),
                            const SizedBox(width: 8),
                            _buildCategoryChip('Personal', 'personal'),
                          ],
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Color(0xFF1E1E1E),
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search projects...',
                          hintStyle: TextStyle(
                            color: const Color(0xFF1E1E1E).withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Projects List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading projects',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.red.shade400,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProjects,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredProjects.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No projects yet',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your first project to get started',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey.shade500,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AddProjectPage(),
                                      ),
                                    ).then((_) => _loadProjects());
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Project'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF9ED69),
                                    foregroundColor: const Color(0xFF1E1E1E),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppConstants.paddingMedium),
                            itemCount: filteredProjects.length,
                            itemBuilder: (context, index) {
                              final project = filteredProjects[index];
                              return ProjectCard(
                                project: project,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProjectDetailPage(project: project),
                                    ),
                                  ).then((_) => _loadProjects());
                                },
                                onEdit: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddProjectPage(projectToEdit: project),
                                    ),
                                  ).then((_) => _loadProjects());
                                },
                                onDelete: () => _showDeleteConfirmationDialog(project),
                                onPinToggle: () async {
                                  try {
                                    await _projectManager.togglePinProject(project.id, !project.isPinned);
                                    _loadProjects();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(project.isPinned ? 'Project unpinned' : 'Project pinned')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error toggling pin: $e')),
                                    );
                                  }
                                },
                                onStatusChanged: _loadProjects,
                              );
                            },
                          ),
          ),
        ],
      ),
      bottomNavigationBar: Consumer<WishlistProvider>(
        builder: (context, wishlistProvider, _) {
          return FloatingNavBar(
            currentIndex: 2, // Projects is index 2
            onTap: (index) {
              if (index == 2) return; // Already on projects
              Navigator.pushReplacementNamed(context, '/');
            },
            wishlistController: wishlistProvider.isInitialized ? wishlistProvider.controller : null,
          );
        },
      ),
      extendBody: true,
    );
  }
}
