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

      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      // If decryption fails, show a placeholder message instead of encrypted text
      return '[Unable to decrypt - please re-enter this entry]';
    }
  }

  /// Hash text using SHA-256 (one-way, for verification)
  static String hashText(String text) {
    final bytes = utf8.encode(text);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if text appears to be encrypted
  static bool isEncrypted(String text) {
    // Base64 strings typically contain only alphanumeric chars, +, /, and =
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');
    return base64Pattern.hasMatch(text) && text.length > 20;
  }
}
