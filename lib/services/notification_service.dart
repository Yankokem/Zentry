import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:zentry/models/notification_model.dart';
import 'package:zentry/services/firebase/auth_service.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Notification channels
  static const String _taskChannelId = 'task_reminders';
  static const String _journalChannelId = 'journal_reminders';
  static const String _wishlistChannelId = 'wishlist_updates';
  static const String _systemChannelId = 'system_updates';

  // Initialize notifications
  Future<void> initialize() async {
    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure Firebase messaging
    await _configureFirebaseMessaging();

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }

    // Listen for token updates
    _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    // Firebase messaging permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Firebase messaging permission status: ${settings.authorizationStatus}');
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  // Create notification channels
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
      _taskChannelId,
      'Task Reminders',
      description: 'Reminders for your tasks',
      importance: Importance.high,
      playSound: true,
    );

    const AndroidNotificationChannel journalChannel = AndroidNotificationChannel(
      _journalChannelId,
      'Journal Reminders',
      description: 'Reminders to write in your journal',
      importance: Importance.high,
      playSound: true,
    );

    const AndroidNotificationChannel wishlistChannel = AndroidNotificationChannel(
      _wishlistChannelId,
      'Wishlist Updates',
      description: 'Updates about your wishlist items',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
      _systemChannelId,
      'System Updates',
      description: 'App updates and system notifications',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(taskChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(journalChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(wishlistChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(systemChannel);
  }

  // Configure Firebase messaging
  Future<void> _configureFirebaseMessaging() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    final user = _authService.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
    await _saveNotificationToFirestore(message);
  }

  // Handle when app is opened from notification
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    // Handle navigation based on notification data
    final data = message.data;
    if (data.containsKey('route')) {
      // Navigate to specific route
      print('Navigate to: ${data['route']}');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      final data = jsonDecode(payload);
      if (data.containsKey('route')) {
        // Navigate to specific route
        print('Navigate to: ${data['route']}');
      }
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _getChannelId(message.data['type'] ?? 'system'),
      _getChannelName(message.data['type'] ?? 'system'),
      channelDescription: _getChannelDescription(message.data['type'] ?? 'system'),
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  // Save notification to Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      type: _parseNotificationType(message.data['type']),
      data: message.data,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toFirestore());
  }

  // Schedule local notification
  Future<void> scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationType type = NotificationType.custom,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(type.toString().split('.').last),
      _getChannelName(type.toString().split('.').last),
      channelDescription: _getChannelDescription(type.toString().split('.').last),
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Cancel scheduled notification
  Future<void> cancelScheduledNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cancel all scheduled notifications
  Future<void> cancelAllScheduledNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Get notifications from Firestore
  Stream<List<NotificationModel>> getNotifications() {
    final user = _authService.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _localNotifications.cancel(int.parse(notificationId));
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Helper methods
  String _getChannelId(String type) {
    switch (type) {
      case 'task':
        return _taskChannelId;
      case 'journal':
        return _journalChannelId;
      case 'wishlist':
        return _wishlistChannelId;
      default:
        return _systemChannelId;
    }
  }

  String _getChannelName(String type) {
    switch (type) {
      case 'task':
        return 'Task Reminders';
      case 'journal':
        return 'Journal Reminders';
      case 'wishlist':
        return 'Wishlist Updates';
      default:
        return 'System Updates';
    }
  }

  String _getChannelDescription(String type) {
    switch (type) {
      case 'task':
        return 'Reminders for your tasks';
      case 'journal':
        return 'Reminders to write in your journal';
      case 'wishlist':
        return 'Updates about your wishlist items';
      default:
        return 'App updates and system notifications';
    }
  }

  NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'task':
        return NotificationType.taskReminder;
      case 'journal':
        return NotificationType.journalReminder;
      case 'wishlist':
        return NotificationType.wishlistUpdate;
      case 'system':
        return NotificationType.systemUpdate;
      default:
        return NotificationType.custom;
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  print('Background message: ${message.messageId}');
}
