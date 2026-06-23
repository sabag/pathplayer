import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_handler.dart';
import '../audio/audio_service.dart';
import '../models/server_credentials.dart';
import '../services/jellyfin_api.dart';
import '../services/jellyfin_auth.dart';
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
  });

  final Dio dio;
  final JellyfinApiClient api;
  final AudioPlayerHandler handler;
  final JellyfinCredentials credentials;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._storage) : super(const AuthLoading()) {
    _init();
  }

  final SecureStorageService _storage;

  Future<void> _init() async {
    final saved = await _storage.read();
    if (saved == null) {
      state = const AuthUnauthenticated();
      return;
    }

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

      final jellyfinAuth = JellyfinAuth(dio);
      final authCredentials = await jellyfinAuth.authenticate(
        credentials.username,
        credentials.password,
      );

      final api = JellyfinApiClient(
        dio: dio,
        credentials: authCredentials,
      );
      final handler = await initAudioService(api);

      await _storage.write(credentials);

      state = AuthAuthenticated(
        dio: dio,
        api: api,
        handler: handler,
        credentials: authCredentials,
      );
    } catch (e) {
      dio?.close();
      state = AuthUnauthenticated(
        prefillUrl: credentials.serverUrl,
        prefillUsername: credentials.username,
        error: _humanReadableError(e),
      );
    }
  }

  /// Clears saved credentials and returns to the login screen.
  Future<void> logout() async {
    if (state is AuthAuthenticated) {
      final authenticated = state as AuthAuthenticated;
      await authenticated.handler.stop();
      authenticated.dio.close();
    }

    await _storage.delete();
    state = const AuthUnauthenticated();
  }

  String _humanReadableError(Object error) {
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
