import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for fetching real-time analytics data for the admin dashboard
class AdminAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== KPI STATS =====
  
  /// Get total user count
  Future<int> getTotalUsersCount() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.length;
  }

  /// Get total user count as stream
  Stream<int> getTotalUsersCountStream() {
    return _firestore.collection('users').snapshots().map((snapshot) => snapshot.docs.length);
  }

  /// Get active users count (users who logged in in last 7 days)
  Future<int> getActiveUsersCount() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    
    // Try to get from user_metadata first
    final metadataSnapshot = await _firestore
        .collection('user_metadata')
        .where('lastActive', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
        .get();
    
    if (metadataSnapshot.docs.isNotEmpty) {
      return metadataSnapshot.docs.length;
    }
    
    // Fallback: check users collection for recent activity
    // Count users who have created content recently
    final recentProjects = await _firestore
        .collection('projects')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
        .get();
    
    final recentJournals = await _firestore
        .collection('journal_entries')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
        .get();
    
    final recentWishlists = await _firestore
        .collection('wishlists')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
        .get();
    
    // Get unique user IDs from all sources
    final activeUserIds = <String>{};
    
    for (final doc in recentProjects.docs) {
      final userId = doc.data()['userId'] as String?;
      if (userId != null) activeUserIds.add(userId);
    }
    
    for (final doc in recentJournals.docs) {
      final userId = doc.data()['userId'] as String?;
      if (userId != null) activeUserIds.add(userId);
    }
    
    for (final doc in recentWishlists.docs) {
      final userId = doc.data()['userId'] as String?;
      if (userId != null) activeUserIds.add(userId);
    }
    
    return activeUserIds.length;
  }

  /// Get active users count as stream
  Stream<int> getActiveUsersCountStream() {
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await getActiveUsersCount();
    }).asyncMap((event) => event);
  }

  /// Get new users this week
  Future<int> getNewUsersThisWeek() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final snapshot = await _firestore
        .collection('users')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
        .get();
    return snapshot.docs.length;
  }

  // ===== USER ACTIVITY DATA =====

  /// Get activity data for charts (projects, journals, wishlists)
  /// Returns data grouped by time period
  Future<Map<String, List<Map<String, dynamic>>>> getActivityData({
    required String interval, // 'Daily', 'Weekly', 'Monthly'
    String activityType = 'All', // 'All', 'Projects', 'Journal', 'Wishlist'
  }) async {
    final now = DateTime.now();
    DateTime startDate;
    int periods;
    
    // Determine date range and period count based on interval
    if (interval == 'Daily') {
      // Last 7 days
      startDate = now.subtract(const Duration(days: 6));
      periods = 7;
    } else if (interval == 'Weekly') {
      // Weeks of current month only
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final currentWeek = ((now.day - 1) / 7).floor() + 1;
      startDate = firstDayOfMonth;
      periods = currentWeek; // Number of weeks so far in current month
    } else {
      // Last 6 months
      startDate = DateTime(now.year, now.month - 5, 1);
      periods = 6;
    }

    final result = <String, List<Map<String, dynamic>>>{
      'projects': [],
      'journal': [],
      'wishlist': [],
    };

    // Fetch data based on activity type
    if (activityType == 'All' || activityType == 'Projects') {
      result['projects'] = await _getProjectsActivityData(startDate, interval, periods, now);
    }
    
    if (activityType == 'All' || activityType == 'Journal') {
      result['journal'] = await _getJournalActivityData(startDate, interval, periods, now);
    }
    
    if (activityType == 'All' || activityType == 'Wishlist') {
      result['wishlist'] = await _getWishlistActivityData(startDate, interval, periods, now);
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> _getProjectsActivityData(
    DateTime startDate,
    String interval,
    int periods,
    DateTime now,
  ) async {
    final snapshot = await _firestore
        .collection('projects')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
        .get();

    return _groupDataByPeriod(snapshot.docs, interval, periods, startDate, now);
  }

  Future<List<Map<String, dynamic>>> _getJournalActivityData(
    DateTime startDate,
    String interval,
    int periods,
    DateTime now,
  ) async {
    final snapshot = await _firestore
        .collection('journal_entries')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
        .get();

    return _groupDataByPeriod(snapshot.docs, interval, periods, startDate, now);
  }

  Future<List<Map<String, dynamic>>> _getWishlistActivityData(
    DateTime startDate,
    String interval,
    int periods,
    DateTime now,
  ) async {
    final snapshot = await _firestore
        .collection('wishlists')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
        .get();

    return _groupDataByPeriod(snapshot.docs, interval, periods, startDate, now);
  }

  List<Map<String, dynamic>> _groupDataByPeriod(
    List<QueryDocumentSnapshot> docs,
    String interval,
    int periods,
    DateTime startDate,
    DateTime now,
  ) {
    final data = <Map<String, dynamic>>[];

    for (int i = 0; i < periods; i++) {
      String label;
      DateTime periodStart;
      DateTime periodEnd;

      if (interval == 'Daily') {
        periodStart = DateTime(startDate.year, startDate.month, startDate.day + i);
        periodEnd = periodStart.add(const Duration(days: 1));
        label = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][periodStart.weekday - 1];
      } else if (interval == 'Weekly') {
        // Weeks of current month
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        periodStart = firstDayOfMonth.add(Duration(days: i * 7));
        periodEnd = periodStart.add(const Duration(days: 7));
        
        // Don't go past current day
        if (periodEnd.isAfter(now)) {
          periodEnd = now.add(const Duration(days: 1));
        }
        
        label = 'W${i + 1}';
      } else {
        // Monthly
        periodStart = DateTime(now.year, now.month - (5 - i), 1);
        periodEnd = DateTime(now.year, now.month - (5 - i) + 1, 1);
        label = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][periodStart.month - 1];
      }

      // Count documents in this period
      int count = 0;
      for (final doc in docs) {
        final docData = doc.data() as Map<String, dynamic>?;
        final createdAt = docData?['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final date = createdAt.toDate();
          if (date.isAfter(periodStart) && date.isBefore(periodEnd)) {
            count++;
          }
        }
      }

      data.add({
        'label': label,
        'value': count,
        'periodStart': periodStart,
        'periodEnd': periodEnd,
      });
    }

    return data;
  }

  // ===== SIGNUP TREND DATA =====

  /// Get descriptive label for activity chart based on interval
  String getActivityChartLabel(String interval) {
    final now = DateTime.now();
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 
                        'July', 'August', 'September', 'October', 'November', 'December'];
    
    if (interval == 'Daily') {
      // Find which week of the month we're in
      final weekOfMonth = ((now.day - 1) / 7).floor() + 1;
      final weekName = ['1st', '2nd', '3rd', '4th', '5th'][weekOfMonth - 1];
      return 'Daily graph for $weekName Week of ${monthNames[now.month - 1]}';
    } else if (interval == 'Weekly') {
      return 'Weekly graph for ${monthNames[now.month - 1]} ${now.year}';
    } else {
      return 'Monthly graph for ${now.year}';
    }
  }

  // ===== SIGNUP TREND DATA =====

  /// Get user signup data for trend chart
  Future<List<Map<String, dynamic>>> getSignupTrendData(String period) async {
    final now = DateTime.now();
    DateTime startDate;
    int dataPoints;
    String intervalType;

    if (period == 'Last 7 Days') {
      startDate = now.subtract(const Duration(days: 6));
      dataPoints = 7;
      intervalType = 'daily';
    } else if (period == 'Last 30 Days') {
      startDate = now.subtract(const Duration(days: 29));
      dataPoints = 30;
      intervalType = 'daily';
    } else if (period == 'Last 3 Months') {
      startDate = DateTime(now.year, now.month - 2, 1);
      dataPoints = 3;
      intervalType = 'monthly';
    } else {
      startDate = now.subtract(const Duration(days: 6));
      dataPoints = 7;
      intervalType = 'daily';
    }

    final snapshot = await _firestore
        .collection('users')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
        .get();

    final data = <Map<String, dynamic>>[];

    if (intervalType == 'daily') {
      for (int i = 0; i < dataPoints; i++) {
        final day = startDate.add(Duration(days: i));
        final nextDay = day.add(const Duration(days: 1));
        
        int count = 0;
        for (final doc in snapshot.docs) {
          final docData = doc.data();
          final createdAt = docData['createdAt'] as Timestamp?;
          if (createdAt != null) {
            final date = createdAt.toDate();
            if (date.isAfter(day) && date.isBefore(nextDay)) {
              count++;
            }
          }
        }

        String label;
        if (period == 'Last 7 Days') {
          label = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];
        } else {
          label = (i + 1).toString();
        }

        data.add({'label': label, 'value': count});
      }
    } else {
      // Monthly
      for (int i = 0; i < dataPoints; i++) {
        final month = DateTime(now.year, now.month - (dataPoints - 1 - i), 1);
        final nextMonth = DateTime(now.year, now.month - (dataPoints - 1 - i) + 1, 1);
        
        int count = 0;
        for (final doc in snapshot.docs) {
          final docData = doc.data();
          final createdAt = docData['createdAt'] as Timestamp?;
          if (createdAt != null) {
            final date = createdAt.toDate();
            if (date.isAfter(month) && date.isBefore(nextMonth)) {
              count++;
            }
          }
        }

        final label = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month.month - 1];
        data.add({'label': label, 'value': count});
      }
    }

    return data;
  }

  // ===== RECENT ACTIVITY =====

  /// Get recent activity feed (combines multiple sources)
  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    final activities = <Map<String, dynamic>>[];

    // Get recent user signups
    final recentUsers = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .get();

    for (final doc in recentUsers.docs) {
      final data = doc.data();
      final createdAt = data['createdAt'] as Timestamp?;
      activities.add({
        'type': 'signup',
        'icon': 'person_add',
        'title': 'New user signed up',
        'subtitle': data['email'] ?? 'Unknown user',
        'timestamp': createdAt?.toDate() ?? DateTime.now(),
      });
    }

    // Get recent bug reports
    final recentBugs = await _firestore
        .collection('bug_reports')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .get();

    for (final doc in recentBugs.docs) {
      final data = doc.data();
      final createdAt = data['createdAt'] as Timestamp?;
      final status = data['status'] ?? 'Open';
      activities.add({
        'type': 'bug_report',
        'icon': 'bug_report',
        'title': 'Bug report ${status.toLowerCase()}',
        'subtitle': data['title'] ?? 'Bug report received',
        'timestamp': createdAt?.toDate() ?? DateTime.now(),
      });
    }

    // Get recent appeals
    final recentAppeals = await _firestore
        .collection('appeals')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .get();

    for (final doc in recentAppeals.docs) {
      final data = doc.data();
      final createdAt = data['createdAt'] as Timestamp?;
      final status = data['status'] ?? 'Pending';
      activities.add({
        'type': 'appeal',
        'icon': 'gavel',
        'title': 'Account appeal $status',
        'subtitle': data['reason'] ?? 'Appeal received',
        'timestamp': createdAt?.toDate() ?? DateTime.now(),
      });
    }

    // Sort by timestamp and limit
    activities.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    return activities.take(limit).toList();
  }

  /// Format time ago for activity feed
  String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() > 1 ? 's' : ''} ago';
    }
  }
}
