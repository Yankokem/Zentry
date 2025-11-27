import 'package:flutter/foundation.dart';

/// In-memory test data for admin UI (front-end only).
class AdminTestData {
  AdminTestData._();

  static final ValueNotifier<List<Map<String, dynamic>>> users = ValueNotifier<List<Map<String, dynamic>>>(
    List.generate(
      8,
      (i) => {
        'id': 'u${i + 1}',
        'name': 'User ${i + 1}',
        'email': 'user${i + 1}@example.com',
        'role': i < 2 ? 'admin' : 'member',
        'lastActive': '${(i % 5) + 1}d ago',
        'projects': List.generate(i % 3, (j) => 'Project ${j + 1}'),
        'tickets': i % 4,
        'journalCount': (i + 2) * 3,
        'wishlists': i % 2 == 0 ? 1 : 0,
        'sharedWishlists': i % 3 == 0 ? 1 : 0,
      },
    ),
  );

  static void promote(String id) {
    final list = List<Map<String, dynamic>>.from(users.value);
    final idx = list.indexWhere((u) => u['id'] == id);
    if (idx != -1) {
      list[idx] = Map<String, dynamic>.from(list[idx])..['role'] = 'admin';
      users.value = list;
    }
  }

  static void demote(String id) {
    final list = List<Map<String, dynamic>>.from(users.value);
    final idx = list.indexWhere((u) => u['id'] == id);
    if (idx != -1) {
      list[idx] = Map<String, dynamic>.from(list[idx])..['role'] = 'member';
      users.value = list;
    }
  }

  static void addAdminByEmail(String email) {
    final list = List<Map<String, dynamic>>.from(users.value);
    final idx = list.indexWhere((u) => u['email'] == email);
    if (idx != -1) {
      list[idx] = Map<String, dynamic>.from(list[idx])..['role'] = 'admin';
    } else {
      list.add({
        'id': 'u${list.length + 1}',
        'name': email.split('@').first,
        'email': email,
        'role': 'admin',
        'lastActive': 'now',
        'projects': [],
        'tickets': 0,
        'journalCount': 0,
        'wishlists': 0,
        'sharedWishlists': 0,
      });
    }
    users.value = list;
  }

  static void suspendUser(String id, String reason, String duration) {
    final list = List<Map<String, dynamic>>.from(users.value);
    final idx = list.indexWhere((u) => u['id'] == id);
    if (idx != -1) {
      list[idx] = Map<String, dynamic>.from(list[idx])
        ..['status'] = 'suspended'
        ..['suspensionReason'] = reason
        ..['suspensionDuration'] = duration;
      users.value = list;
    }
  }

  static void banUser(String id, String reason) {
    final list = List<Map<String, dynamic>>.from(users.value);
    final idx = list.indexWhere((u) => u['id'] == id);
    if (idx != -1) {
      list[idx] = Map<String, dynamic>.from(list[idx])
        ..['status'] = 'banned'
        ..['banReason'] = reason;
      users.value = list;
    }
  }

  static void activateUser(String id) {
    final list = List<Map<String, dynamic>>.from(users.value);
    final idx = list.indexWhere((u) => u['id'] == id);
    if (idx != -1) {
      list[idx] = Map<String, dynamic>.from(list[idx])
        ..['status'] = 'active'
        ..remove('suspensionReason')
        ..remove('suspensionDuration')
        ..remove('banReason');
      users.value = list;
    }
  }
}
