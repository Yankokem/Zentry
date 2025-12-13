import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Types of notifications for admins
enum AdminNotificationType {
  newUser,              // New account registration
  newBugReport,         // New bug report submitted
  bugReportStatusChange, // Bug report status changed
  newAppeal,            // New account appeal submitted
  urgentAppeal,         // Appeal that needs immediate attention
  userMilestone,        // User reached a milestone (100 projects, etc.)
  appMilestone,         // App milestone (1000 users, etc.)
  securityAlert,        // Security-related events
  systemHealth,         // System health issues
  criticalError,        // Critical errors that need attention
  unusualActivity,      // Unusual patterns detected
  userFeedback,         // User submitted feedback/rating
  accountAction,        // User account suspended/banned/activated
}

class AdminNotificationModel {
  final String id;
  final String title;
  final String message;
  final AdminNotificationType type;
  final Map<String, dynamic> metadata; // Additional data for navigation/context
  final DateTime createdAt;
  final bool isRead;
  final String? actionUrl; // Deep link or route for action
  final String? userId;    // Related user ID if applicable
  final String? relatedEntityId; // ID of related entity (bug report, appeal, etc.)

  AdminNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.metadata = const {},
    required this.createdAt,
    this.isRead = false,
    this.actionUrl,
    this.userId,
    this.relatedEntityId,
  });

  factory AdminNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminNotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _parseNotificationType(data['type']),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      actionUrl: data['actionUrl'],
      userId: data['userId'],
      relatedEntityId: data['relatedEntityId'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'actionUrl': actionUrl,
      'userId': userId,
      'relatedEntityId': relatedEntityId,
    };
  }

  /// Create a copy with updated fields
  AdminNotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    AdminNotificationType? type,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    bool? isRead,
    String? actionUrl,
    String? userId,
    String? relatedEntityId,
  }) {
    return AdminNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      userId: userId ?? this.userId,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
    );
  }

  /// Parse notification type from string
  static AdminNotificationType _parseNotificationType(String? typeString) {
    if (typeString == null) return AdminNotificationType.systemHealth;
    
    try {
      return AdminNotificationType.values.firstWhere(
        (e) => e.name == typeString,
        orElse: () => AdminNotificationType.systemHealth,
      );
    } catch (e) {
      return AdminNotificationType.systemHealth;
    }
  }

  /// Get icon for notification type
  static IconData getIconForType(AdminNotificationType type) {
    switch (type) {
      case AdminNotificationType.newUser:
        return Icons.person_add_rounded;
      case AdminNotificationType.newBugReport:
        return Icons.bug_report_rounded;
      case AdminNotificationType.bugReportStatusChange:
        return Icons.update_rounded;
      case AdminNotificationType.newAppeal:
        return Icons.gavel_rounded;
      case AdminNotificationType.urgentAppeal:
        return Icons.gavel_rounded;
      case AdminNotificationType.userMilestone:
        return Icons.star_rounded;
      case AdminNotificationType.appMilestone:
        return Icons.star_rounded;
      case AdminNotificationType.securityAlert:
        return Icons.security_rounded;
      case AdminNotificationType.systemHealth:
        return Icons.health_and_safety_rounded;
      case AdminNotificationType.criticalError:
        return Icons.error_rounded;
      case AdminNotificationType.unusualActivity:
        return Icons.warning_rounded;
      case AdminNotificationType.userFeedback:
        return Icons.message_rounded;
      case AdminNotificationType.accountAction:
        return Icons.admin_panel_settings_rounded;
    }
  }

  /// Get color for notification type
  static Color getColorForType(AdminNotificationType type) {
    switch (type) {
      case AdminNotificationType.newUser:
        return Colors.blue;
      case AdminNotificationType.newBugReport:
      case AdminNotificationType.bugReportStatusChange:
        return Colors.orange;
      case AdminNotificationType.newAppeal:
      case AdminNotificationType.urgentAppeal:
        return Colors.purple;
      case AdminNotificationType.userMilestone:
      case AdminNotificationType.appMilestone:
        return Colors.amber;
      case AdminNotificationType.securityAlert:
      case AdminNotificationType.criticalError:
        return Colors.red;
      case AdminNotificationType.systemHealth:
        return Colors.teal;
      case AdminNotificationType.unusualActivity:
        return Colors.deepOrange;
      case AdminNotificationType.userFeedback:
        return Colors.green;
      case AdminNotificationType.accountAction:
        return Colors.indigo;
    }
  }
}
