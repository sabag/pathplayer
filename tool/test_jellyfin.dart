// ignore_for_file: avoid_print

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pathplayer/services/jellyfin_api.dart';
import 'package:pathplayer/services/jellyfin_auth.dart';

Future<void> main() async {
  final env = Platform.environment;
  final serverUrl = env['JELLYFIN_URL'] ?? 'http://YOUR_SERVER_IP:8096';
  final username = env['JELLYFIN_USER'] ?? 'YOUR_USERNAME';
  final password = env['JELLYFIN_PASSWORD'] ?? 'YOUR_PASSWORD';

  if (serverUrl.contains('YOUR_') ||
      username.contains('YOUR_') ||
      password.contains('YOUR_')) {
    print('Set the JELLYFIN_URL, JELLYFIN_USER and JELLYFIN_PASSWORD');
    print('environment variables to run this integration test.');
    return;
  }

  final dio = Dio(BaseOptions(baseUrl: serverUrl));
  final credentials = await JellyfinAuth(dio).authenticate(username, password);
  print('Authenticated user: ${credentials.userId}');

  final api = JellyfinApiClient(dio: dio, credentials: credentials);

  print('\n--- Root items ---');
  final root = await api.getTopLevelItems();
  for (final item in root.take(20)) {
    print('  ${item.isFolder ? "[FOLDER]" : "[AUDIO]"} ${item.displayName} (${item.type})');
  }

  final firstFolder = root.firstWhere((item) => item.isFolder);
  print('\n--- Children of ${firstFolder.displayName} ---');
  final children = await api.getChildren(firstFolder.id);
  for (final item in children.take(20)) {
    print('  ${item.isFolder ? "[FOLDER]" : "[AUDIO]"} ${item.displayName}');
  }

  final firstAudio = children.firstWhere(
    (item) => item.isAudio,
    orElse: () => children.expand((c) => c.isAudio ? [c] : []).first,
  );
  print('\n--- Stream URL for ${firstAudio.displayName} ---');
  print(api.streamUrl(firstAudio.id));

  print('\n--- Search for "love" ---');
  final searchResults = await api.search('love');
  for (final item in searchResults.take(10)) {
    print('  ${item.isFolder ? "[FOLDER]" : "[AUDIO]"} ${item.displayName}');
  }
}
