import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/directory.dart';
import 'api_client_provider.dart';

final directoryProvider = FutureProvider.family.autoDispose<Directory, String>(
  (ref, id) => ref.watch(apiClientProvider).getDirectory(id),
);
