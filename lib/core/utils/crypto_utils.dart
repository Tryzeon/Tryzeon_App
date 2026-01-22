import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Cryptographic utilities for authentication and security operations
class CryptoUtils {
  CryptoUtils._();

  /// Generates a cryptographically secure random nonce
  ///
  /// [length] The length of the nonce to generate (default: 32)
  /// Returns a random string from the charset containing alphanumeric and special characters
  static String generateNonce([final int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Computes SHA-256 hash of the input string
  ///
  /// [input] The string to hash
  /// Returns the hexadecimal representation of the SHA-256 digest
  static String sha256Hash(final String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
