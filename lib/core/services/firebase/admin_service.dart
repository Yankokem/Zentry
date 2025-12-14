import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zentry/features/admin/services/admin_notification_service.dart';

class AdminService {
  static const String adminEmail = 'zentry_admin@zentry.app.com';
  static const String adminPassword = 'zentryAdmin12345-';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if the current user is an admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Check if email matches admin email
    return user.email?.toLowerCase() == adminEmail.toLowerCase();
  }

  /// Check if current user is admin synchronously (for UI checks)
  bool isAdminSync() {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.email?.toLowerCase() == adminEmail.toLowerCase();
  }

  /// Initialize admin account - should be called once during app setup
  /// This creates the admin user in Firebase Auth and stores metadata in Firestore
  ///
  /// Security Note: This requires Firestore rules to allow the admin email
  /// to access the 'admins' collection. See firestore.rules for configuration.
  Future<void> initializeAdminAccount() async {
    try {
      // Check if admin already exists in Firestore
      // This requires the admin user to be authenticated first
      final adminDoc =
          await _firestore.collection('admins').doc('system_admin').get();

      if (adminDoc.exists) {
        print('Admin account already initialized');
        return;
      }

      // Try to sign in with admin credentials first
      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        print('Admin account exists, updating metadata');
      } catch (e) {
        // Admin doesn't exist, create it
        print('Creating new admin account');
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );

        // Update display name
        await userCredential.user?.updateDisplayName('Zentry Admin');
      }

      if (userCredential.user != null) {
        await _firestore.collection('admins').doc('system_admin').set({
          'uid': userCredential.user!.uid,
          'email': adminEmail,
          'firstName': 'Zentry',
          'lastName': 'Admin',
          'fullName': 'Zentry Admin',
          'role': 'system_administrator',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'permissions': [
            'view_all_users',
            'manage_bug_reports',
            'view_analytics',
            'manage_content',
            'system_admin'
          ],
        });

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'firstName': 'Zentry',
          'lastName': 'Admin',
          'fullName': 'Zentry Admin',
          'email': adminEmail,
          'role': 'admin',
          'isAdmin': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('Admin account initialized successfully');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        print('Error initializing admin account: Permission denied. '
            'Please check Firestore security rules allow admin email access to admins collection.');
      } else {
        print('Error initializing admin account: ${e.code} - ${e.message}');
      }
    } catch (e) {
      print('Error initializing admin account: $e');
    }
  }

  /// Update last login time for admin
  Future<void> updateAdminLastLogin() async {
    if (await isAdmin()) {
      try {
        await _firestore.collection('admins').doc('system_admin').update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating admin last login: $e');
      }
    }
  }

  /// Get admin metadata
  Future<Map<String, dynamic>?> getAdminMetadata() async {
    if (!await isAdmin()) return null;

    try {
      final doc =
          await _firestore.collection('admins').doc('system_admin').get();
      return doc.data();
    } catch (e) {
      print('Error getting admin metadata: $e');
      return null;
    }
  }

  /// Verify admin access for protected routes
  Future<bool> verifyAdminAccess() async {
    final isAdminUser = await isAdmin();
    if (isAdminUser) {
      await updateAdminLastLogin();
    }
    return isAdminUser;
  }

  // ===== USER MANAGEMENT METHODS =====

  static const String userMetadataCollection = 'user_metadata';
  static const String journalCollection = 'journal_entries';
  static const String wishlistCollection = 'wishlists';
  static const String projectsCollection = 'projects';
  static const String usersCollection = 'users';

  /// Get all users with their metadata
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final usersSnapshot = await _firestore.collection(usersCollection).get();
      
      final users = <Map<String, dynamic>>[];
      
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        
        // Get metadata for this user
        final metadataDoc = await _firestore
            .collection(userMetadataCollection)
            .doc(userDoc.id)
            .get();
        
        final metadata = metadataDoc.exists ? metadataDoc.data()! : {};
        
        // Combine user data with metadata
        users.add({
          'id': userDoc.id,
          'uid': userData['uid'] ?? userDoc.id,
          'name': userData['fullName'] ?? 'Unknown User',
          'firstName': userData['firstName'] ?? '',
          'lastName': userData['lastName'] ?? '',
          'email': userData['email'] ?? '',
          'profileImageUrl': userData['profileImageUrl'],
          'phoneNumber': userData['phoneNumber'],
          'country': userData['country'],
          'role': userData['role'] ?? 'member',
          'status': metadata['status'] ?? 'active',
          'lastActive': metadata['lastActive'] != null
              ? _formatLastActive((metadata['lastActive'] as Timestamp).toDate())
              : 'Never',
          'lastActiveDateTime': metadata['lastActive'] != null
              ? (metadata['lastActive'] as Timestamp).toDate()
              : null,
          'suspensionReason': metadata['suspensionReason'],
          'suspensionDuration': metadata['suspensionDuration'],
          'suspensionStartDate': metadata['suspensionStartDate'],
          'banReason': metadata['banReason'],
          'createdAt': userData['createdAt'],
        });
      }
      
      return users;
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Get user statistics for detail view
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      // Get user data
      final userDoc = await _firestore.collection(usersCollection).doc(userId).get();
      final userData = userDoc.data() ?? {};
      
      // Get metadata
      final metadataDoc = await _firestore.collection(userMetadataCollection).doc(userId).get();
      final metadata = metadataDoc.exists ? metadataDoc.data()! : {};
      
      // Count journal entries
      final journalSnapshot = await _firestore
          .collection(journalCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      // Count wishlists
      final wishlistSnapshot = await _firestore
          .collection(wishlistCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      // Count shared wishlists
      final sharedWishlistSnapshot = await _firestore
          .collection(wishlistCollection)
          .where('sharedWith', arrayContains: userData['email'] ?? '')
          .get();
      
      // Count projects (owned)
      final projectsSnapshot = await _firestore
          .collection(projectsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      // Count shared projects
      final sharedProjectsSnapshot = await _firestore
          .collection(projectsCollection)
          .where('teamMembers', arrayContains: userData['email'] ?? '')
          .get();
      
      // Count tickets across all projects
      int totalTickets = 0;
      for (final projectDoc in projectsSnapshot.docs) {
        final ticketsSnapshot = await _firestore
            .collection(projectsCollection)
            .doc(projectDoc.id)
            .collection('tickets')
            .get();
        totalTickets += ticketsSnapshot.docs.length;
      }
      
      return {
        'id': userId,
        'uid': userData['uid'] ?? userId,
        'name': userData['fullName'] ?? 'Unknown User',
        'firstName': userData['firstName'] ?? '',
        'lastName': userData['lastName'] ?? '',
        'email': userData['email'] ?? '',
        'profileImageUrl': userData['profileImageUrl'],
        'phoneNumber': userData['phoneNumber'],
        'country': userData['country'],
        'role': userData['role'] ?? 'member',
        'status': metadata['status'] ?? 'active',
        'lastActive': metadata['lastActive'] != null
            ? (metadata['lastActive'] as Timestamp).toDate()
            : null,
        'lastActiveFormatted': metadata['lastActive'] != null
            ? _formatLastActive((metadata['lastActive'] as Timestamp).toDate())
            : 'Never',
        'createdAt': userData['createdAt'] != null
            ? (userData['createdAt'] as Timestamp).toDate()
            : null,
        'suspensionReason': metadata['suspensionReason'],
        'suspensionDuration': metadata['suspensionDuration'],
        'suspensionStartDate': metadata['suspensionStartDate'] != null
            ? (metadata['suspensionStartDate'] as Timestamp).toDate()
            : null,
        'banReason': metadata['banReason'],
        // Statistics
        'journalCount': journalSnapshot.docs.length,
        'wishlists': wishlistSnapshot.docs.length,
        'sharedWishlists': sharedWishlistSnapshot.docs.length,
        'projects': projectsSnapshot.docs.length,
        'sharedProjects': sharedProjectsSnapshot.docs.length,
        'tickets': totalTickets,
      };
    } catch (e) {
      throw Exception('Failed to fetch user statistics: $e');
    }
  }

  /// Update user account status
  Future<void> updateUserStatus({
    required String userId,
    required String status,
    String? reason,
    String? duration,
    String? userEmail,
  }) async {
    try {
      final metadataRef = _firestore.collection(userMetadataCollection).doc(userId);
      
      final data = <String, dynamic>{
        'status': status,
        'userId': userId,
        'userEmail': userEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (status == 'suspended') {
        data['suspensionReason'] = reason;
        data['suspensionDuration'] = duration;
        data['suspensionStartDate'] = FieldValue.serverTimestamp();
      } else if (status == 'banned') {
        data['banReason'] = reason;
      } else if (status == 'active') {
        // Remove suspension/ban data when activating
        data['suspensionReason'] = FieldValue.delete();
        data['suspensionDuration'] = FieldValue.delete();
        data['suspensionStartDate'] = FieldValue.delete();
        data['banReason'] = FieldValue.delete();
      }
      
      await metadataRef.set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  /// Update user role (stored in users collection, not metadata)
  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).set({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Update last active timestamp
  Future<void> updateLastActive(String userId) async {
    try {
      await _firestore.collection(userMetadataCollection).doc(userId).set({
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Don't throw error for last active update
      print('Failed to update last active: $e');
    }
  }

  /// Initialize user metadata when user signs up
  /// Note: lastActive is NOT set here - only set when user logs in
  Future<void> initializeUserMetadata(String userId) async {
    try {
      await _firestore.collection(userMetadataCollection).doc(userId).set({
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // lastActive is intentionally NOT set on signup - only on login
      });
    } catch (e) {
      throw Exception('Failed to initialize user metadata: $e');
    }
  }

  /// Check if specific user is admin
  Future<bool> isUserAdmin(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return false;
      
      final role = userDoc.data()?['role'] ?? 'member';
      return role == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Get user metadata
  Future<Map<String, dynamic>?> getUserMetadata(String userId) async {
    try {
      final doc = await _firestore.collection(userMetadataCollection).doc(userId).get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to get user metadata: $e');
    }
  }

  /// Check if suspension has expired and auto-reactivate if needed
  /// Returns the current status after checking
  Future<String> checkAndUpdateSuspensionStatus(String userId) async {
    try {
      final metadata = await getUserMetadata(userId);
      if (metadata == null) return 'active';

      final status = metadata['status'] ?? 'active';
      if (status != 'suspended') return status;

      // Check if suspension has expired
      final suspensionStartDate = metadata['suspensionStartDate'] as Timestamp?;
      final suspensionDuration = metadata['suspensionDuration'] as String?;

      if (suspensionStartDate == null || suspensionDuration == null) {
        return status;
      }

      // Parse duration (e.g., "7 days" -> 7)
      final durationDays = int.tryParse(suspensionDuration.split(' ').first) ?? 0;
      final startDate = suspensionStartDate.toDate();
      final expiryDate = startDate.add(Duration(days: durationDays));
      final now = DateTime.now();

      // If suspension has expired, reactivate user
      if (now.isAfter(expiryDate)) {
        // Get user info before updating status
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userName = userDoc.data()?['fullName'] ?? 'Unknown User';
        
        await updateUserStatus(
          userId: userId,
          status: 'active',
        );
        
        // Notify admin that suspension has been automatically lifted
        final adminNotificationService = AdminNotificationService();
        await adminNotificationService.notifyAccountAction(
          userId: userId,
          userName: userName,
          action: 'Suspension Lifted',
          reason: 'Suspension period expired automatically',
        );
        
        return 'active';
      }

      return 'suspended';
    } catch (e) {
      print('Error checking suspension status: $e');
      return 'active'; // Default to active on error to avoid blocking users
    }
  }

  // ===== HELPER METHODS =====

  String _formatLastActive(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  /// Check if a user is currently online (active within last 5 minutes)
  bool isUserOnline(DateTime? lastActiveDateTime) {
    if (lastActiveDateTime == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(lastActiveDateTime);
    
    // User is online if last active within last 5 minutes
    return difference.inMinutes <= 5;
  }
}
