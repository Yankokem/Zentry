import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String usersCollection = 'users';

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
}
