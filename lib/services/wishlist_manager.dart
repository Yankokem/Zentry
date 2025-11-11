import '../models/wish_model.dart';

class WishlistManager {
  static final WishlistManager _instance = WishlistManager._internal();
  factory WishlistManager() => _instance;
  WishlistManager._internal();

  final List<Wish> _items = [
    Wish(
      title: 'New MacBook Pro',
      price: '2499',
      category: 'tech',
      notes: 'M3 chip, 16GB RAM, perfect for coding',
      dateAdded: 'Nov 5, 2025',
      completed: false,
    ),
    Wish(
      title: 'Trip to Japan',
      price: '3500',
      category: 'travel',
      notes: 'Visit Tokyo, Kyoto, and Mount Fuji',
      dateAdded: 'Nov 4, 2025',
      completed: false,
    ),
    Wish(
      title: 'Sony A7 IV Camera',
      price: '1200',
      category: 'tech',
      notes: 'For photography hobby',
      dateAdded: 'Nov 3, 2025',
      completed: false,
    ),
  ];

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
