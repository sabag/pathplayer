import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/jellyfin_item.dart';
import 'api_client_provider.dart';

final directoryProvider = FutureProvider.family.autoDispose<List<JellyfinItem>, String>(
  (ref, id) => ref.watch(apiClientProvider).getChildren(id),
);
