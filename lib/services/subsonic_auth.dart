import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Helpers for Subsonic's token-and-salt authentication scheme.
class SubsonicAuth {
  SubsonicAuth._();

  static const String apiVersion = '1.16.1';
  static const String clientId = 'PathPlayer';

  static final Random _random = Random.secure();

  /// Generates a random 16-character hexadecimal salt.
  static String generateSalt() {
    final bytes = List<int>.generate(8, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Computes `md5(password + salt)`.
  static String token(String password, String salt) {
    final bytes = utf8.encode('$password$salt');
    return md5.convert(bytes).toString();
  }
}
