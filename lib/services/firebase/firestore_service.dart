import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zentry/models/project_model.dart';
import 'package:zentry/models/ticket_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';
  static const String ticketsSubcollection = 'tickets'; // Tickets are now subcollection under projects

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

      // Calculate actual ticket counts for each project
      final projectsWithUpdatedCounts = <Project>[];
      for (final project in allProjects) {
        try {
          // Get tickets for this project
          final ticketsSnapshot = await _db
              .collection(projectsCollection)
              .doc(project.id)
              .collection(ticketsSubcollection)
              .get();

          final tickets = ticketsSnapshot.docs
              .map((doc) => Ticket.fromMap(doc.data()))
              .toList();

          // Count total tickets and completed tickets
          final totalTickets = tickets.length;
          final completedTickets = tickets.where((ticket) => ticket.status == 'done').length;

          // Update project with calculated counts
          final updatedProject = project.copyWith(
            totalTickets: totalTickets,
            completedTickets: completedTickets,
          );

          projectsWithUpdatedCounts.add(updatedProject);
        } catch (e) {
          // If there's an error fetching tickets for this project, use the stored counts
          print('Error fetching tickets for project ${project.id}: $e');
          projectsWithUpdatedCounts.add(project);
        }
      }

      return projectsWithUpdatedCounts;
    } catch (e) {
      throw Exception('Failed to get user projects: $e');
    }
  }

  // Get user projects as a stream for real-time updates
  Stream<List<Project>> getUserProjectsStream(String userId, String userEmail) {
    try {
      // Combine both owned and shared projects streams
      return _db
          .collection(projectsCollection)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .asyncMap((ownedSnapshot) async {
        // Get shared projects
        final sharedSnapshot = await _db
            .collection(projectsCollection)
            .where('teamMembers', arrayContains: userEmail)
            .get();

        final allProjects = <Project>[];

        // Add owned projects
        allProjects.addAll(
          ownedSnapshot.docs.map((doc) => Project.fromMap(doc.data()))
        );

        // Add shared projects (avoid duplicates)
        for (final doc in sharedSnapshot.docs) {
          final project = Project.fromMap(doc.data());
          if (!allProjects.any((p) => p.id == project.id)) {
            allProjects.add(project);
          }
        }

        // Calculate actual ticket counts for each project
        final projectsWithUpdatedCounts = <Project>[];
        for (final project in allProjects) {
          try {
            final ticketsSnapshot = await _db
                .collection(projectsCollection)
                .doc(project.id)
                .collection(ticketsSubcollection)
                .get();

            final tickets = ticketsSnapshot.docs
                .map((doc) => Ticket.fromMap(doc.data()))
                .toList();

            final totalTickets = tickets.length;
            final completedTickets = tickets.where((ticket) => ticket.status == 'done').length;

            final updatedProject = project.copyWith(
              totalTickets: totalTickets,
              completedTickets: completedTickets,
            );

            projectsWithUpdatedCounts.add(updatedProject);
          } catch (e) {
            print('Error fetching tickets for project ${project.id}: $e');
            projectsWithUpdatedCounts.add(project);
          }
        }

        return projectsWithUpdatedCounts;
      });
    } catch (e) {
      throw Exception('Failed to get user projects stream: $e');
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
      // Delete all tickets for this project (now in subcollection)
      final ticketsQuery = await _db
          .collection(projectsCollection)
          .doc(projectId)
          .collection(ticketsSubcollection)
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

  // Create a new ticket (now stored in project subcollection)
  Future<void> createTicket(Ticket ticket) async {
    try {
      await _db
          .collection(projectsCollection)
          .doc(ticket.projectId)
          .collection(ticketsSubcollection)
          .doc(ticket.ticketNumber)
          .set({
        ...ticket.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  // Get all tickets for a user (across all their projects)
  Future<List<Ticket>> getUserTickets(String userId) async {
    try {
      // First get all user projects
      final projectsSnapshot = await _db
          .collection(projectsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final allTickets = <Ticket>[];

      // For each project, get its tickets from subcollection
      for (final projectDoc in projectsSnapshot.docs) {
        final ticketsSnapshot = await projectDoc.reference
            .collection(ticketsSubcollection)
            .get();

        final tickets = ticketsSnapshot.docs
            .map((doc) => Ticket.fromMap(doc.data()))
            .toList();

        allTickets.addAll(tickets);
      }

      return allTickets;
    } catch (e) {
      throw Exception('Failed to get user tickets: $e');
    }
  }

  // Get tickets for a specific project (from subcollection)
  Future<List<Ticket>> getProjectTickets(String projectId) async {
    try {
      final querySnapshot = await _db
          .collection(projectsCollection)
          .doc(projectId)
          .collection(ticketsSubcollection)
          .get();

      return querySnapshot.docs
          .map((doc) => Ticket.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get project tickets: $e');
    }
  }

  // Get tickets by status for a project (from subcollection)
  Future<List<Ticket>> getProjectTicketsByStatus(String projectId, String status) async {
    try {
      final querySnapshot = await _db
          .collection(projectsCollection)
          .doc(projectId)
          .collection(ticketsSubcollection)
          .where('status', isEqualTo: status)
          .get();

      return querySnapshot.docs
          .map((doc) => Ticket.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get project tickets by status: $e');
    }
  }

  // Update a ticket (in project subcollection)
  Future<void> updateTicket(String projectId, String ticketNumber, Map<String, dynamic> data) async {
    try {
      await _db
          .collection(projectsCollection)
          .doc(projectId)
          .collection(ticketsSubcollection)
          .doc(ticketNumber)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update ticket: $e');
    }
  }

  // Delete a ticket (from project subcollection)
  Future<void> deleteTicket(String projectId, String ticketNumber) async {
    try {
      await _db
          .collection(projectsCollection)
          .doc(projectId)
          .collection(ticketsSubcollection)
          .doc(ticketNumber)
          .delete();
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

  // Listen to tickets changes for a project (from subcollection)
  Stream<List<Ticket>> listenToProjectTickets(String projectId) {
    return _db
        .collection(projectsCollection)
        .doc(projectId)
        .collection(ticketsSubcollection)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Ticket.fromMap(doc.data())).toList());
  }
}
