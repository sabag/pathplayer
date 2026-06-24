import 'package:dio/dio.dart';

/// Credentials returned by Jellyfin after authenticating by name.
class JellyfinCredentials {
  const JellyfinCredentials({
    required this.userId,
    required this.accessToken,
  });

  final String userId;
  final String accessToken;
}

/// Handles Jellyfin user authentication.
class JellyfinAuth {
  JellyfinAuth(
    this._dio, {
    required this.deviceId,
    required this.deviceName,
    required this.clientVersion,
  });

  final Dio _dio;
  final String deviceId;
  final String deviceName;
  final String clientVersion;

  Future<JellyfinCredentials> authenticate(
    String username,
    String password,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/Users/AuthenticateByName',
      data: {
        'Username': username,
        'Pw': password,
      },
      options: Options(
        headers: {
          'Authorization': authHeader(
            deviceId: deviceId,
            deviceName: deviceName,
            clientVersion: clientVersion,
          ),
        },
        contentType: 'application/json',
      ),
    );

    final data = response.data!;
    final user = data['User'] as Map<String, dynamic>;
    final token = data['AccessToken'] as String;

    return JellyfinCredentials(
      userId: user['Id'] as String,
      accessToken: token,
    );
  }

  /// Logs out the current session on the Jellyfin server.
  Future<void> logout({required String token}) async {
    await _dio.post<Map<String, dynamic>>(
      '/Sessions/Logout',
      options: Options(
        headers: {
          'Authorization': authHeader(
            token: token,
            deviceId: deviceId,
            deviceName: deviceName,
            clientVersion: clientVersion,
          ),
        },
      ),
    );
  }

  /// Builds the `Authorization` header required by Jellyfin.
  ///
  /// [token] should be added once authentication has completed.
  static String authHeader({
    String? token,
    required String deviceId,
    required String deviceName,
    required String clientVersion,
  }) {
    final buffer = StringBuffer()
      ..write('MediaBrowser ')
      ..write('Client="PathPlayer", ')
      ..write('Device="$deviceName", ')
      ..write('DeviceId="$deviceId", ')
      ..write('Version="$clientVersion"');
    if (token != null) {
      buffer.write(', Token="$token"');
    }
    return buffer.toString();
  }
}
