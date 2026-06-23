import 'package:dio/dio.dart';

import '../config.dart';
import '../models/directory.dart';
import '../models/index.dart';
import '../models/track.dart';
import 'subsonic_auth.dart';

/// Authenticated Subsonic/Navidrome API client.
class NavidromeApiClient {
  NavidromeApiClient({required this._dio});

  final Dio _dio;

  Future<GetIndexesResult> getIndexes() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/rest/getIndexes.view',
    );
    return GetIndexesResult.fromResponse(response.data!);
  }

  Future<Directory> getDirectory(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/rest/getMusicDirectory.view',
      queryParameters: {'id': id},
    );
    return Directory.fromResponse(response.data!);
  }

  Future<Search3Result> search3(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/rest/search3.view',
      queryParameters: {
        'query': query,
        'songCount': 50,
      },
    );
    return Search3Result.fromResponse(response.data!);
  }

  /// Builds a fully authenticated stream URL for a track id.
  ///
  /// Audio players load the URL directly, so the auth parameters must be
  /// embedded in the query string.
  String streamUrl(String id) {
    final salt = SubsonicAuth.generateSalt();
    final token = SubsonicAuth.token(SubsonicConfig.password, salt);
    return Uri.parse('${SubsonicConfig.baseUrl}/rest/stream.view')
        .replace(
          queryParameters: {
            'id': id,
            'u': SubsonicConfig.username,
            'v': SubsonicAuth.apiVersion,
            'c': SubsonicAuth.clientId,
            'f': 'json',
            's': salt,
            't': token,
          },
        )
        .toString();
  }
}

/// Injects Subsonic authentication parameters into every outgoing request.
class _SubsonicAuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final salt = SubsonicAuth.generateSalt();
    final token = SubsonicAuth.token(SubsonicConfig.password, salt);

    options.queryParameters.addAll({
      'u': SubsonicConfig.username,
      'v': SubsonicAuth.apiVersion,
      'c': SubsonicAuth.clientId,
      'f': 'json',
      's': salt,
      't': token,
    });

    handler.next(options);
  }
}

/// Creates a [Dio] instance configured for the Navidrome server.
Dio createNavidromeDio() {
  return Dio(
    BaseOptions(
      baseUrl: SubsonicConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  )..interceptors.add(_SubsonicAuthInterceptor());
}
