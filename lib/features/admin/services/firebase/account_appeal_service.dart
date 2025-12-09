import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:zentry/features/admin/admin.dart';

class AccountAppealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'account_appeal';

  /// Submit an account appeal to Firestore
  Future<void> submitAppeal(AccountAppealModel appeal) async {
    try {
      await _firestore.collection(_collection).add(appeal.toMap());
    } catch (e) {
      throw Exception('Failed to submit appeal: $e');
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

  /// Update appeal with admin response
  Future<void> updateAppealWithResponse(
    String appealId,
    String status,
    String response,
  ) async {
    try {
      await _firestore.collection(_collection).doc(appealId).update({
        'status': status,
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
