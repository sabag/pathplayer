import 'jellyfin_auth.dart';

/// Holds the current Jellyfin authentication credentials in memory.
///
/// This object is shared between the Dio interceptor and the API client so
/// that both read the same token and userId. The interceptor updates it when
/// it silently re-authenticates after a 401.
class AuthTokenHolder {
  AuthTokenHolder({required this.deviceId});

  /// The unique device id used in Jellyfin's Authorization header.
  final String deviceId;

  JellyfinCredentials? _credentials;

  /// Current authenticated user credentials, or null when not authenticated.
  JellyfinCredentials? get credentials => _credentials;

  /// Updates the credentials, typically after login or silent re-auth.
  set credentials(JellyfinCredentials? value) => _credentials = value;

  /// The current access token, or null when not authenticated.
  String? get accessToken => _credentials?.accessToken;

  /// The current user id, or null when not authenticated.
  String? get userId => _credentials?.userId;

  /// Whether valid credentials are currently held.
  bool get isAuthenticated => _credentials != null;
}
