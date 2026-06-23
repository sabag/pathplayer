import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/index.dart';
import 'api_client_provider.dart';

final rootIndexesProvider = FutureProvider.autoDispose<GetIndexesResult>(
  (ref) => ref.watch(apiClientProvider).getIndexes(),
);
