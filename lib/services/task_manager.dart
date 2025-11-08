// Global task manager to share data between screens
class TaskManager {
  static final TaskManager _instance = TaskManager._internal();
  factory TaskManager() => _instance;
  TaskManager._internal();

  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'Complete the final documentation',
      'description': 'Complete slides and practice delivery',
      'time': '10:30 AM',
      'priority': 'high',
      'isDone': false,
      'assignedTo': 'John Doe',
    },
    {
      'title': 'Review pull request #342',
      'description': 'Review authentication module',
      'time': '2:00 PM',
      'priority': 'medium',
      'isDone': false,
      'assignedTo': 'Sarah Lee',
    },
    {
      'title': 'Update server dependencies',
      'description': 'Q4 planning and milestones',
      'time': 'Tomorrow',
      'priority': 'medium',
      'isDone': false,
      'assignedTo': 'You',
    },
    {
      'title': 'Buy groceries',
      'description': 'Milk, eggs, bread, vegetables',
      'time': '4:30 PM',
      'priority': 'medium',
      'isDone': false,
      'assignedTo': null,
    },
    {
      'title': 'Call dentist',
      'description': null,
      'time': 'Tomorrow',
      'priority': 'low',
      'isDone': false,
      'assignedTo': null,
    },
    {
      'title': 'Team meeting preparation',
      'description': 'Prepare agenda and materials',
      'time': '2:00 PM',
      'priority': 'medium',
      'isDone': false,
      'assignedTo': null,
    },
    {
      'title': 'Code review - Feature branch',
      'description': 'Review authentication module',
      'time': '11:00 AM',
      'priority': 'low',
      'isDone': false,
      'assignedTo': null,
    },
    {
      'title': 'Update project roadmap',
      'description': 'Q4 planning and milestones',
      'time': '3:30 PM',
      'priority': 'medium',
      'isDone': false,
      'assignedTo': null,
    },
    {
      'title': 'Client call',
      'description': 'Discuss requirements and timeline',
      'time': '4:00 PM',
      'priority': 'high',
      'isDone': false,
      'assignedTo': null,
    },
    {
      'title': 'Workout session',
      'description': 'Gym - upper body routine',
      'time': '6:00 AM',
      'priority': 'medium',
      'isDone': true,
      'assignedTo': null,
    },
  ];

  List<Map<String, dynamic>> get tasks => _tasks;

  List<Map<String, dynamic>> get sharedTasks =>
      _tasks.where((task) => task['assignedTo'] != null).toList();

  List<Map<String, dynamic>> get personalTasks =>
      _tasks.where((task) => task['assignedTo'] == null).toList();

  int get doneToday =>
      _tasks.where((task) => task['isDone'] == true).length;

  int get pendingToday =>
      _tasks.where((task) => task['isDone'] == false && task['time'] != 'Tomorrow').length;

  int get totalTasks => _tasks.length;

  void addTask(Map<String, dynamic> task) {
    _tasks.add(task);
  }

  void removeTask(Map<String, dynamic> task) {
    _tasks.remove(task);
  }

  void updateTask(Map<String, dynamic> task, Map<String, dynamic> updates) {
    final index = _tasks.indexOf(task);
    if (index != -1) {
      _tasks[index] = {...task, ...updates};
    }
  }
}