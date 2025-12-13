import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:zentry/features/admin/admin.dart';
import 'package:zentry/features/admin/services/admin_notification_service.dart';

class BugReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'bug_reports';

  /// Submit a bug report to Firestore
  Future<void> submitBugReport(BugReportModel bugReport) async {
    try {
      final docRef = await _firestore.collection(_collection).add(bugReport.toMap());
      
      // Notify admin of new bug report
      final adminNotificationService = AdminNotificationService();
      await adminNotificationService.notifyNewBugReport(
        bugReportId: docRef.id,
        userId: bugReport.userId,
        title: bugReport.title,
        severity: bugReport.category, // Use category as severity
        description: bugReport.content,
      );
    } catch (e) {
      throw Exception('Failed to submit bug report: $e');
    }
  }

  /// Get all bug reports (for admin use)
  Future<List<BugReportModel>> getAllBugReports() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
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
          .collection(_collection)
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

  /// Get a single bug report by ID
  Future<BugReportModel?> getBugReportById(String bugReportId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(bugReportId)
          .get();
      
      if (doc.exists) {
        return BugReportModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch bug report: $e');
    }
  }

  /// Update bug report status (for admin use)
  Future<void> updateBugReportStatus(String bugReportId, String status, {String? oldStatus, String? title}) async {
    try {
      await _firestore.collection(_collection).doc(bugReportId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
      
      // Notify admin of status change if title and oldStatus provided
      if (oldStatus != null && title != null && oldStatus != status) {
        final adminNotificationService = AdminNotificationService();
        await adminNotificationService.notifyBugReportStatusChange(
          bugReportId: bugReportId,
          title: title,
          oldStatus: oldStatus,
          newStatus: status,
        );
      }
    } catch (e) {
      throw Exception('Failed to update bug report status: $e');
    }
  }

  /// Stream all bug reports
  Stream<List<BugReportModel>> getBugReportsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BugReportModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Stream bug reports by status
  Stream<List<BugReportModel>> getBugReportsByStatusStream(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BugReportModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}

