import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:zentry/features/projects/projects.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';
  static const String ticketsSubcollection =
      'tickets'; // Tickets are now subcollection under projects

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
          ownedProjectsQuery.docs.map((doc) => Project.fromMap(doc.data())));

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
          final completedTickets =
              tickets.where((ticket) => ticket.status == 'done').length;

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
      // Create two real-time streams: one for owned, one for shared projects
      final ownedStream = _db
          .collection(projectsCollection)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Project.fromMap(doc.data())).toList());

      final sharedStream = _db
          .collection(projectsCollection)
          .where('teamMembers', arrayContains: userEmail)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Project.fromMap(doc.data())).toList());

      // Merge both streams and calculate ticket counts
      return Stream.multi((controller) {
        late StreamSubscription<List<Project>> ownedSub;
        late StreamSubscription<List<Project>> sharedSub;
        
        List<Project>? lastOwned;
        List<Project>? lastShared;
        
        Future<void> emitCombined() async {
          try {
            final owned = lastOwned ?? [];
            final shared = lastShared ?? [];
            
            final allProjects = <Project>[];
            allProjects.addAll(owned);
            
            // Add shared projects (only if user has accepted the invitation)
            for (final project in shared) {
              if (!allProjects.any((p) => p.id == project.id)) {
                // Check if user has accepted this invitation
                final userTeamMember = project.teamMemberDetails
                    .firstWhere(
                      (member) => member.email == userEmail,
                      orElse: () => TeamMember(
                        email: userEmail,
                        status: 'pending',
                      ),
                    );
                
                // Only include if user has accepted
                if (userTeamMember.isAccepted) {
                  allProjects.add(project);
                }
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
                final completedTickets =
                    tickets.where((ticket) => ticket.status == 'done').length;

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
            
            controller.add(projectsWithUpdatedCounts);
          } catch (e) {
            controller.addError(e);
          }
        }
        
        ownedSub = ownedStream.listen(
          (projects) {
            lastOwned = projects;
            emitCombined();
          },
          onError: controller.addError,
        );
        
        sharedSub = sharedStream.listen(
          (projects) {
            lastShared = projects;
            emitCombined();
          },
          onError: controller.addError,
        );
        
        controller.onCancel = () {
          ownedSub.cancel();
          sharedSub.cancel();
        };
      });
    } catch (e) {
      throw Exception('Failed to get user projects stream: $e');
    }
  }

  // Get a single project by ID
  Future<Project?> getProjectById(String projectId) async {
    try {
      final doc = await _db.collection(projectsCollection).doc(projectId).get();
      if (!doc.exists) return null;

      final project = Project.fromMap(doc.data()!);

      // Get actual ticket counts
      final ticketsSnapshot = await _db
          .collection(projectsCollection)
          .doc(projectId)
          .collection(ticketsSubcollection)
          .get();

      final tickets = ticketsSnapshot.docs
          .map((doc) => Ticket.fromMap(doc.data()))
          .toList();

      final totalTickets = tickets.length;
      final completedTickets =
          tickets.where((t) => t.status == 'Completed').length;

      return project.copyWith(
        totalTickets: totalTickets,
        completedTickets: completedTickets,
      );
    } catch (e) {
      throw Exception('Failed to get project: $e');
    }
  }

  // Update a project
  Future<void> updateProject(
      String projectId, Map<String, dynamic> data) async {
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

  // ===== PROJECT INVITATION OPERATIONS =====

  /// Accept a project invitation
  Future<void> acceptProjectInvitation(
      String projectId, String userEmail) async {
    try {
      final projectRef = _db.collection(projectsCollection).doc(projectId);
      final projectDoc = await projectRef.get();

      if (!projectDoc.exists) {
        throw Exception('Project not found');
      }

      final projectData = projectDoc.data()!;
      final teamMemberDetails = (projectData['teamMemberDetails'] as List?)
              ?.map((m) => Map<String, dynamic>.from(m as Map))
              .toList() ??
          [];

      // Find and update the member's status
      final memberIndex =
          teamMemberDetails.indexWhere((m) => m['email'] == userEmail);
      if (memberIndex != -1) {
        teamMemberDetails[memberIndex]['status'] = 'accepted';
        teamMemberDetails[memberIndex]['respondedAt'] =
            DateTime.now().toIso8601String();

        await projectRef.update({
          'teamMemberDetails': teamMemberDetails,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception('Invitation not found');
      }
    } catch (e) {
      throw Exception('Failed to accept invitation: $e');
    }
  }

  /// Reject a project invitation
  Future<void> rejectProjectInvitation(
      String projectId, String userEmail) async {
    try {
      final projectRef = _db.collection(projectsCollection).doc(projectId);
      final projectDoc = await projectRef.get();

      if (!projectDoc.exists) {
        throw Exception('Project not found');
      }

      final projectData = projectDoc.data()!;
      final teamMemberDetails = (projectData['teamMemberDetails'] as List?)
              ?.map((m) => Map<String, dynamic>.from(m as Map))
              .toList() ??
          [];

      // Remove the member from the list
      teamMemberDetails.removeWhere((m) => m['email'] == userEmail);

      // Also remove from legacy teamMembers array
      final teamMembers = List<String>.from(projectData['teamMembers'] ?? []);
      teamMembers.remove(userEmail);

      // Remove the member from all roles they are assigned to
      final roles = (projectData['roles'] as List?)
              ?.map((r) => Map<String, dynamic>.from(r as Map))
              .toList() ??
          [];

      for (var role in roles) {
        final members = List<String>.from(role['members'] ?? []);
        members.remove(userEmail);
        role['members'] = members;
      }

      await projectRef.update({
        'teamMembers': teamMembers,
        'teamMemberDetails': teamMemberDetails,
        'roles': roles,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject invitation: $e');
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
        final ticketsSnapshot =
            await projectDoc.reference.collection(ticketsSubcollection).get();

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
  Future<List<Ticket>> getProjectTicketsByStatus(
      String projectId, String status) async {
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
  Future<void> updateTicket(
      String projectId, String ticketNumber, Map<String, dynamic> data) async {
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
    // Create two real-time streams: one for owned, one for shared projects
    // This ensures both are updated immediately when projects are created or shared
    
    final ownedStream = _db
        .collection(projectsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Project.fromMap(doc.data())).toList());

    final sharedStream = _db
        .collection(projectsCollection)
        .where('teamMembers', arrayContains: userEmail)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Project.fromMap(doc.data())).toList());

    // Merge both streams using mergeMap-like behavior
    // Listen to both streams and emit combined results whenever either changes
    return Stream.multi((controller) {
      late StreamSubscription<List<Project>> ownedSub;
      late StreamSubscription<List<Project>> sharedSub;
      
      List<Project>? lastOwned;
      List<Project>? lastShared;
      
      void emitCombined() {
        final owned = lastOwned ?? [];
        final shared = lastShared ?? [];
        
        final allProjects = <Project>[];
        allProjects.addAll(owned);
        
        // Add shared projects (only if user has accepted the invitation)
        for (final project in shared) {
          if (!allProjects.any((p) => p.id == project.id)) {
            // Check if user has accepted this invitation
            final userTeamMember = project.teamMemberDetails
                .firstWhere(
                  (member) => member.email == userEmail,
                  orElse: () => TeamMember(
                    email: userEmail,
                    status: 'pending',
                  ),
                );
            
            // Only include if user has accepted
            if (userTeamMember.isAccepted) {
              allProjects.add(project);
            }
          }
        }
        
        controller.add(allProjects);
      }
      
      ownedSub = ownedStream.listen(
        (projects) {
          lastOwned = projects;
          emitCombined();
        },
        onError: controller.addError,
      );
      
      sharedSub = sharedStream.listen(
        (projects) {
          lastShared = projects;
          emitCombined();
        },
        onError: controller.addError,
      );
      
      controller.onCancel = () {
        ownedSub.cancel();
        sharedSub.cancel();
      };
    });
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

  // Listen to all tickets for a user across all their projects
  // This combines tickets from all projects the user owns or is a member of
  Stream<List<Ticket>> listenToUserTickets(String userId, String userEmail) {
    // Controller to emit combined tickets
    final controller = StreamController<List<Ticket>>();
    
    // Track subscriptions to cancel them
    StreamSubscription<List<Project>>? projectsSub;
    final ticketSubs = <String, StreamSubscription<List<Ticket>>>{};
    final projectTickets = <String, List<Ticket>>{}; // Cache tickets by projectId

    // Helper to emit current state
    void emit() {
      if (controller.isClosed) return;
      final all = projectTickets.values.expand((x) => x).toList();
      controller.add(all);
    }

    // Listen to projects
    projectsSub = getUserProjectsStream(userId, userEmail).listen((projects) {
      // Identify projects that were removed
      final currentIds = projects.map((p) => p.id).toSet();
      final removedIds = ticketSubs.keys.where((id) => !currentIds.contains(id)).toList();

      // Cancel removed subscriptions
      for (final id in removedIds) {
        ticketSubs[id]?.cancel();
        ticketSubs.remove(id);
        projectTickets.remove(id);
      }

      // Add new subscriptions
      for (final project in projects) {
        if (!ticketSubs.containsKey(project.id)) {
          ticketSubs[project.id] = listenToProjectTickets(project.id).listen((tickets) {
            projectTickets[project.id] = tickets;
            emit();
          });
        }
      }
      
      // Emit immediately if we have cached data
      // Note: New projects will emit when their ticket stream sends first event
      if (projectTickets.isNotEmpty || projects.isEmpty) {
        emit();
      }
    });

    controller.onCancel = () {
      projectsSub?.cancel();
      for (final sub in ticketSubs.values) {
        sub.cancel();
      }
    };

    return controller.stream;
  }
}
