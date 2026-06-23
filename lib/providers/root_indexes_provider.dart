import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/jellyfin_item.dart';
import 'api_client_provider.dart';

final rootItemsProvider = FutureProvider.autoDispose<List<JellyfinItem>>(
  (ref) => ref.watch(apiClientProvider).getTopLevelItems(),
);
