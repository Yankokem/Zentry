import '../models/task_model.dart';

// Global task manager to share data between screens
class TaskManager {
  static final TaskManager _instance = TaskManager._internal();
  factory TaskManager() => _instance;
  TaskManager._internal();

  final List<Task> _tasks = [
    Task(
      title: 'Complete the final documentation',
      description: 'Complete slides and practice delivery',
      time: '10:30 AM',
      priority: 'high',
      isDone: false,
      assignedTo: 'John Doe',
    ),
    Task(
      title: 'Review pull request #342',
      description: 'Review authentication module',
      time: '2:00 PM',
      priority: 'medium',
      isDone: false,
      assignedTo: 'Sarah Lee',
    ),
    Task(
      title: 'Update server dependencies',
      description: 'Q4 planning and milestones',
      time: 'Tomorrow',
      priority: 'medium',
      isDone: false,
      assignedTo: 'You',
    ),
    Task(
      title: 'Buy groceries',
      description: 'Milk, eggs, bread, vegetables',
      time: '4:30 PM',
      priority: 'medium',
      isDone: false,
    ),
    Task(
      title: 'Call dentist',
      time: 'Tomorrow',
      priority: 'low',
      isDone: false,
    ),
    Task(
      title: 'Team meeting preparation',
      description: 'Prepare agenda and materials',
      time: '2:00 PM',
      priority: 'medium',
      isDone: false,
    ),
    Task(
      title: 'Code review - Feature branch',
      description: 'Review authentication module',
      time: '11:00 AM',
      priority: 'low',
      isDone: false,
    ),
    Task(
      title: 'Update project roadmap',
      description: 'Q4 planning and milestones',
      time: '3:30 PM',
      priority: 'medium',
      isDone: false,
    ),
    Task(
      title: 'Client call',
      description: 'Discuss requirements and timeline',
      time: '4:00 PM',
      priority: 'high',
      isDone: false,
    ),
    Task(
      title: 'Workout session',
      description: 'Gym - upper body routine',
      time: '6:00 AM',
      priority: 'medium',
      isDone: true,
    ),
  ];

  List<Task> get tasks => _tasks;

  List<Task> get sharedTasks =>
      _tasks.where((task) => task.assignedTo != null).toList();

  List<Task> get personalTasks =>
      _tasks.where((task) => task.assignedTo == null).toList();

  int get doneToday =>
      _tasks.where((task) => task.isDone == true).length;

  int get pendingToday =>
      _tasks.where((task) => task.isDone == false && task.time != 'Tomorrow').length;

  int get totalTasks => _tasks.length;

  void addTask(Task task) {
    _tasks.add(task);
  }

  void removeTask(Task task) {
    _tasks.remove(task);
  }

  void updateTask(Task task, Task updates) {
    final index = _tasks.indexOf(task);
    if (index != -1) {
      _tasks[index] = updates;
    }
  }

  // For backward compatibility with existing code that uses Maps
  List<Map<String, dynamic>> get tasksAsMaps => _tasks.map((task) => task.toMap()).toList();

  void addTaskFromMap(Map<String, dynamic> taskMap) {
    _tasks.add(Task.fromMap(taskMap));
  }

  void removeTaskFromMap(Map<String, dynamic> taskMap) {
    final task = Task.fromMap(taskMap);
    _tasks.remove(task);
  }
}
