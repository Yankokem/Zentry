import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/projects/projects.dart';

  class TasksPage extends StatefulWidget {
    const TasksPage({super.key});

    @override
    State<TasksPage> createState() => _TasksPageState();
  }

  class _TasksPageState extends State<TasksPage> with SingleTickerProviderStateMixin {
    late TabController _tabController;
    String _searchQuery = '';
    bool _isSearching = false;
    final TextEditingController _searchController = TextEditingController();
    final TaskManager _taskManager = TaskManager();
    
    @override
    void initState() {
      super.initState();
      _tabController = TabController(length: 3, vsync: this);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Color(0xFFF9ED69),
          statusBarIconBrightness: Brightness.dark,
        ),
      );
    }
    
    @override
    void dispose() {
      _tabController.dispose();
      _searchController.dispose();
      super.dispose();
    }

    List<Task> _getFilteredTasks() {
      if (_searchQuery.isEmpty) return _taskManager.tasks;
      return _taskManager.tasks.where((task) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (task.description != null &&
                task.description!.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
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
      final filteredTasks = _getFilteredTasks();
      
      return Scaffold(
        backgroundColor: const Color(0xFFF9ED69),
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
                              IconButton(
                                icon: const Icon(Icons.add),
                                color: const Color(0xFF1E1E1E),
                                onPressed: () {
                                  _showAddTaskDialog();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!_isSearching) ...[
                        Text(
                          'My Tasks',
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
                                'Let\'s make a productive day today',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF1E1E1E).withOpacity(0.7),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_taskManager.tasks.where((t) => !t.isDone).length} active',
                                style: const TextStyle(
                                  color: Color(0xFFF9ED69),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1E1E1E).withOpacity(0.1),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(
                              color: Color(0xFF1E1E1E),
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search tasks...',
                              hintStyle: TextStyle(
                                color: const Color(0xFF1E1E1E).withOpacity(0.5),
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF1E1E1E),
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Color(0xFF1E1E1E),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isSearching = false;
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            // Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF1E1E1E),
                  unselectedLabelColor: Colors.grey.shade500,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  indicator: BoxDecoration(
                    color: const Color(0xFFF9ED69),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF9ED69).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(
                      height: 40,
                      child: Center(child: Text('All')),
                    ),
                    Tab(
                      height: 40,
                      child: Center(child: Text('Active')),
                    ),
                    Tab(
                      height: 40,
                      child: Center(child: Text('Completed')),
                    ),
                  ],
                ),
              ),
            ),
            
            // Tab Content
            Expanded(
              child: Container(
                color: Colors.grey.shade100,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskListByDate(filteredTasks),
                    _buildTaskListByDate(filteredTasks.where((task) => !task.isDone).toList()),
                    _buildTaskListByDate(filteredTasks.where((task) => task.isDone).toList()),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildTaskListByDate(List<Task> tasks) {
      if (tasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchQuery.isNotEmpty ? Icons.search_off : Icons.check_circle_outline,
                size: 80,
                color: Colors.grey.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty ? 'No tasks found' : 'No tasks here',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try a different search term'
                    : 'Add a new task to get started',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        );
      }

      // Group tasks by date
      Map<String, List<Task>> groupedTasks = {
        'Today': [],
        'Tomorrow': [],
        'Completed': [],
      };

      for (var task in tasks) {
        if (task.isDone == true) {
          groupedTasks['Completed']!.add(task);
        } else if (task.time == 'Tomorrow') {
          groupedTasks['Tomorrow']!.add(task);
        } else {
          groupedTasks['Today']!.add(task);
        }
      }

      return ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          if (groupedTasks['Today']!.isNotEmpty) ...[
            _buildDateHeader('Today', groupedTasks['Today']!.length),
            ...groupedTasks['Today']!.map((task) => _buildTaskCard(task)),
            const SizedBox(height: 16),
          ],
          if (groupedTasks['Tomorrow']!.isNotEmpty) ...[
            _buildDateHeader('Tomorrow', groupedTasks['Tomorrow']!.length),
            ...groupedTasks['Tomorrow']!.map((task) => _buildTaskCard(task)),
            const SizedBox(height: 16),
          ],
          if (groupedTasks['Completed']!.isNotEmpty) ...[
            _buildDateHeader('Completed', groupedTasks['Completed']!.length),
            ...groupedTasks['Completed']!.map((task) => _buildTaskCard(task)),
          ],
        ],
      );
    }

    Widget _buildDateHeader(String title, int count) {
      return Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildTaskCard(Task task) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Dismissible(
          key: Key(task.title + task.time + DateTime.now().toString()),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Task'),
                content: const Text('Are you sure you want to delete this task?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            setState(() {
              _taskManager.removeTask(task);
            });
            _showSuccessDialog('Task Deleted', 'Task deleted');
          },
          child: InkWell(
            onTap: () => _showTaskDetails(task),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _taskManager.updateTask(task, task.copyWith(isDone: !task.isDone));
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.isDone
                              ? Colors.yellow.shade700
                              : Colors.grey.shade400,
                          width: 2.5,
                        ),
                        color: task.isDone
                            ? Colors.yellow.shade700
                            : Colors.transparent,
                      ),
                      child: task.isDone
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Priority indicator bar
                  Container(
                    width: 4,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E1E),
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.time,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(task.priority).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                task.priority.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getPriorityColor(task.priority),
                                ),
                              ),
                            ),
                            if (task.assignedTo != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  task.assignedTo!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: Colors.grey.shade600,
                    onPressed: () {
                      _showEditTaskDialog(task);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Color _getPriorityColor(String priority) {
      switch (priority) {
        case 'high':
          return Colors.red.shade400;
        case 'medium':
          return Colors.purple.shade300;
        case 'low':
          return Colors.green.shade400;
        default:
          return Colors.grey;
      }
    }

    void _showTaskDetails(Task task) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.access_time, 'Time', task.time),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.flag_outlined, 'Priority', task.priority.toUpperCase()),
              if (task.assignedTo != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow(Icons.person_outline, 'Assigned To', task.assignedTo!),
              ],
              if (task.description != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow(Icons.description_outlined, 'Description', task.description!),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditTaskDialog(task);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9ED69),
                        foregroundColor: const Color(0xFF1E1E1E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _taskManager.updateTask(task, task.copyWith(isDone: !task.isDone));
                        });
                        Navigator.pop(context);
                      },
                      icon: Icon(task.isDone ? Icons.undo : Icons.check),
                      label: Text(task.isDone ? 'Undo' : 'Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      );
    }

    Widget _buildDetailRow(IconData icon, String label, String value) {
      return Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    void _showEditTaskDialog(Task task) {
      final titleController = TextEditingController(text: task.title);
      final descController = TextEditingController(text: task.description ?? '');
      final assignedToController = TextEditingController(text: task.assignedTo ?? '');
      String selectedPriority = task.priority;
      String selectedTime = task.time;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Edit Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: assignedToController,
                    decoration: const InputDecoration(
                      labelText: 'Assigned To (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Leave empty for personal task',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedPriority = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: selectedTime),
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () async {
                      if (selectedTime == 'Tomorrow') {
                        return;
                      }
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setDialogState(() {
                          selectedTime = time.format(context);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    setState(() {
                      _taskManager.updateTask(task, task.copyWith(
                        title: titleController.text,
                        description: descController.text.isEmpty ? null : descController.text,
                        assignedTo: assignedToController.text.isEmpty ? null : assignedToController.text,
                        time: selectedTime,
                        priority: selectedPriority,
                      ));
                    });
                    Navigator.pop(context);
                    _showSuccessDialog('Task Updated', 'Task updated');
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
    }

    void _showAddTaskDialog() {
      final titleController = TextEditingController();
      final descController = TextEditingController();
      final assignedToController = TextEditingController();
      String selectedPriority = 'medium';
      TimeOfDay selectedTime = TimeOfDay.now();

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('New Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: assignedToController,
                    decoration: const InputDecoration(
                      labelText: 'Assigned To (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Leave empty for personal task',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedPriority = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Time'),
                    subtitle: Text(selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setDialogState(() {
                          selectedTime = time;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    setState(() {
                      _taskManager.addTaskFromMap({
                        'title': titleController.text,
                        'description': descController.text.isEmpty ? null : descController.text,
                        'assignedTo': assignedToController.text.isEmpty ? null : assignedToController.text,
                        'time': selectedTime.format(context),
                        'priority': selectedPriority,
                        'isDone': false,
                      });
                    });
                    Navigator.pop(context);
                    _showSuccessDialog('Task Added', 'Task added');
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      );
    }
  }