class WishlistManager {
  static final WishlistManager _instance = WishlistManager._internal();
  factory WishlistManager() => _instance;
  WishlistManager._internal();

  final List<Map<String, dynamic>> _items = [
    {
      'title': 'New MacBook Pro',
      'price': '2499',
      'category': 'tech',
      'notes': 'M3 chip, 16GB RAM, perfect for coding',
      'dateAdded': 'Nov 5, 2025',
    },
    {
      'title': 'Trip to Japan',
      'price': '3500',
      'category': 'travel',
      'notes': 'Visit Tokyo, Kyoto, and Mount Fuji',
      'dateAdded': 'Nov 4, 2025',
    },
    {
      'title': 'Sony A7 IV Camera',
      'price': '1200',
      'category': 'tech',
      'notes': 'For photography hobby',
      'dateAdded': 'Nov 3, 2025',
    },
  ];

  List<Map<String, dynamic>> get items => _items;

  void addItem(Map<String, dynamic> item) {
    _items.insert(0, item);
  }

  void removeItem(Map<String, dynamic> item) {
    _items.remove(item);
  }
}