import 'dart:async';
import 'package:flutter/material.dart';

import 'package:zentry/core/core.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  bool _isSessionActive = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize() async {
    _isSessionActive = true;
    await _notificationService.initialize();
    if (_isSessionActive) {
      await loadNotifications();
    }
  }

  StreamSubscription? _subscription;

  Future<void> loadNotifications() async {
    if (!_isSessionActive) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Cancel previous subscription if any
      await _subscription?.cancel();

      // Check if session is still active after the await
      if (!_isSessionActive) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final stream = _notificationService.getNotifications();
      _subscription = stream.listen(
        (notifications) {
          if (!_isSessionActive) {
            _subscription?.cancel();
            return;
          }
          _notifications = notifications;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          if (!_isSessionActive) return;
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      if (!_isSessionActive) return;
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          title: _notifications[index].title,
          body: _notifications[index].body,
          type: _notifications[index].type,
          data: _notifications[index].data,
          createdAt: _notifications[index].createdAt,
          isRead: true,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      for (final notification in _notifications.where((n) => !n.isRead)) {
        await _notificationService.markAsRead(notification.id);
      }
      _notifications = _notifications
          .map((n) => NotificationModel(
                id: n.id,
                userId: n.userId,
                title: n.title,
                body: n.body,
                type: n.type,
                data: n.data,
                createdAt: n.createdAt,
                isRead: true,
              ))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> scheduleLocalNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    NotificationType type = NotificationType.custom,
    String? payload,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notificationService.scheduleLocalNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        type: type,
        payload: payload,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelScheduledNotification(int id) async {
    try {
      await _notificationService.cancelScheduledNotification(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void cleanup() {
    _isSessionActive = false;
    _subscription?.cancel();
    _subscription = null;
    _notifications = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
