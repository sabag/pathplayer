import 'package:dio/dio.dart';

import '../services/jellyfin_auth_interceptor.dart';

/// Returns a user-friendly message for errors surfaced by API providers.
///
/// This is intended for errors that appear on browse/search/directory screens.
/// Login-screen errors are handled separately by [AuthController] because a 401
/// there means "wrong password" rather than "session expired".
String apiErrorMessage(Object error) {
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
      return 'Session expired. Please log in again.';
    }
    if (statusCode != null) {
      return 'Server returned HTTP $statusCode.';
    }
    return 'Network error: ${error.message}';
  }
  return 'Something went wrong. Please try again.';
}
