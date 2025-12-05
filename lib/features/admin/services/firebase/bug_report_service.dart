import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:zentry/features/admin/admin.dart';

class BugReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a bug report to Firestore
  Future<void> submitBugReport(BugReportModel bugReport) async {
    try {
      await _firestore.collection('bug_reports').add(bugReport.toMap());
    } catch (e) {
      throw Exception('Failed to submit bug report: $e');
    }
  }

  /// Get all bug reports (for admin use)
  Future<List<BugReportModel>> getAllBugReports() async {
    try {
      final querySnapshot = await _firestore
          .collection('bug_reports')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BugReportModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch bug reports: $e');
    }
  }

  /// Get bug reports by user ID
  Future<List<BugReportModel>> getBugReportsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bug_reports')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BugReportModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user bug reports: $e');
    }
  }

  /// Update bug report status (for admin use)
  Future<void> updateBugReportStatus(String bugReportId, String status) async {
    try {
      await _firestore.collection('bug_reports').doc(bugReportId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update bug report status: $e');
    }
  }
}
