import 'shared_with_detail_model.dart';

class Wish {
  final String? id; // Firestore document ID
  final String userId; // Owner's user ID
  final String title;
  final String price;
  final String category;
  final String notes;
  final String dateAdded;
  final bool completed;
  final List<String> sharedWith; // List of user emails (backward compatibility)
  final List<SharedWithDetail> sharedWithDetails; // Detailed sharing info
  final String? imageUrl; // Single image URL (backward compatibility)
  final List<String> imageUrls; // Multiple image URLs from Cloudinary
  final String? sharedByUserId; // For shared wishlists: the owner's UID

  Wish({
    this.id,
    required this.userId,
    required this.title,
    required this.price,
    required this.category,
    required this.notes,
    required this.dateAdded,
    this.completed = false,
    this.sharedWith = const [],
    this.sharedWithDetails = const [],
    this.imageUrl,
    this.imageUrls = const [],
    this.sharedByUserId,
  });
  
  // Helper getters for sharing management
  List<SharedWithDetail> get acceptedShares =>
      sharedWithDetails.where((s) => s.isAccepted).toList();
  
  List<SharedWithDetail> get pendingShares =>
      sharedWithDetails.where((s) => s.isPending).toList();
  
  List<String> get acceptedShareEmails =>
      acceptedShares.map((s) => s.email).toList();
  
  bool get hasAcceptedShares => acceptedShares.isNotEmpty;
  
  bool isSharedWithAccepted(String email) =>
      acceptedShares.any((s) => s.email.toLowerCase() == email.toLowerCase());
  
  bool isSharedWithPending(String email) =>
      pendingShares.any((s) => s.email.toLowerCase() == email.toLowerCase());
  
  bool isOwner(String email) => userId == email;

  // Convert to Map for compatibility with existing code
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'price': price,
      'category': category,
      'notes': notes,
      'dateAdded': dateAdded,
      'completed': completed,
      'sharedWith': sharedWith,
      'sharedWithDetails': sharedWithDetails.map((s) => s.toMap()).toList(),
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'sharedByUserId': sharedByUserId,
    };
  }

  // Convert to Firestore document (excludes id)
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'price': price,
      'category': category,
      'notes': notes,
      'dateAdded': dateAdded,
      'completed': completed,
      'sharedWith': sharedWith,
      'sharedWithDetails': sharedWithDetails.map((s) => s.toMap()).toList(),
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'sharedByUserId': sharedByUserId,
      'createdAt': dateAdded, // Keep original dateAdded for display
    };
  }

  // Create from Map
  factory Wish.fromMap(Map<String, dynamic> map) {
    // Handle backward compatibility for sharedWithDetails
    List<SharedWithDetail> shareDetails = [];
    if (map['sharedWithDetails'] != null) {
      shareDetails = (map['sharedWithDetails'] as List)
          .map((s) => SharedWithDetail.fromMap(s as Map<String, dynamic>))
          .toList();
    } else if (map['sharedWith'] != null) {
      // Migrate old data: assume existing shares are accepted
      shareDetails = (map['sharedWith'] as List)
          .map((email) => SharedWithDetail(
                email: email as String,
                status: 'accepted',
                invitedAt: DateTime.now(),
                respondedAt: DateTime.now(),
              ))
          .toList();
    }
    
    return Wish(
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      price: map['price'] ?? '0',
      category: map['category'] ?? 'other',
      notes: map['notes'] ?? '',
      dateAdded: map['dateAdded'] ?? '',
      completed: map['completed'] ?? false,
      sharedWith: List<String>.from(map['sharedWith'] ?? []),
      sharedWithDetails: shareDetails,
      imageUrl: map['imageUrl'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      sharedByUserId: map['sharedByUserId'],
    );
  }

  // Create from Firestore document
  factory Wish.fromFirestore(String id, Map<String, dynamic> data) {
    // Handle backward compatibility for sharedWithDetails
    List<SharedWithDetail> shareDetails = [];
    if (data['sharedWithDetails'] != null) {
      shareDetails = (data['sharedWithDetails'] as List)
          .map((s) => SharedWithDetail.fromMap(s as Map<String, dynamic>))
          .toList();
    } else if (data['sharedWith'] != null) {
      // Migrate old data: assume existing shares are accepted
      shareDetails = (data['sharedWith'] as List)
          .map((email) => SharedWithDetail(
                email: email as String,
                status: 'accepted',
                invitedAt: DateTime.now(),
                respondedAt: DateTime.now(),
              ))
          .toList();
    }
    
    return Wish(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      price: data['price'] ?? '0',
      category: data['category'] ?? 'other',
      notes: data['notes'] ?? '',
      dateAdded: data['dateAdded'] ?? '',
      completed: data['completed'] ?? false,
      sharedWith: List<String>.from(data['sharedWith'] ?? []),
      sharedWithDetails: shareDetails,
      imageUrl: data['imageUrl'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      sharedByUserId: data['sharedByUserId'],
    );
  }

  // Copy with method for immutability
  Wish copyWith({
    String? id,
    String? userId,
    String? title,
    String? price,
    String? category,
    String? notes,
    String? dateAdded,
    bool? completed,
    List<String>? sharedWith,
    List<SharedWithDetail>? sharedWithDetails,
    String? imageUrl,
    List<String>? imageUrls,
    String? sharedByUserId,
  }) {
    return Wish(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      price: price ?? this.price,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      dateAdded: dateAdded ?? this.dateAdded,
      completed: completed ?? this.completed,
      sharedWith: sharedWith ?? this.sharedWith,
      sharedWithDetails: sharedWithDetails ?? this.sharedWithDetails,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      sharedByUserId: sharedByUserId ?? this.sharedByUserId,
    );
  }
}
