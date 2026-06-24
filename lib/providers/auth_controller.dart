// ignore_for_file: must_be_immutable

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_handler.dart';
import '../audio/audio_service.dart';
import '../models/server_credentials.dart';
import '../services/auth_token_holder.dart';
import '../services/jellyfin_api.dart';
import '../services/jellyfin_auth.dart';
import '../services/jellyfin_auth_interceptor.dart';
import '../services/secure_storage.dart';

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => const SecureStorageService(),
);

/// Current authentication status of the app.
@immutable
sealed class AuthState {
  const AuthState();
}

/// Credentials are being loaded or authentication is in progress.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// No valid session exists; show the login screen.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({
    this.prefillUrl,
    this.prefillUsername,
    this.error,
  });

  final String? prefillUrl;
  final String? prefillUsername;
  final String? error;
}

/// Authentication succeeded; the app can be shown.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({
    required this.dio,
    required this.api,
    required this.handler,
    required this.credentials,
    required this.tokenHolder,
  });

  final Dio dio;
  final JellyfinApiClient api;
  final AudioPlayerHandler handler;
  final JellyfinCredentials credentials;
  final AuthTokenHolder tokenHolder;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._storage) : super(const AuthLoading()) {
    _init();
  }

  final SecureStorageService _storage;
  String? _deviceId;

  Future<String> get _deviceIdOrCreate async {
    _deviceId ??= await _storage.readOrCreateDeviceId();
    return _deviceId!;
  }

  Future<void> _init() async {
    await _deviceIdOrCreate;

    final saved = await _storage.read();
    if (saved == null) {
      debugPrint('[AuthController] no saved credentials');
      state = const AuthUnauthenticated();
      return;
    }

    final savedAuth = await _storage.readAuth();
    if (savedAuth != null) {
      debugPrint(
        '[AuthController] resuming session userId=${savedAuth.userId} token=${savedAuth.accessToken.isNotEmpty}',
      );
      await _resumeSession(saved, savedAuth);
      return;
    }

    debugPrint('[AuthController] no saved token, logging in with password');
    await _login(saved);
  }

  /// Attempts to log in with the supplied credentials and, on success, persists
  /// them so the user is not prompted again until logout.
  Future<void> login(ServerCredentials credentials) async {
    state = const AuthLoading();
    await _login(credentials);
  }

  Future<void> _login(ServerCredentials credentials) async {
    Dio? dio;
    try {
      dio = Dio(
        BaseOptions(
          baseUrl: credentials.serverUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final deviceId = await _deviceIdOrCreate;
      final tokenHolder = AuthTokenHolder(deviceId: deviceId);
      final authCredentials = await JellyfinAuth(dio, deviceId: deviceId)
          .authenticate(credentials.username, credentials.password);
      tokenHolder.credentials = authCredentials;
      debugPrint(
        '[AuthController] login succeeded userId=${authCredentials.userId}',
      );

      _attachAuthInterceptor(dio, credentials, tokenHolder);
      await _enterAuthenticatedState(
        dio: dio,
        tokenHolder: tokenHolder,
        serverCredentials: credentials,
        authCredentials: authCredentials,
      );
    } catch (e) {
      debugPrint('[AuthController] login failed: $e');
      dio?.close();
      state = AuthUnauthenticated(
        prefillUrl: credentials.serverUrl,
        prefillUsername: credentials.username,
        error: _humanReadableError(e),
      );
    }
  }

  /// Restores an existing session from a persisted access token.
  ///
  /// If the token is no longer valid, the auth interceptor will silently
  /// re-authenticate on the first API call using the saved password.
  Future<void> _resumeSession(
    ServerCredentials credentials,
    JellyfinCredentials auth,
  ) async {
    final deviceId = await _deviceIdOrCreate;
    final tokenHolder = AuthTokenHolder(deviceId: deviceId)
      ..credentials = auth;
    final dio = _createDio(credentials, tokenHolder);
    debugPrint(
      '[AuthController] session resumed with interceptor attached',
    );

    await _enterAuthenticatedState(
      dio: dio,
      tokenHolder: tokenHolder,
      serverCredentials: credentials,
      authCredentials: auth,
    );
  }

  Future<void> _enterAuthenticatedState({
    required Dio dio,
    required AuthTokenHolder tokenHolder,
    required ServerCredentials serverCredentials,
    required JellyfinCredentials authCredentials,
  }) async {
    final api = JellyfinApiClient(dio: dio, tokenHolder: tokenHolder);
    final handler = await initAudioService(api);

    await _storage.write(serverCredentials);
    await _storage.writeAuth(authCredentials);

    state = AuthAuthenticated(
      dio: dio,
      api: api,
      handler: handler,
      credentials: authCredentials,
      tokenHolder: tokenHolder,
    );
  }

  Dio _createDio(ServerCredentials credentials, AuthTokenHolder tokenHolder) {
    final dio = Dio(
      BaseOptions(
        baseUrl: credentials.serverUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    _attachAuthInterceptor(dio, credentials, tokenHolder);
    return dio;
  }

  void _attachAuthInterceptor(
    Dio dio,
    ServerCredentials credentials,
    AuthTokenHolder tokenHolder,
  ) {
    debugPrint('[AuthController] attaching auth interceptor');
    final interceptor = JellyfinAuthInterceptor(
      dio: dio,
      serverUrl: credentials.serverUrl,
      username: credentials.username,
      password: credentials.password,
      tokenHolder: tokenHolder,
      onRefreshed: _onTokenRefreshed,
      onRefreshFailed: _onRefreshFailed,
    );
    dio.interceptors.add(interceptor);
  }

  Future<void> _onTokenRefreshed(JellyfinCredentials credentials) async {
    debugPrint(
      '[AuthController] token refreshed userId=${credentials.userId}',
    );
    await _storage.writeAuth(credentials);
    if (state is AuthAuthenticated) {
      final authenticated = state as AuthAuthenticated;
      authenticated.tokenHolder.credentials = credentials;
      state = AuthAuthenticated(
        dio: authenticated.dio,
        api: authenticated.api,
        handler: authenticated.handler,
        credentials: credentials,
        tokenHolder: authenticated.tokenHolder,
      );
    }
  }

  Future<void> _onRefreshFailed(Object error) async {
    debugPrint('[AuthController] refresh failed: $error');
    await _clearSession(
      error: _humanReadableError(AuthRefreshException(error)),
    );
  }

  /// Clears saved credentials and returns to the login screen.
  Future<void> logout() async {
    if (state is AuthAuthenticated) {
      final authenticated = state as AuthAuthenticated;
      final token = authenticated.tokenHolder.accessToken;
      if (token != null && token.isNotEmpty) {
        try {
          final logoutDio = Dio(
            BaseOptions(baseUrl: authenticated.dio.options.baseUrl),
          );
          final deviceId = await _deviceIdOrCreate;
          await JellyfinAuth(logoutDio, deviceId: deviceId)
              .logout(token: token);
          logoutDio.close();
        } catch (_) {
          // Ignore server-side logout failures; local state must still clear.
        }
      }
      await authenticated.handler.stop();
      authenticated.dio.close();
    }

    await _storage.delete();
    state = const AuthUnauthenticated();
  }

  Future<void> _clearSession({String? error}) async {
    debugPrint('[AuthController] clearing session; error=$error');
    if (state is AuthAuthenticated) {
      final authenticated = state as AuthAuthenticated;
      await authenticated.handler.stop();
      authenticated.dio.close();
    }

    await _storage.delete();
    state = AuthUnauthenticated(error: error);
  }

  String _humanReadableError(Object error) {
    if (error is AuthRefreshException) {
      return 'Session expired. Please log in again.';
    }
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Could not reach the server. Check the URL and network.';
      }
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return 'Invalid username or password.';
      }
      if (statusCode != null) {
        return 'Server returned HTTP $statusCode.';
      }
      return 'Network error: ${error.message}';
    }
    return error.toString();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(secureStorageProvider));
});

final dioProvider = Provider<Dio>((ref) {
  final state = ref.watch(authControllerProvider);
  if (state is AuthAuthenticated) {
    return state.dio;
  }
  throw StateError('No authenticated Dio available');
});

final apiClientProvider = Provider<JellyfinApiClient>((ref) {
  final state = ref.watch(authControllerProvider);
  if (state is AuthAuthenticated) {
    return state.api;
  }
  throw StateError('No authenticated API client available');
});

final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  final state = ref.watch(authControllerProvider);
  if (state is AuthAuthenticated) {
    return state.handler;
  }
  throw StateError('No authenticated audio handler available');
});
