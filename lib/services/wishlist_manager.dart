import '../models/wish_model.dart';

/// Legacy WishlistManager - kept for backward compatibility
/// New code should use WishlistController and WishlistService
class WishlistManager {
  static final WishlistManager _instance = WishlistManager._internal();
  factory WishlistManager() => _instance;
  WishlistManager._internal();

  // Sample data cleared - now using Firestore
  final List<Wish> _items = [];

  List<Wish> get items => _items;

  void addItem(Wish item) {
    _items.insert(0, item);
  }

  void removeItem(Wish item) {
    _items.remove(item);
  }

  void updateItem(Wish item, Wish updates) {
    final index = _items.indexOf(item);
    if (index != -1) {
      _items[index] = updates;
    }
  }

  // For backward compatibility with existing code that uses Maps
  List<Map<String, dynamic>> get itemsAsMaps => _items.map((item) => item.toMap()).toList();

  void addItemFromMap(Map<String, dynamic> itemMap) {
    _items.insert(0, Wish.fromMap(itemMap));
  }

  void removeItemFromMap(Map<String, dynamic> itemMap) {
    final item = Wish.fromMap(itemMap);
    _items.remove(item);
  }
}
