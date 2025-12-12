import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wish_model.dart';
import '../models/category_model.dart';
import '../services/firebase/wishlist_service.dart';
import '../services/firebase/category_service.dart';
import '../../../core/services/firebase/notification_manager.dart';
import '../../../core/core.dart';

/// Controller for managing wishlist state and business logic
/// Uses ChangeNotifier for reactive state management
class WishlistController extends ChangeNotifier {
  final WishlistService _service = WishlistService();
  final CategoryService _categoryService = CategoryService();
  
  List<Wish> _wishes = [];
  List<WishlistCategory> _categories = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Wish>>? _wishesSubscription;
  StreamSubscription<List<WishlistCategory>>? _categoriesSubscription;

  // Getters
  List<Wish> get wishes => _wishes;
  List<WishlistCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasWishes => _wishes.isNotEmpty;
  
  /// Get wishes filtered by category
  List<Wish> getWishesByCategory(String category) {
    if (category == 'all') return _wishes;
    return _wishes.where((wish) => wish.category == category).toList();
  }

  /// Get count of completed wishes
  int get completedCount {
    return _wishes.where((wish) => wish.completed).length;
  }

  /// Get total wishes count
  int get totalCount => _wishes.length;

  /// Initialize and start listening to wishlist changes
  void initialize() {
    _listenToWishes();
    _listenToCategories();
  }

  /// Listen to real-time wishlist updates from Firestore
  void _listenToWishes() {
    _setLoading(true);
    _wishesSubscription?.cancel();

    _wishesSubscription = _service.getWishesStream().listen(
      (wishes) {
        debugPrint('🔥 Wishlist stream received ${wishes.length} items');
        _wishes = wishes;
        _error = null;
        _setLoading(false);
        notifyListeners(); // Explicitly notify on every update
        debugPrint('✅ notifyListeners() called - AnimatedBuilder should rebuild');
      },
      onError: (error) {
        debugPrint('❌ Wishlist stream error: $error');
        _error = 'Failed to load wishes: $error';
        _setLoading(false);
        notifyListeners(); // Notify on error too
      },
    );
  }

  /// Listen to real-time category updates from Firestore
  void _listenToCategories() {
    _categoriesSubscription?.cancel();

    _categoriesSubscription = _categoryService.getCategoriesStream().listen(
      (categories) {
        _categories = categories;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Failed to load categories: $error');
      },
    );
  }

  /// Create a new wish
  Future<String?> createWish(Wish wish) async {
    try {
      _error = null;
      final wishId = await _service.createWish(wish);
      return wishId;
    } catch (e) {
      _error = 'Failed to create wish: $e';
      notifyListeners();
      return null;
    }
  }

  /// Update an existing wish
  Future<bool> updateWish(Wish wish) async {
    try {
      if (wish.id == null) {
        _error = 'Cannot update wish without ID';
        notifyListeners();
        return false;
      }

      _error = null;
      await _service.updateWish(wish.id!, wish);
      return true;
    } catch (e) {
      _error = 'Failed to update wish: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toggle the completed status of a wish
  Future<bool> toggleCompleted(Wish wish) async {
    try {
      if (wish.id == null) {
        _error = 'Cannot toggle wish without ID';
        notifyListeners();
        return false;
      }

      _error = null;
      final newCompletedStatus = !wish.completed;
      await _service.toggleCompleted(wish.id!, newCompletedStatus);
      
      // Notify accepted members when wish status changes
      if (wish.acceptedShares.isNotEmpty) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          try {
            final firestoreService = FirestoreService();
            final currentUserData = await firestoreService.getUserData(currentUser.uid);
            final currentUserName = currentUserData?['fullName'] ?? 'Someone';
            final notificationManager = NotificationManager();
            
            for (final shareDetail in wish.acceptedShares) {
              final memberEmail = shareDetail.email;
              if (memberEmail != currentUser.email) {
                final memberUserDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: memberEmail.toLowerCase())
                    .limit(1)
                    .get();

                if (memberUserDoc.docs.isNotEmpty) {
                  final memberUserId = memberUserDoc.docs.first.id;
                  
                  // Use specific notification methods based on the new status
                  if (newCompletedStatus) {
                    await notificationManager.notifyWishlistAcquired(
                      recipientUserId: memberUserId,
                      wishTitle: wish.title,
                      wishlistId: wish.id!,
                      acquiredByName: currentUserName,
                    );
                  } else {
                    await notificationManager.notifyWishlistUndoAcquired(
                      recipientUserId: memberUserId,
                      wishTitle: wish.title,
                      wishlistId: wish.id!,
                      undoneByName: currentUserName,
                    );
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('Failed to send notifications: $e');
            // Don't fail the toggle operation if notifications fail
          }
        }
      }
      
      return true;
    } catch (e) {
      _error = 'Failed to toggle wish: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a wish
  Future<bool> deleteWish(Wish wish) async {
    try {
      if (wish.id == null) {
        _error = 'Cannot delete wish without ID';
        notifyListeners();
        return false;
      }

      _error = null;
      await _service.deleteWish(wish.id!);
      return true;
    } catch (e) {
      _error = 'Failed to delete wish: $e';
      notifyListeners();
      return false;
    }
  }

  /// Reload wishes from Firestore
  Future<void> refresh() async {
    try {
      _setLoading(true);
      _error = null;
      final wishes = await _service.getWishes();
      _wishes = wishes;
      _setLoading(false);
    } catch (e) {
      _error = 'Failed to refresh wishes: $e';
      _setLoading(false);
    }
  }

  /// Clear all error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Create a new custom category
  Future<bool> createCategory(String name, String label, String colorHex) async {
    try {
      _error = null;
      final category = WishlistCategory(
        id: '', // Will be set by Firestore
        name: name,
        label: label,
        colorHex: colorHex,
        isDefault: false,
        userId: '',
      );
      await _categoryService.createCategory(category);
      return true;
    } catch (e) {
      _error = 'Failed to create category: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a custom category
  Future<bool> deleteCategory(String id) async {
    try {
      _error = null;
      await _categoryService.deleteCategory(id);
      return true;
    } catch (e) {
      _error = 'Failed to delete category: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get Color from category name
  Color getCategoryColor(String categoryName) {
    final category = _categories.firstWhere(
      (cat) => cat.name == categoryName,
      orElse: () => WishlistCategory.defaultCategories.first,
    );
    return _categoryService.getColorFromHex(category.colorHex);
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _wishesSubscription?.cancel();
    _categoriesSubscription?.cancel();
    super.dispose();
  }
}
