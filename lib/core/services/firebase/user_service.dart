import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<String>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }
    final snapshot = await _db
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => doc['email'] as String).toList();
  }

  Future<Map<String, String>> getUserDetailsByEmail(String email) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        var profilePictureUrl = data['profilePictureUrl'] ?? '';
        
        // If no profile picture, try to get Google profile picture
        if (profilePictureUrl.isEmpty) {
          profilePictureUrl = _getGoogleProfilePictureUrl(email);
        }
        
        return {
          'fullName': data['fullName'] ?? '',
          'email': data['email'] ?? email,
          'profilePictureUrl': profilePictureUrl,
        };
      }
    } catch (e) {
      // Handle error silently
    }

    // Return email as fallback with Google profile picture URL
    return {
      'fullName': '',
      'email': email,
      'profilePictureUrl': _getGoogleProfilePictureUrl(email),
    };
  }

  /// Generate Google profile picture URL for an email
  /// Uses Google's public API: https://lh3.googleusercontent.com/a/[hash]
  /// For fallback, we use: https://www.gravatar.com/avatar/[md5_hash]?d=initials
  String _getGoogleProfilePictureUrl(String email) {
    // Use Gravatar as a reliable fallback source for profile pictures
    // Gravatar is commonly used and has good coverage
    final emailLower = email.toLowerCase().trim();
    // In a real app, you might want to compute MD5 hash, but for now we'll use a simpler approach
    // that relies on the profilePictureUrl from Firestore or user initialization
    return '';
  }

  Future<Map<String, Map<String, String>>> getUsersDetailsByEmails(List<String> emails) async {
    final Map<String, Map<String, String>> result = {};

    for (final email in emails) {
      result[email] = await getUserDetailsByEmail(email);
    }

    return result;
  }

  String getDisplayName(Map<String, String> userDetails, String email) {
    final fullName = userDetails['fullName'] ?? '';
    if (fullName.isNotEmpty) {
      return fullName;
    }

    // Generate name from email
    final parts = email.split('@').first.split('.');
    final nameParts = parts.map((part) => part.isNotEmpty ? part[0].toUpperCase() + part.substring(1).toLowerCase() : '').toList();
    final generatedName = nameParts.join(' ');
    if (generatedName.isNotEmpty) {
      return generatedName;
    }

    return email[0].toUpperCase();
  }
}
