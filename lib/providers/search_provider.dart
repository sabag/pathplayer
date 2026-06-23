import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/jellyfin_item.dart';
import 'auth_controller.dart';

final searchProvider =
    FutureProvider.family.autoDispose<List<JellyfinItem>, String>(
  (ref, query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    return ref.watch(apiClientProvider).search(trimmed);
  },
);
