// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:pathplayer/config.dart';
import 'package:pathplayer/services/jellyfin_api.dart';
import 'package:pathplayer/services/jellyfin_auth.dart';

Future<void> main() async {
  final dio = Dio(BaseOptions(baseUrl: JellyfinConfig.baseUrl));
  final credentials = await JellyfinAuth(dio).authenticate();
  print('Authenticated user: ${credentials.userId}');

  final api = JellyfinApiClient(dio: dio, credentials: credentials);

  print('\n--- Root items ---');
  final root = await api.getTopLevelItems();
  for (final item in root.take(20)) {
    print('  ${item.isFolder ? "[FOLDER]" : "[AUDIO]"} ${item.name} (${item.type})');
  }

  final firstFolder = root.firstWhere((item) => item.isFolder);
  print('\n--- Children of ${firstFolder.name} ---');
  final children = await api.getChildren(firstFolder.id);
  for (final item in children.take(20)) {
    print('  ${item.isFolder ? "[FOLDER]" : "[AUDIO]"} ${item.name}');
  }

  final firstAudio = children.firstWhere(
    (item) => item.isAudio,
    orElse: () => children.expand((c) => c.isAudio ? [c] : []).first,
  );
  print('\n--- Stream URL for ${firstAudio.name} ---');
  print(api.streamUrl(firstAudio.id));

  print('\n--- Search for "love" ---');
  final searchResults = await api.search('love');
  for (final item in searchResults.take(10)) {
    print('  ${item.isFolder ? "[FOLDER]" : "[AUDIO]"} ${item.name}');
  }
}
