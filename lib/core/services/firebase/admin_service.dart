import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        // Store admin metadata in Firestore
        // This requires Firestore rules to allow admin email access
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

        // Also create user document for consistency
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
      // Don't rethrow - allow app to continue even if admin init fails
    } catch (e) {
      print('Error initializing admin account: $e');
      // Don't rethrow - allow app to continue even if admin init fails
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
}
