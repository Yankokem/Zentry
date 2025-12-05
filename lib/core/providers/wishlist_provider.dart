import 'package:flutter/material.dart';

import 'package:zentry/features/wishlist/wishlist.dart';

class WishlistProvider extends ChangeNotifier {
  WishlistController? _controller;
  bool _isInitialized = false;

  WishlistController get controller {
    if (!_isInitialized || _controller == null) {
      throw StateError('WishlistProvider not initialized. Call initialize() first.');
    }
    return _controller!;
  }

  bool get isInitialized => _isInitialized;

  WishlistProvider() {
    _initialize();
  }

  void _initialize() {
    if (_isInitialized) return;

    _controller = WishlistController();
    _controller!.initialize();
    _isInitialized = true;
    notifyListeners();
  }
}
