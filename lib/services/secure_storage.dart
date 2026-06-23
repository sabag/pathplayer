import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/server_credentials.dart';

/// Stores Jellyfin server credentials in the platform secure keychain/keystore.
class SecureStorageService {
  const SecureStorageService();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _serverUrlKey = 'server_url';
  static const _usernameKey = 'username';
  static const _passwordKey = 'password';

  /// Reads saved credentials, if any.
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

  /// Persists credentials.
  Future<void> write(ServerCredentials credentials) async {
    await _storage.write(key: _serverUrlKey, value: credentials.serverUrl);
    await _storage.write(key: _usernameKey, value: credentials.username);
    await _storage.write(key: _passwordKey, value: credentials.password);
  }

  /// Removes persisted credentials.
  Future<void> delete() async {
    await _storage.delete(key: _serverUrlKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
  }
}
