class ProjectRole {
  final String name;
  final List<String> members; // List of email addresses

  ProjectRole({
    required this.name,
    required this.members,
  });

  ProjectRole copyWith({
    String? name,
    List<String>? members,
  }) {
    return ProjectRole(
      name: name ?? this.name,
      members: members ?? this.members,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'members': members,
    };
  }

  // Create from Firestore Map
  factory ProjectRole.fromMap(Map<String, dynamic> map) {
    return ProjectRole(
      name: map['name'] ?? '',
      members: List<String>.from(map['members'] ?? []),
    );
  }

  @override
  String toString() => 'ProjectRole(name: $name, members: $members)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectRole &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          members == other.members;

  @override
  int get hashCode => name.hashCode ^ members.hashCode;
}
