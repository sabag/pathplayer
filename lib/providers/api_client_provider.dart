import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/navidrome_api.dart';

final dioProvider = Provider<Dio>((ref) => createNavidromeDio());

final apiClientProvider = Provider<NavidromeApiClient>(
  (ref) => NavidromeApiClient(dio: ref.watch(dioProvider)),
);
