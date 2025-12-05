import 'package:firebase_auth/firebase_auth.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/projects/projects.dart';

class ProjectManager {
  static final ProjectManager _instance = ProjectManager._internal();
  factory ProjectManager() => _instance;
  ProjectManager._internal();

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;
  String? get _currentUserEmail => _auth.currentUser?.email;

  // Public getters for current user info
  String? getCurrentUserId() => _currentUserId;
  String? getCurrentUserEmail() => _currentUserEmail;

  // Get all projects for current user
  Future<List<Project>> getProjects() async {
    if (_currentUserId == null || _currentUserEmail == null) {
      throw Exception('User not authenticated');
    }
    return await _firestoreService.getUserProjects(_currentUserId!, _currentUserEmail!);
  }

  // Get all tickets for current user
  Future<List<Ticket>> getTickets() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }
    return await _firestoreService.getUserTickets(_currentUserId!);
  }

  // Get tickets by project
  Future<List<Ticket>> getTicketsByProject(String projectId) async {
    return await _firestoreService.getProjectTickets(projectId);
  }

  // Get tickets by status for a project
  Future<List<Ticket>> getTicketsByStatus(String projectId, String status) async {
    return await _firestoreService.getProjectTicketsByStatus(projectId, status);
  }

  // Add project
  Future<void> addProject(Project project) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }
    final projectWithUser = project.copyWith(userId: _currentUserId);
    await _firestoreService.createProject(projectWithUser);
  }

  // Add ticket
  Future<void> addTicket(Ticket ticket) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }
    final ticketWithUser = ticket.copyWith(userId: _currentUserId);
    await _firestoreService.createTicket(ticketWithUser);
  }

  // Update ticket (now requires projectId)
  Future<void> updateTicket(String projectId, String ticketNumber, Ticket updatedTicket) async {
    await _firestoreService.updateTicket(projectId, ticketNumber, updatedTicket.toMap());
  }

  // Delete ticket (now requires projectId)
  Future<void> deleteTicket(String projectId, String ticketNumber) async {
    await _firestoreService.deleteTicket(projectId, ticketNumber);
  }

  // Update project
  Future<void> updateProject(Project project) async {
    await _firestoreService.updateProject(project.id, project.toMap());
  }

  // Delete project
  Future<void> deleteProject(String projectId) async {
    await _firestoreService.deleteProject(projectId);
  }

  // Pin/unpin project
  Future<void> togglePinProject(String projectId, bool isPinned) async {
    await _firestoreService.updateProject(projectId, {'isPinned': isPinned});
  }

  // ===== REAL-TIME LISTENERS =====

  // Listen to projects changes
  Stream<List<Project>> listenToProjects() {
    if (_currentUserId == null || _currentUserEmail == null) {
      throw Exception('User not authenticated');
    }
    return _firestoreService.listenToUserProjects(_currentUserId!, _currentUserEmail!);
  }

  // Listen to tickets changes for a project
  Stream<List<Ticket>> listenToProjectTickets(String projectId) {
    return _firestoreService.listenToProjectTickets(projectId);
  }
}
