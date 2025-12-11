import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:zentry/features/admin/admin.dart';

class AccountAppealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'account_appeal';

  /// Submit an account appeal to Firestore
  Future<void> submitAppeal(AccountAppealModel appeal) async {
    try {
      // Debug: Check authentication status
      final currentUser = _auth.currentUser;
      if (kDebugMode) {
        print('🔐 Auth Status:');
        print('  Current user: ${currentUser?.uid}');
        print('  Current user email: ${currentUser?.email}');
        print('  Is authenticated: ${currentUser != null}');
        print('  Token: ${(await currentUser?.getIdTokenResult())?.token?.substring(0, 20)}...');
      }

      // Debug: Log the data being submitted
      if (kDebugMode) {
        print('📤 Submitting appeal:');
        print('  userId: ${appeal.userId}');
        print('  userEmail: ${appeal.userEmail}');
        print('  reason: ${appeal.reason}');
        print('  title: ${appeal.title}');
        print('  status: ${appeal.status}');
        print('  Collection: $_collection');
      }

      final data = appeal.toMap();
      
      if (kDebugMode) {
        print('  Data keys: ${data.keys.toList()}');
        print('  Data userId value: ${data['userId']}');
        print('  Data values sample: userId=${data['userId']}, status=${data['status']}, createdAt=${data['createdAt']}');
      }

      if (kDebugMode) {
        print('  Firestore instance: ${_firestore.hashCode}');
        print('  Writing to collection: $_collection');
      }

      final docRef = await _firestore.collection(_collection).add(data);
      
      if (kDebugMode) {
        print('✅ Appeal submitted successfully with ID: ${docRef.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error submitting appeal: $e');
        print('  Error type: ${e.runtimeType}');
        print('  Full error: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Get all appeals (for admin use)
  Future<List<AccountAppealModel>> getAllAppeals() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AccountAppealModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch appeals: $e');
    }
  }

  /// Get appeals by user ID
  Future<List<AccountAppealModel>> getAppealsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AccountAppealModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user appeals: $e');
    }
  }

  /// Update appeal status (for admin use)
  Future<void> updateAppealStatus(String appealId, String status) async {
    try {
      await _firestore.collection(_collection).doc(appealId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update appeal status: $e');
    }
  }

  /// Update appeal with admin response and decision
  Future<void> updateAppealWithResponse(
    String appealId,
    String decision,
    String response,
  ) async {
    try {
      await _firestore.collection(_collection).doc(appealId).update({
        'status': 'Closed', // Always save status as Closed
        'decision': decision, // Save the admin's decision (e.g., '1 day', 'Lift Suspension', etc.)
        'adminResponse': response,
        'updatedAt': Timestamp.now(),
        'resolvedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update appeal: $e');
    }
  }

  /// Stream all appeals
  Stream<List<AccountAppealModel>> getAppealsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AccountAppealModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Stream appeals by status
  Stream<List<AccountAppealModel>> getAppealsByStatusStream(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AccountAppealModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}
