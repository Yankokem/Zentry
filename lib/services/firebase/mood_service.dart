import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/mood_model.dart';

/// Service for managing moods in Firestore
/// Moods are stored in a dedicated 'moods' collection with userId as a field
/// This avoids creating unnecessary parent documents
class MoodService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String moodsCollection = 'moods';

  /// Get the current user's ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get reference to moods collection
  CollectionReference get _moodsRef => _db.collection(moodsCollection);

  /// Get all moods for the current user (default + custom)
  Stream<List<Mood>> getMoodsStream() {
    if (_userId == null) {
      return Stream.value(Mood.defaultMoods);
    }

    return _moodsRef
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      // Get custom moods from Firestore
      final customMoods = snapshot.docs.map((doc) {
        return Mood.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();

      // Combine default + custom moods
      return [...Mood.defaultMoods, ...customMoods];
    });
  }

  /// Get all moods (one-time fetch)
  Future<List<Mood>> getMoods() async {
    try {
      if (_userId == null) {
        return Mood.defaultMoods;
      }

      final snapshot = await _moodsRef
          .where('userId', isEqualTo: _userId)
          .get();

      final customMoods = snapshot.docs.map((doc) {
        return Mood.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();

      return [...Mood.defaultMoods, ...customMoods];
    } catch (e) {
      return Mood.defaultMoods;
    }
  }

  /// Create a new custom mood
  Future<String> createMood(Mood mood) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      // Ensure it's marked as custom
      final customMood = mood.copyWith(
        isDefault: false,
        userId: _userId,
      );

      final docRef = await _moodsRef.add({
        ...customMood.toFirestore(),
        'userId': _userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create mood: $e');
    }
  }

  /// Delete a custom mood
  Future<void> deleteMood(String id) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify existence and ownership before deleting
      final doc = await _moodsRef.doc(id).get();
      if (!doc.exists) {
        throw Exception('Mood not found');
      }

      final data = doc.data() as Map<String, dynamic>;

      // Can't delete default moods
      if (data['isDefault'] == true) {
        throw Exception('Cannot delete default moods');
      }

      // Can only delete own moods
      if (data['userId'] != _userId) {
        throw Exception('Unauthorized');
      }

      await _moodsRef.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete mood: $e');
    }
  }

  /// Get Color from hex string
  Color getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  /// Convert Color to hex string
  String getHexFromColor(Color color) {
    return color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
  }
}
