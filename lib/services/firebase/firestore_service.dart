import 'package:cloud_firestore/cloud_firestore.dart';

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
      print('Firestore userExistsByEmail error: $e');
      // If there's an error, throw it so we can see what's happening
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
