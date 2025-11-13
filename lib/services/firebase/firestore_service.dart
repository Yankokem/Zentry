import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zentry/models/project_model.dart';
import 'package:zentry/models/ticket_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';
  static const String ticketsCollection = 'tickets';

  // Store user data in Firestore after signup
  Future<void> createUserDocument({
    required String uid,
    required String firstName,
    required String lastName,
    required String fullName,
    required String email,
  }) async {
    try {
      await _db.collection(usersCollection).doc(uid).set({
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName, 
        'fullName': fullName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  // Store Google user data in Firestore after Google sign-in
  Future<void> createGoogleUserDocument(User user) async {
    try {
      // Extract name from Google user
      final displayName = user.displayName ?? '';
      final nameParts = displayName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final fullName = displayName.isEmpty ? 'Google User' : displayName;

      // Check if user document already exists
      final docExists =
          await _db.collection(usersCollection).doc(user.uid).get();

      if (!docExists.exists) {
        // Create new user document for Google sign-in
        await _db.collection(usersCollection).doc(user.uid).set({
          'uid': user.uid,
          'firstName': firstName,
          'lastName': lastName,
          'fullName': fullName,
          'email': user.email?.toLowerCase() ?? '',
          'photoUrl': user.photoURL ?? '',
          'authProvider': 'google',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Document already exists - no action needed
      }
    } catch (e) {
      throw Exception('Failed to create Google user document: $e');
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db.collection(usersCollection).doc(uid).get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to retrieve user data: $e');
    }
  }

  // Check if user exists in Firestore by email
  Future<bool> userExistsByEmail(String email) async {
    try {
      final query = await _db
          .collection(usersCollection)
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      // If there's an error, throw it so callers can handle it
      throw Exception('Failed to check user existence: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection(usersCollection).doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Delete user document
  Future<void> deleteUserDocument(String uid) async {
    try {
      await _db.collection(usersCollection).doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user document: $e');
    }
  }

  // ===== PROJECT OPERATIONS =====

  // Create a new project
  Future<void> createProject(Project project) async {
    try {
      await _db.collection(projectsCollection).doc(project.id).set({
        ...project.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  // Get all projects for a user (both owned and shared)
  Future<List<Project>> getUserProjects(String userId, String userEmail) async {
    try {
      // Get owned projects
      final ownedProjectsQuery = await _db
          .collection(projectsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      // Get shared projects where user email is in teamMembers
      final sharedProjectsQuery = await _db
          .collection(projectsCollection)
          .where('teamMembers', arrayContains: userEmail)
          .get();

      // Combine and deduplicate projects
      final allProjects = <Project>[];

      // Add owned projects
      allProjects.addAll(
        ownedProjectsQuery.docs.map((doc) => Project.fromMap(doc.data()))
      );

      // Add shared projects (avoid duplicates)
      for (final doc in sharedProjectsQuery.docs) {
        final project = Project.fromMap(doc.data());
        if (!allProjects.any((p) => p.id == project.id)) {
          allProjects.add(project);
        }
      }

      return allProjects;
    } catch (e) {
      throw Exception('Failed to get user projects: $e');
    }
  }

  // Update a project
  Future<void> updateProject(String projectId, Map<String, dynamic> data) async {
    try {
      await _db.collection(projectsCollection).doc(projectId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  // Delete a project
  Future<void> deleteProject(String projectId) async {
    try {
      // Delete all tickets for this project first
      final ticketsQuery = await _db
          .collection(ticketsCollection)
          .where('projectId', isEqualTo: projectId)
          .get();

      final batch = _db.batch();
      for (final doc in ticketsQuery.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_db.collection(projectsCollection).doc(projectId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  // ===== TICKET OPERATIONS =====

  // Create a new ticket
  Future<void> createTicket(Ticket ticket) async {
    try {
      await _db.collection(ticketsCollection).doc(ticket.ticketNumber).set({
        ...ticket.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  // Get all tickets for a user
  Future<List<Ticket>> getUserTickets(String userId) async {
    try {
      final querySnapshot = await _db
          .collection(ticketsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => Ticket.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user tickets: $e');
    }
  }

  // Get tickets for a specific project
  Future<List<Ticket>> getProjectTickets(String projectId) async {
    try {
      final querySnapshot = await _db
          .collection(ticketsCollection)
          .where('projectId', isEqualTo: projectId)
          .get();

      return querySnapshot.docs
          .map((doc) => Ticket.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get project tickets: $e');
    }
  }

  // Get tickets by status for a project
  Future<List<Ticket>> getProjectTicketsByStatus(String projectId, String status) async {
    try {
      final querySnapshot = await _db
          .collection(ticketsCollection)
          .where('projectId', isEqualTo: projectId)
          .where('status', isEqualTo: status)
          .get();

      return querySnapshot.docs
          .map((doc) => Ticket.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get project tickets by status: $e');
    }
  }

  // Update a ticket
  Future<void> updateTicket(String ticketNumber, Map<String, dynamic> data) async {
    try {
      await _db.collection(ticketsCollection).doc(ticketNumber).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update ticket: $e');
    }
  }

  // Delete a ticket
  Future<void> deleteTicket(String ticketNumber) async {
    try {
      await _db.collection(ticketsCollection).doc(ticketNumber).delete();
    } catch (e) {
      throw Exception('Failed to delete ticket: $e');
    }
  }

  // ===== REAL-TIME LISTENERS =====

  // Listen to projects changes (both owned and shared)
  Stream<List<Project>> listenToUserProjects(String userId, String userEmail) {
    // For real-time listeners, we need to combine two streams
    // This is a simplified version - in production, you might want to use a more sophisticated approach
    return _db
        .collection(projectsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Project.fromMap(doc.data())).toList());
  }

  // Listen to tickets changes for a project
  Stream<List<Ticket>> listenToProjectTickets(String projectId) {
    return _db
        .collection(ticketsCollection)
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Ticket.fromMap(doc.data())).toList());
  }
}
