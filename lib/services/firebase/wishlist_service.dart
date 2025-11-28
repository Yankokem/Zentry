import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/wish_model.dart';

/// Service class for managing wishlist items in Firestore
/// Follows the repository pattern for data access
/// 
/// Firestore Structure:
/// wishlists/
///   {wishId}/
///     userId: "user-id"
///     title: "Item Title"
///     price: "99.99"
///     category: "tech"
///     notes: "Notes"
///     dateAdded: "Nov 13, 2025"
///     completed: false
///     createdAt: Timestamp
///     updatedAt: Timestamp
class WishlistService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String wishlistCollection = 'wishlists';

  /// Get the current user's ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get reference to the top-level wishlists collection
  CollectionReference get _wishlistRef => _db.collection(wishlistCollection);

  /// Create a new wishlist item
  /// Returns the document ID of the created item
  Future<String> createWish(Wish wish) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final firestoreData = {
        'userId': _userId, // Store user ID for filtering
        ...wish.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      debugPrint('💾 Saving to Firestore: $firestoreData');
      debugPrint('📧 SharedWith array: ${wish.sharedWith}');

      final docRef = await _wishlistRef.add(firestoreData);

      debugPrint('✅ Document created with ID: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating wish: $e');
      throw Exception('Failed to create wish: $e');
    }
  }

  /// Get all wishlist items for the current user (owned and shared)
  /// Returns a stream that updates in real-time
  Stream<List<Wish>> getWishesStream() {
    if (_userId == null) {
      return Stream.value([]);
    }

    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) {
      return Stream.value([]);
    }

    final controller = StreamController<List<Wish>>();

    // Query for wishes owned by the user
    final ownedWishesStream = _wishlistRef
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    // Query for wishes shared with the user
    final sharedWishesStream = _wishlistRef
        .where('sharedWith', arrayContains: userEmail)
        .snapshots();

    List<Wish> currentOwnedWishes = [];
    List<Wish> currentSharedWishes = [];

    StreamSubscription? ownedSubscription;
    StreamSubscription? sharedSubscription;

    void emitCombined() {
      if (!controller.isClosed) {
        _emitCombinedWishes(controller, currentOwnedWishes, currentSharedWishes);
      }
    }

    ownedSubscription = ownedWishesStream.listen(
      (snapshot) {
        try {
          currentOwnedWishes = snapshot.docs.map((doc) =>
            Wish.fromFirestore(doc.id, doc.data() as Map<String, dynamic>)
          ).toList();
          emitCombined();
        } catch (e) {
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    sharedSubscription = sharedWishesStream.listen(
      (snapshot) {
        try {
          currentSharedWishes = snapshot.docs.map((doc) =>
            Wish.fromFirestore(doc.id, doc.data() as Map<String, dynamic>)
          ).toList();
          emitCombined();
        } catch (e) {
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    controller.onCancel = () async {
      await ownedSubscription?.cancel();
      await sharedSubscription?.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  void _emitCombinedWishes(StreamController<List<Wish>> controller, List<Wish> owned, List<Wish> shared) {
    final allWishes = <String, Wish>{};

    // Add owned wishes
    for (final wish in owned) {
      allWishes[wish.id!] = wish;
    }

    // Add shared wishes (will overwrite if already present)
    for (final wish in shared) {
      allWishes[wish.id!] = wish;
    }

    final sortedWishes = allWishes.values.toList();
    // Sort by createdAt descending (assuming createdAt is a string date)
    sortedWishes.sort((a, b) {
      final aDate = a.dateAdded;
      final bDate = b.dateAdded;
      return bDate.compareTo(aDate);
    });

    controller.add(sortedWishes);
  }

  /// Get all wishlist items (one-time fetch)
  Future<List<Wish>> getWishes() async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _wishlistRef
          .where('userId', isEqualTo: _userId)
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
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _wishlistRef.doc(id).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      
      // Verify the wish belongs to the current user
      if (data['userId'] != _userId) {
        throw Exception('Unauthorized access to wish');
      }

      return Wish.fromFirestore(
        doc.id,
        data,
      );
    } catch (e) {
      throw Exception('Failed to get wish: $e');
    }
  }

  /// Update an existing wishlist item
  Future<void> updateWish(String id, Wish wish) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify ownership before updating
      final existingDoc = await _wishlistRef.doc(id).get();
      if (!existingDoc.exists || existingDoc['userId'] != _userId) {
        throw Exception('Unauthorized: wish not found or does not belong to user');
      }

      await _wishlistRef.doc(id).update({
        ...wish.toFirestore(),
        'userId': _userId, // Ensure userId is maintained
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update wish: $e');
    }
  }

  /// Toggle the completed status of a wish
  Future<void> toggleCompleted(String id, bool completed) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify ownership before updating
      final existingDoc = await _wishlistRef.doc(id).get();
      if (!existingDoc.exists || existingDoc['userId'] != _userId) {
        throw Exception('Unauthorized: wish not found or does not belong to user');
      }

      await _wishlistRef.doc(id).update({
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
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify ownership before deleting
      final existingDoc = await _wishlistRef.doc(id).get();
      if (!existingDoc.exists || existingDoc['userId'] != _userId) {
        throw Exception('Unauthorized: wish not found or does not belong to user');
      }

      await _wishlistRef.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete wish: $e');
    }
  }

  /// Get wishes by category
  Stream<List<Wish>> getWishesByCategory(String category) {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _wishlistRef
        .where('userId', isEqualTo: _userId)
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
      if (_userId == null) {
        return 0;
      }

      final snapshot = await _wishlistRef
          .where('userId', isEqualTo: _userId)
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
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _wishlistRef
          .where('userId', isEqualTo: _userId)
          .get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete all wishes: $e');
    }
  }
}
