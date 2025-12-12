import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/journal_entry_model.dart';

/// Service class for managing journal entries in Firestore
/// Follows the repository pattern for data access
/// 
/// Firestore Structure:
/// journal_entries/
///   {entryId}/
///     userId: "user-id"
///     title: "Entry Title"
///     content: "Entry content..."
///     date: "Nov 23, 2025"
///     time: "12:00 PM"
///     mood: "calm"
///     createdAt: Timestamp
///     updatedAt: Timestamp
class JournalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String journalCollection = 'journal_entries';

  /// Get the current user's ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get reference to the top-level journal entries collection
  CollectionReference get _journalRef => _db.collection(journalCollection);

  /// Create a new journal entry
  /// Returns the document ID of the created entry
  Future<String> createEntry(JournalEntry entry) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final docData = {
        'userId': _userId,
        'title': entry.title,
        'content': entry.content,
        'date': entry.date,
        'time': entry.time,
        'mood': entry.mood,
        'imageUrls': entry.imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _journalRef.add(docData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create journal entry: $e');
    }
  }

  /// Get all journal entries for the current user
  /// Returns a stream that updates in real-time
  Stream<List<JournalEntry>> getEntriesStream() {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _journalRef
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      // Get entries and sort them locally
      final entries = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return JournalEntry.fromFirestore(doc.id, data);
      }).toList();
      
      // Sort by createdAt timestamp (most recent first). Fallback to epoch if null.
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      entries.sort((a, b) => (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch));
      
      return entries;
    });
  }

  /// Get all journal entries (one-time fetch)
  Future<List<JournalEntry>> getEntries() async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _journalRef
          .where('userId', isEqualTo: _userId)
          .get();

      final entries = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return JournalEntry.fromFirestore(doc.id, data);
      }).toList();
      
      // Sort by createdAt timestamp (most recent first). Fallback to epoch if null.
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      entries.sort((a, b) => (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch));
      
      return entries;
    } catch (e) {
      throw Exception('Failed to get journal entries: $e');
    }
  }

  /// Get a single journal entry by ID
  Future<JournalEntry?> getEntryById(String id) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _journalRef.doc(id).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      
      // Verify the entry belongs to the current user
      if (data['userId'] != _userId) {
        throw Exception('Unauthorized access to journal entry');
      }

      return JournalEntry.fromFirestore(doc.id, data);
    } catch (e) {
      throw Exception('Failed to get journal entry: $e');
    }
  }

  /// Update an existing journal entry
  Future<void> updateEntry(String id, JournalEntry entry) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify ownership before updating
      final existingDoc = await _journalRef.doc(id).get();
      if (!existingDoc.exists || existingDoc['userId'] != _userId) {
        throw Exception('Unauthorized: entry not found or does not belong to user');
      }

      await _journalRef.doc(id).update({
        'userId': _userId,
        'title': entry.title,
        'content': entry.content,
        'date': entry.date,
        'time': entry.time,
        'mood': entry.mood,
        'imageUrls': entry.imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update journal entry: $e');
    }
  }

  /// Delete a journal entry
  Future<void> deleteEntry(String id) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify ownership before deleting
      final existingDoc = await _journalRef.doc(id).get();
      if (!existingDoc.exists || existingDoc['userId'] != _userId) {
        throw Exception('Unauthorized: entry not found or does not belong to user');
      }

      await _journalRef.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete journal entry: $e');
    }
  }

  /// Get entries by mood
  Stream<List<JournalEntry>> getEntriesByMood(String mood) {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _journalRef
        .where('userId', isEqualTo: _userId)
        .where('mood', isEqualTo: mood)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return JournalEntry.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  /// Search entries by title or content
  Future<List<JournalEntry>> searchEntries(String query) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      // Get all user entries (Firestore doesn't support full-text search natively)
      final snapshot = await _journalRef
          .where('userId', isEqualTo: _userId)
          .get();

      final entries = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return JournalEntry.fromFirestore(doc.id, data);
      }).toList();

      // Filter locally
      final lowerQuery = query.toLowerCase();
      return entries.where((entry) {
        return entry.title.toLowerCase().contains(lowerQuery) ||
               entry.content.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search entries: $e');
    }
  }

  /// Get count of entries by mood
  Future<Map<String, int>> getMoodCounts() async {
    try {
      if (_userId == null) {
        return {};
      }

      final snapshot = await _journalRef
          .where('userId', isEqualTo: _userId)
          .get();

      final counts = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final mood = data?['mood'] as String? ?? 'calm';
        counts[mood] = (counts[mood] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get mood counts: $e');
    }
  }

  /// Delete all entries (for testing purposes)
  Future<void> deleteAllEntries() async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _journalRef
          .where('userId', isEqualTo: _userId)
          .get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete all entries: $e');
    }
  }
}
