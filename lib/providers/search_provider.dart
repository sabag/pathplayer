import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track.dart';
import 'api_client_provider.dart';

final searchProvider =
    FutureProvider.family.autoDispose<Search3Result, String>(
  (ref, query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const Search3Result(songs: []);
    return ref.watch(apiClientProvider).search3(trimmed);
  },
);
