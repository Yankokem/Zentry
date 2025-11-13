import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/category_model.dart';

/// Service for managing wishlist categories in Firestore
class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String categoriesCollection = 'wishlist_categories';

  /// Get the current user's ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get reference to the categories collection
  CollectionReference get _categoriesRef => _db.collection(categoriesCollection);

  /// Get all categories for the current user (default + custom)
  Stream<List<WishlistCategory>> getCategoriesStream() {
    if (_userId == null) {
      return Stream.value(WishlistCategory.defaultCategories);
    }

    return _categoriesRef
        .where('userId', whereIn: ['', _userId])
        .snapshots()
        .map((snapshot) {
      // Get custom categories from Firestore
      final customCategories = snapshot.docs.map((doc) {
        return WishlistCategory.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).where((cat) => !cat.isDefault).toList();

      // Combine default + custom categories
      return [...WishlistCategory.defaultCategories, ...customCategories];
    });
  }

  /// Get all categories (one-time fetch)
  Future<List<WishlistCategory>> getCategories() async {
    try {
      if (_userId == null) {
        return WishlistCategory.defaultCategories;
      }

      final snapshot = await _categoriesRef
          .where('userId', whereIn: ['', _userId])
          .get();

      final customCategories = snapshot.docs.map((doc) {
        return WishlistCategory.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).where((cat) => !cat.isDefault).toList();

      return [...WishlistCategory.defaultCategories, ...customCategories];
    } catch (e) {
      return WishlistCategory.defaultCategories;
    }
  }

  /// Create a new custom category
  Future<String> createCategory(WishlistCategory category) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      // Ensure it's marked as custom
      final customCategory = category.copyWith(
        isDefault: false,
        userId: _userId,
      );

      final docRef = await _categoriesRef.add({
        ...customCategory.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  /// Delete a custom category
  Future<void> deleteCategory(String id) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify ownership before deleting
      final doc = await _categoriesRef.doc(id).get();
      if (!doc.exists) {
        throw Exception('Category not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      
      // Can't delete default categories
      if (data['isDefault'] == true) {
        throw Exception('Cannot delete default categories');
      }

      // Can only delete own categories
      if (data['userId'] != _userId) {
        throw Exception('Unauthorized');
      }

      await _categoriesRef.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
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
