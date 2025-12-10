import 'package:cloud_firestore/cloud_firestore.dart';

/// One-time script to initialize user_metadata for all existing users in Firebase.
/// This should be run once after implementing the account management system.
/// 
/// Usage:
/// 1. Create a temporary button in your admin panel
/// 2. Call this function when clicked
/// 3. Wait for completion
/// 4. Remove the button after successful execution
class UserMetadataInitializer {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Initialize metadata for all existing users who don't have it yet
  Future<Map<String, dynamic>> initializeAllUsersMetadata() async {
    int successCount = 0;
    int skipCount = 0;
    int errorCount = 0;
    final List<String> errors = [];

    try {
      // ignore: avoid_print
      print('Starting user metadata initialization...');

      // Get all users from the users collection
      final usersSnapshot = await _db.collection('users').get();
      // ignore: avoid_print
      print('Found ${usersSnapshot.docs.length} users');

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        try {
          // Check if metadata already exists
          final metadataDoc = await _db
              .collection('user_metadata')
              .doc(userId)
              .get();

          if (metadataDoc.exists) {
            // ignore: avoid_print
            print('Skipping $userId - metadata already exists');
            skipCount++;
            continue;
          }

          // Create initial metadata
          await _db.collection('user_metadata').doc(userId).set({
            'status': 'active',
            'lastActive': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // ignore: avoid_print
          print('✓ Initialized metadata for $userId');
          successCount++;

          // Add a small delay to avoid overwhelming Firestore
          await Future.delayed(const Duration(milliseconds: 100));

        } catch (e) {
          // ignore: avoid_print
          print('✗ Error initializing metadata for $userId: $e');
          errors.add('$userId: $e');
          errorCount++;
        }
      }

      // ignore: avoid_print
      print('\n========================================');
      // ignore: avoid_print
      print('Initialization Complete!');
      // ignore: avoid_print
      print('========================================');
      // ignore: avoid_print
      print('Success: $successCount');
      // ignore: avoid_print
      print('Skipped: $skipCount');
      // ignore: avoid_print
      print('Errors: $errorCount');
      // ignore: avoid_print
      print('========================================\n');

      if (errors.isNotEmpty) {
        // ignore: avoid_print
        print('Error Details:');
        for (final error in errors) {
          // ignore: avoid_print
          print('- $error');
        }
      }

      return {
        'success': errorCount == 0,
        'successCount': successCount,
        'skipCount': skipCount,
        'errorCount': errorCount,
        'errors': errors,
        'message': errorCount == 0
            ? 'All users initialized successfully!'
            : 'Initialization completed with $errorCount errors. Check console for details.',
      };

    } catch (e) {
      // ignore: avoid_print
      print('Fatal error during initialization: $e');
      return {
        'success': false,
        'successCount': successCount,
        'skipCount': skipCount,
        'errorCount': errorCount + 1,
        'errors': [...errors, 'Fatal: $e'],
        'message': 'Initialization failed: $e',
      };
    }
  }

  /// Initialize metadata for a specific user
  Future<bool> initializeSingleUser(String userId) async {
    try {
      // Check if metadata already exists
      final metadataDoc = await _db
          .collection('user_metadata')
          .doc(userId)
          .get();

      if (metadataDoc.exists) {
        // ignore: avoid_print
        print('User $userId already has metadata');
        return true;
      }

      // Create initial metadata
      await _db.collection('user_metadata').doc(userId).set({
        'role': 'member',
        'status': 'active',
        'lastActive': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ignore: avoid_print
      print('Successfully initialized metadata for $userId');
      return true;

    } catch (e) {
      // ignore: avoid_print
      print('Error initializing metadata for $userId: $e');
      return false;
    }
  }

  /// Check how many users need metadata initialization
  Future<Map<String, int>> checkInitializationStatus() async {
    try {
      final usersSnapshot = await _db.collection('users').get();
      final metadataSnapshot = await _db.collection('user_metadata').get();

      final totalUsers = usersSnapshot.docs.length;
      final usersWithMetadata = metadataSnapshot.docs.length;
      final usersNeedingMetadata = totalUsers - usersWithMetadata;

      // ignore: avoid_print
      print('Total users: $totalUsers');
      // ignore: avoid_print
      print('Users with metadata: $usersWithMetadata');
      // ignore: avoid_print
      print('Users needing metadata: $usersNeedingMetadata');

      return {
        'totalUsers': totalUsers,
        'usersWithMetadata': usersWithMetadata,
        'usersNeedingMetadata': usersNeedingMetadata,
      };
    } catch (e) {
      // ignore: avoid_print
      print('Error checking initialization status: $e');
      return {
        'totalUsers': 0,
        'usersWithMetadata': 0,
        'usersNeedingMetadata': 0,
      };
    }
  }
}
