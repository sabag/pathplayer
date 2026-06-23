import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/jellyfin_item.dart';
import 'auth_controller.dart';

final directoryProvider = FutureProvider.family.autoDispose<List<JellyfinItem>, String>(
  (ref, id) => ref.watch(apiClientProvider).getChildren(id),
);
