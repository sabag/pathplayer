import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/server_credentials.dart';
import 'jellyfin_auth.dart';

/// Stores Jellyfin server credentials and authentication state in the platform
/// secure keychain/keystore.
class SecureStorageService {
  const SecureStorageService();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _serverUrlKey = 'server_url';
  static const _usernameKey = 'username';
  static const _passwordKey = 'password';
  static const _userIdKey = 'jellyfin_user_id';
  static const _accessTokenKey = 'jellyfin_access_token';
  static const _deviceIdKey = 'jellyfin_device_id';

  /// Reads saved server credentials, if any.
  Future<ServerCredentials?> read() async {
    final serverUrl = await _storage.read(key: _serverUrlKey);
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);

    if (serverUrl == null ||
        serverUrl.isEmpty ||
        username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }

    return ServerCredentials(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
  }

  /// Persists server credentials.
  Future<void> write(ServerCredentials credentials) async {
    await _storage.write(key: _serverUrlKey, value: credentials.serverUrl);
    await _storage.write(key: _usernameKey, value: credentials.username);
    await _storage.write(key: _passwordKey, value: credentials.password);
  }

  /// Reads saved Jellyfin authentication credentials, if any.
  Future<JellyfinCredentials?> readAuth() async {
    final userId = await _storage.read(key: _userIdKey);
    final accessToken = await _storage.read(key: _accessTokenKey);

    if (userId == null ||
        userId.isEmpty ||
        accessToken == null ||
        accessToken.isEmpty) {
      return null;
    }

    return JellyfinCredentials(
      userId: userId,
      accessToken: accessToken,
    );
  }

  /// Persists Jellyfin authentication credentials.
  Future<void> writeAuth(JellyfinCredentials credentials) async {
    await _storage.write(key: _userIdKey, value: credentials.userId);
    await _storage.write(key: _accessTokenKey, value: credentials.accessToken);
  }

  /// Reads the persisted device id, generating and storing one if needed.
  Future<String> readOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final deviceId = _generateDeviceId();
    await _storage.write(key: _deviceIdKey, value: deviceId);
    return deviceId;
  }

  /// Removes all persisted credentials and authentication state.
  Future<void> delete() async {
    await _storage.delete(key: _serverUrlKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _deviceIdKey);
  }

  String _generateDeviceId() {
    // Generate a reasonably unique device id without adding a dependency.
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure().nextInt(0x7fffffff);
    return 'pathplayer-${now.toRadixString(36)}-${random.toRadixString(36)}';
  }
}
