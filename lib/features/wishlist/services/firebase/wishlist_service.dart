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

    // Create two separate streams: owned and shared wishes
    final ownedWishesStream = _wishlistRef
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Wish.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
            .toList());

    final sharedWishesStream = _wishlistRef
        .where('sharedWith', arrayContains: userEmail)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Wish.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
            .toList());

    // Combine both streams using Stream.multi for proper real-time synchronization
    return Stream.multi((controller) {
      late StreamSubscription<List<Wish>> ownedSub;
      late StreamSubscription<List<Wish>> sharedSub;

      List<Wish>? lastOwned;
      List<Wish>? lastShared;

      void emitCombined() {
        final owned = lastOwned ?? [];
        final shared = lastShared ?? [];

        final allWishes = <String, Wish>{};

        // Add owned wishes
        for (final wish in owned) {
          allWishes[wish.id!] = wish;
        }

        // Add shared wishes (filter by acceptance status)
        for (final wish in shared) {
          debugPrint('🔎 Checking shared wish: ${wish.title}');
          debugPrint('   acceptedShares: ${wish.acceptedShares.map((s) => '${s.email}:${s.status}').toList()}');
          debugPrint('   isSharedWithAccepted("$userEmail"): ${wish.isSharedWithAccepted(userEmail)}');
          
          if (wish.isSharedWithAccepted(userEmail)) {
            debugPrint('   ✅ Including in results');
            allWishes[wish.id!] = wish;
          } else {
            debugPrint('   ❌ Excluding (not accepted)');
          }
        }

        // Sort by createdAt descending
        final sortedWishes = allWishes.values.toList();
        sortedWishes.sort((a, b) {
          return b.dateAdded.compareTo(a.dateAdded);
        });

        debugPrint('📤 emitCombined emitting ${sortedWishes.length} total wishes');
        controller.add(sortedWishes);
      }

      ownedSub = ownedWishesStream.listen(
        (wishes) {
          lastOwned = wishes;
          emitCombined();
        },
        onError: (error) {
          debugPrint('❌ Error in owned wishes stream: $error');
          controller.addError(error);
        },
      );

      sharedSub = sharedWishesStream.listen(
        (wishes) {
          debugPrint('🎁 Shared wishes stream update: ${wishes.length} wishes');
          for (final wish in wishes) {
            debugPrint('  - Wish: ${wish.title}, email=$userEmail, isAccepted=${wish.isSharedWithAccepted(userEmail)}');
            debugPrint('    sharedWithDetails: ${wish.sharedWithDetails.map((s) => '${s.email}:${s.status}').toList()}');
          }
          lastShared = wishes;
          emitCombined();
        },
        onError: (error) {
          debugPrint('❌ Error in shared wishes stream: $error');
          controller.addError(error);
        },
      );

      // Cleanup when stream is cancelled
      controller.onCancel = () {
        ownedSub.cancel();
        sharedSub.cancel();
      };
    });
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

  // ===== WISHLIST INVITATION OPERATIONS =====

  /// Accept a wishlist sharing invitation
  Future<void> acceptWishlistInvitation(String wishId, String userEmail) async {
    try {
      debugPrint('🎯 acceptWishlistInvitation called for wishId=$wishId, email=$userEmail');
      
      final wishRef = _wishlistRef.doc(wishId);
      final wishDoc = await wishRef.get();
      
      if (!wishDoc.exists) {
        throw Exception('Wish not found');
      }

      final wishData = wishDoc.data() as Map<String, dynamic>;
      debugPrint('📄 Current Firestore data: $wishData');
      
      final sharedWithDetails = (wishData['sharedWithDetails'] as List?)
              ?.map((m) => Map<String, dynamic>.from(m as Map))
              .toList() ??
          [];
      
      debugPrint('📋 Current sharedWithDetails: $sharedWithDetails');
      
      // Also get the current sharedWith array for backward compatibility
      final List<String> sharedWith = List<String>.from(
        (wishData['sharedWith'] as List?) ?? []
      );
      
      debugPrint('📧 Current sharedWith: $sharedWith');

      // Find and update the share status in sharedWithDetails (case-insensitive)
      final shareIndex = sharedWithDetails.indexWhere((s) => s['email'].toString().toLowerCase() == userEmail.toLowerCase());
      debugPrint('🔍 Found share at index: $shareIndex');
      
      if (shareIndex != -1) {
        sharedWithDetails[shareIndex]['status'] = 'accepted';
        sharedWithDetails[shareIndex]['respondedAt'] = DateTime.now().toIso8601String();
        
        debugPrint('✏️ Updated sharedWithDetails["status"] to "accepted"');
        debugPrint('📋 Updated sharedWithDetails: $sharedWithDetails');
        
        // IMPORTANT: Also add the email to sharedWith array if not already there
        // This is critical for the stream query: where('sharedWith', arrayContains: userEmail)
        // Use case-insensitive comparison for safety
        final emailAlreadyExists = sharedWith.any((email) => email.toLowerCase() == userEmail.toLowerCase());
        if (!emailAlreadyExists) {
          sharedWith.add(userEmail.toLowerCase()); // Store lowercase for consistency
          debugPrint('➕ Added email to sharedWith array');
        } else {
          debugPrint('✓ Email already in sharedWith array');
        }

        debugPrint('📤 Updating Firestore with:');
        debugPrint('   sharedWithDetails: $sharedWithDetails');
        debugPrint('   sharedWith: $sharedWith');
        
        await wishRef.update({
          'sharedWithDetails': sharedWithDetails,
          'sharedWith': sharedWith, // Update both arrays for stream to pick it up
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('✅ Firestore update successful');
      } else {
        throw Exception('Invitation not found for email: $userEmail');
      }
    } catch (e) {
      debugPrint('❌ Error in acceptWishlistInvitation: $e');
      throw Exception('Failed to accept wishlist invitation: $e');
    }
  }

  /// Reject a wishlist sharing invitation
  Future<void> rejectWishlistInvitation(String wishId, String userEmail) async {
    try {
      final wishRef = _wishlistRef.doc(wishId);
      final wishDoc = await wishRef.get();
      
      if (!wishDoc.exists) {
        throw Exception('Wish not found');
      }

      final wishData = wishDoc.data() as Map<String, dynamic>;
      final sharedWithDetails = (wishData['sharedWithDetails'] as List?)
              ?.map((m) => Map<String, dynamic>.from(m as Map))
              .toList() ??
          [];

      // Remove the share invitation
      sharedWithDetails.removeWhere((s) => s['email'] == userEmail);
      
      // Also remove from legacy sharedWith array
      final sharedWith = List<String>.from(wishData['sharedWith'] ?? []);
      sharedWith.remove(userEmail);

      await wishRef.update({
        'sharedWith': sharedWith,
        'sharedWithDetails': sharedWithDetails,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject wishlist invitation: $e');
    }
  }
}
