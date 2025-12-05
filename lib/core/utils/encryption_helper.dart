import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// Helper class for encrypting and decrypting journal entries
/// Uses AES encryption for privacy
class EncryptionHelper {
  // In production, this key should be stored securely (e.g., Flutter Secure Storage)
  // and be unique per user. For now, we'll use a fixed 256-bit key for demonstration.
  // TODO: Generate unique key per user and store securely
  // Create a 256-bit key (32 bytes) using a secure method
  static final _key = _generateKey();
  static final _iv = encrypt.IV.fromLength(16);

  static encrypt.Key _generateKey() {
    // Use SHA-256 hash of a secret string to generate exactly 32 bytes
    const secretString = 'my-secret-key-for-journal-encryption-2025';
    final bytes = sha256.convert(utf8.encode(secretString)).bytes;
    return encrypt.Key(Uint8List.fromList(bytes));
  }

  /// Encrypt text using AES
  static String encryptText(String plainText) {
    if (plainText.isEmpty) return plainText;
    
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypt text using AES
  static String decryptText(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;
    
    try {
      // Handle legacy encryption error marker
      if (encryptedText.startsWith('ENC_ERROR:')) {
        return encryptedText.substring(10);
      }

      // Check if it's already plain text (not base64 encoded)
      if (!_looksLikeBase64(encryptedText)) {
        // Likely plain text from before encryption was implemented
        return encryptedText;
      }

      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      // Decryption failed - could be corrupted data or wrong key
      // Return a message that allows the user to edit and re-save
      return '[Unable to decrypt - please re-enter this entry]';
    }
  }

  /// Check if text looks like base64-encoded data
  static bool _looksLikeBase64(String text) {
    // Base64 strings contain only A-Z, a-z, 0-9, +, /, and = (padding)
    // Must be at least 16 chars (minimum encrypted string length)
    if (text.length < 16) return false;
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/]+=*$');
    return base64Pattern.hasMatch(text);
  }

  /// Hash text using SHA-256 (one-way, for verification)
  static String hashText(String text) {
    final bytes = utf8.encode(text);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if text appears to be encrypted
  static bool isEncrypted(String text) {
    return _looksLikeBase64(text);
  }
}
