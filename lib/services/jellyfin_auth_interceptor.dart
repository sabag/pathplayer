import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'auth_token_holder.dart';
import 'jellyfin_auth.dart';

/// Thrown when a 401 response cannot be recovered by re-authenticating.
class AuthRefreshException implements Exception {
  const AuthRefreshException(this.cause);

  final Object cause;

  @override
  String toString() => 'AuthRefreshException: $cause';
}

/// Dio interceptor that injects the Jellyfin access token and silently
/// re-authenticates when the server responds with 401 or 403.
///
/// When re-authentication succeeds, the failed request is retried with the
/// new token and any concurrent requests that also failed are replayed.
/// When re-authentication fails, [onRefreshFailed] is invoked and all
/// pending requests are rejected with [AuthRefreshException].
class JellyfinAuthInterceptor extends Interceptor {
  JellyfinAuthInterceptor({
    required this.dio,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.tokenHolder,
    required this.onRefreshed,
    required this.onRefreshFailed,
  });

  final Dio dio;
  final String serverUrl;
  final String username;
  final String password;
  final AuthTokenHolder tokenHolder;
  final void Function(JellyfinCredentials credentials) onRefreshed;
  final Future<void> Function(Object error) onRefreshFailed;

  Future<JellyfinCredentials>? _refreshFuture;
  final _pendingRequests = <_PendingRequest>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenHolder.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = JellyfinAuth.authHeader(
        token: token,
        deviceId: tokenHolder.deviceId,
      );
    }
    debugPrint(
      '[JellyfinAuthInterceptor] ${options.method} ${options.path} (token=${token != null})',
    );
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    debugPrint(
      '[JellyfinAuthInterceptor] onError: ${err.type} status=$statusCode path=${err.requestOptions.path}',
    );
    if (statusCode != 401 && statusCode != 403) {
      handler.next(err);
      return;
    }

    _pendingRequests.add(_PendingRequest(err, handler));
    debugPrint(
      '[JellyfinAuthInterceptor] queued request; pending=${_pendingRequests.length}',
    );

    _refreshFuture ??= _reauthenticate().whenComplete(() {
      _refreshFuture = null;
    });

    try {
      final credentials = await _refreshFuture!;
      tokenHolder.credentials = credentials;
      onRefreshed(credentials);
      await _retryPendingRequests();
    } catch (e) {
      debugPrint(
        '[JellyfinAuthInterceptor] re-auth failed: $e',
      );
      await onRefreshFailed(e);
      _rejectPendingRequests(e);
    }
  }

  Future<JellyfinCredentials> _reauthenticate() async {
    debugPrint(
      '[JellyfinAuthInterceptor] re-authenticating user=$username deviceId=${tokenHolder.deviceId}',
    );
    final reauthDio = Dio(
      BaseOptions(
        baseUrl: serverUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    try {
      return await JellyfinAuth(reauthDio, deviceId: tokenHolder.deviceId)
          .authenticate(username, password);
    } finally {
      reauthDio.close();
    }
  }

  Future<void> _retryPendingRequests() async {
    final pending = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    debugPrint(
      '[JellyfinAuthInterceptor] retrying ${pending.length} pending requests',
    );
    for (final request in pending) {
      try {
        final response = await dio.fetch<dynamic>(request.error.requestOptions);
        request.handler.resolve(response);
      } catch (e) {
        request.handler.reject(
          e is DioException
              ? e
              : DioException(
                  requestOptions: request.error.requestOptions,
                  error: e,
                  type: DioExceptionType.unknown,
                ),
        );
      }
    }
  }

  void _rejectPendingRequests(Object error) {
    final pending = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    debugPrint(
      '[JellyfinAuthInterceptor] rejecting ${pending.length} pending requests due to $error',
    );
    for (final request in pending) {
      request.handler.reject(
        _wrapRejection(request.error.requestOptions, error),
      );
    }
  }

  DioException _wrapRejection(RequestOptions requestOptions, Object error) {
    if (error is DioException) {
      return error;
    }
    return DioException(
      requestOptions: requestOptions,
      error: AuthRefreshException(error),
      type: DioExceptionType.unknown,
    );
  }
}

class _PendingRequest {
  _PendingRequest(this.error, this.handler);

  final DioException error;
  final ErrorInterceptorHandler handler;
}
