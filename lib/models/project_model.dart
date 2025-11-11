class Project {
  final String id;
  final String title;
  final String description;
  final List<String> teamMembers;
  final String status;
  final int totalTickets;
  final int completedTickets;
  final String color;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.teamMembers,
    required this.status,
    required this.totalTickets,
    required this.completedTickets,
    this.color = 'yellow',
  });

  double get progressPercentage {
    if (totalTickets == 0) return 0.0;
    return (completedTickets / totalTickets) * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'teamMembers': teamMembers,
      'status': status,
      'totalTickets': totalTickets,
      'completedTickets': completedTickets,
      'color': color,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      teamMembers: List<String>.from(map['teamMembers']),
      status: map['status'],
      totalTickets: map['totalTickets'],
      completedTickets: map['completedTickets'],
      color: map['color'] ?? 'yellow',
    );
  }
}