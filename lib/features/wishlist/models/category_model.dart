/// Model for wishlist categories
class WishlistCategory {
  final String? id; // Firestore document ID
  final String name; // Category name (e.g., "tech", "travel")
  final String label; // Display label (e.g., "Tech", "Travel")
  final String colorHex; // Color in hex format (e.g., "FF42A5F5")
  final bool isDefault; // Whether this is a default category
  final String userId; // Owner of this category (empty for default categories)

  WishlistCategory({
    this.id,
    required this.name,
    required this.label,
    required this.colorHex,
    this.isDefault = false,
    this.userId = '',
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'label': label,
      'colorHex': colorHex,
      'isDefault': isDefault,
      'userId': userId,
    };
  }

  /// Create from Firestore document
  factory WishlistCategory.fromFirestore(String id, Map<String, dynamic> data) {
    return WishlistCategory(
      id: id,
      name: data['name'] ?? '',
      label: data['label'] ?? '',
      colorHex: data['colorHex'] ?? 'FF78909C',
      isDefault: data['isDefault'] ?? false,
      userId: data['userId'] ?? '',
    );
  }

  /// Copy with method
  WishlistCategory copyWith({
    String? id,
    String? name,
    String? label,
    String? colorHex,
    bool? isDefault,
    String? userId,
  }) {
    return WishlistCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      label: label ?? this.label,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      userId: userId ?? this.userId,
    );
  }

  /// Default categories
  static List<WishlistCategory> get defaultCategories => [
        WishlistCategory(
          name: 'tech',
          label: 'Tech',
          colorHex: 'FF42A5F5',
          isDefault: true,
        ),
        WishlistCategory(
          name: 'travel',
          label: 'Travel',
          colorHex: 'FF66BB6A',
          isDefault: true,
        ),
        WishlistCategory(
          name: 'fashion',
          label: 'Fashion',
          colorHex: 'FFAB47BC',
          isDefault: true,
        ),
        WishlistCategory(
          name: 'home',
          label: 'Home',
          colorHex: 'FFFFA726',
          isDefault: true,
        ),
      ];
}
