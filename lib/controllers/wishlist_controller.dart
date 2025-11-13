import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/wish_model.dart';
import '../services/firebase/wishlist_service.dart';

/// Controller for managing wishlist state and business logic
/// Uses ChangeNotifier for reactive state management
class WishlistController extends ChangeNotifier {
  final WishlistService _service = WishlistService();
  
  List<Wish> _wishes = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Wish>>? _wishesSubscription;

  // Getters
  List<Wish> get wishes => _wishes;
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
  }

  /// Listen to real-time wishlist updates from Firestore
  void _listenToWishes() {
    _setLoading(true);
    _wishesSubscription?.cancel();

    _wishesSubscription = _service.getWishesStream().listen(
      (wishes) {
        _wishes = wishes;
        _error = null;
        _setLoading(false);
      },
      onError: (error) {
        _error = 'Failed to load wishes: $error';
        _setLoading(false);
      },
    );
  }

  /// Create a new wish
  Future<bool> createWish(Wish wish) async {
    try {
      _error = null;
      await _service.createWish(wish);
      return true;
    } catch (e) {
      _error = 'Failed to create wish: $e';
      notifyListeners();
      return false;
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
      await _service.toggleCompleted(wish.id!, !wish.completed);
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

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _wishesSubscription?.cancel();
    super.dispose();
  }
}
