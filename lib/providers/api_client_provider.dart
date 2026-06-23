import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../services/jellyfin_api.dart';

final dioProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      baseUrl: JellyfinConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  ),
);

/// This provider must be overridden with an authenticated client
/// before the app is run.
final apiClientProvider = Provider<JellyfinApiClient>(
  (ref) => throw UnsupportedError(
    'apiClientProvider must be overridden after authenticating',
  ),
);
