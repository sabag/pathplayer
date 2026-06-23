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
  JellyfinAuth(this._dio);

  final Dio _dio;

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
        headers: {'Authorization': authHeader()},
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

  /// Builds the `Authorization` header required by Jellyfin.
  ///
  /// [token] should be added once authentication has completed.
  static String authHeader({String? token}) {
    final buffer = StringBuffer()
      ..write('MediaBrowser ')
      ..write('Client="PathPlayer", ')
      ..write('Device="Android", ')
      ..write('DeviceId="pathplayer-1", ')
      ..write('Version="1.0.0"');
    if (token != null) {
      buffer.write(', Token="$token"');
    }
    return buffer.toString();
  }
}
