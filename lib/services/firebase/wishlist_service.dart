import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/wish_model.dart';

/// Service class for managing wishlist items in Firestore
/// Follows the repository pattern for data access
class WishlistService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String wishlistCollection = 'wishlists';

  /// Get the current user's ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get reference to user's wishlist collection
  CollectionReference? get _userWishlistRef {
    if (_userId == null) return null;
    return _db
        .collection('users')
        .doc(_userId)
        .collection(wishlistCollection);
  }

  /// Create a new wishlist item
  /// Returns the document ID of the created item
  Future<String> createWish(Wish wish) async {
    try {
      if (_userWishlistRef == null) {
        throw Exception('User not authenticated');
      }

      final docRef = await _userWishlistRef!.add({
        ...wish.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create wish: $e');
    }
  }

  /// Get all wishlist items for the current user
  /// Returns a stream that updates in real-time
  Stream<List<Wish>> getWishesStream() {
    if (_userWishlistRef == null) {
      return Stream.value([]);
    }

    return _userWishlistRef!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Wish.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  /// Get all wishlist items (one-time fetch)
  Future<List<Wish>> getWishes() async {
    try {
      if (_userWishlistRef == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _userWishlistRef!
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Wish.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get wishes: $e');
    }
  }

  /// Get a single wishlist item by ID
  Future<Wish?> getWishById(String id) async {
    try {
      if (_userWishlistRef == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _userWishlistRef!.doc(id).get();
      
      if (!doc.exists) {
        return null;
      }

      return Wish.fromFirestore(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to get wish: $e');
    }
  }

  /// Update an existing wishlist item
  Future<void> updateWish(String id, Wish wish) async {
    try {
      if (_userWishlistRef == null) {
        throw Exception('User not authenticated');
      }

      await _userWishlistRef!.doc(id).update({
        ...wish.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update wish: $e');
    }
  }

  /// Toggle the completed status of a wish
  Future<void> toggleCompleted(String id, bool completed) async {
    try {
      if (_userWishlistRef == null) {
        throw Exception('User not authenticated');
      }

      await _userWishlistRef!.doc(id).update({
        'completed': completed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle wish completion: $e');
    }
  }

  /// Delete a wishlist item
  Future<void> deleteWish(String id) async {
    try {
      if (_userWishlistRef == null) {
        throw Exception('User not authenticated');
      }

      await _userWishlistRef!.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete wish: $e');
    }
  }

  /// Get wishes by category
  Stream<List<Wish>> getWishesByCategory(String category) {
    if (_userWishlistRef == null) {
      return Stream.value([]);
    }

    return _userWishlistRef!
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Wish.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  /// Get count of completed wishes
  Future<int> getCompletedCount() async {
    try {
      if (_userWishlistRef == null) {
        return 0;
      }

      final snapshot = await _userWishlistRef!
          .where('completed', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get completed count: $e');
    }
  }

  /// Delete all wishes (for testing purposes)
  Future<void> deleteAllWishes() async {
    try {
      if (_userWishlistRef == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _userWishlistRef!.get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete all wishes: $e');
    }
  }
}
