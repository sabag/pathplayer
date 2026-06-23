import 'package:flutter/foundation.dart';

/// Server credentials entered by the user and persisted securely.
@immutable
class ServerCredentials {
  const ServerCredentials({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  final String serverUrl;
  final String username;
  final String password;

  ServerCredentials copyWith({
    String? serverUrl,
    String? username,
    String? password,
  }) {
    return ServerCredentials(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}
