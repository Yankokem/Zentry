import 'package:flutter/material.dart';
import '../controllers/wishlist_controller.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistController _controller = WishlistController();
  
  WishlistController get controller => _controller;

  WishlistProvider() {
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
