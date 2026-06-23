import 'package:dio/dio.dart';

import '../models/jellyfin_item.dart';
import 'jellyfin_auth.dart';

/// Authenticated Jellyfin API client for folder-based browsing.
class JellyfinApiClient {
  JellyfinApiClient({required this.dio, required this.credentials});

  final Dio dio;
  final JellyfinCredentials credentials;

  Map<String, dynamic> get _authHeaders => {
        'Authorization': JellyfinAuth.authHeader(token: credentials.accessToken),
      };

  /// Returns the top-level music libraries, or the contents of the single
  /// music library when only one exists.
  Future<List<JellyfinItem>> getTopLevelItems() async {
    final folders = await _getItems();
    final musicFolders = folders
        .where((item) => item.isFolder && item.collectionType == 'music')
        .toList();

    if (musicFolders.isEmpty) {
      throw Exception('No music library found');
    }

    // If there is only one music library, open it directly.
    // Otherwise show the list of libraries so the user can pick.
    if (musicFolders.length == 1) {
      return getChildren(musicFolders.first.id);
    }

    return musicFolders;
  }

  /// Returns the immediate children of [parentId].
  Future<List<JellyfinItem>> getChildren(String parentId) async {
    return _getItems(parentId: parentId);
  }

  /// Returns every audio file under [parentId], recursively.
  Future<List<JellyfinItem>> getRecursiveAudio(String parentId) async {
    return _getItems(
      parentId: parentId,
      recursive: true,
      includeItemTypes: const ['Audio'],
      limit: 5000,
    );
  }

  /// Searches for audio items matching [query].
  Future<List<JellyfinItem>> search(String query) async {
    final results = await _getItems(
      searchTerm: query.trim(),
      recursive: true,
      includeItemTypes: const ['Audio', 'MusicAlbum', 'MusicArtist'],
      limit: 100,
    );
    return results;
  }

  /// Builds a direct static stream URL for an audio [itemId].
  String streamUrl(String itemId) {
    final base = dio.options.baseUrl;
    return '$base/Audio/$itemId/stream'
        '?static=true&api_key=${credentials.accessToken}';
  }

  Future<List<JellyfinItem>> _getItems({
    String? parentId,
    String? searchTerm,
    bool recursive = false,
    List<String>? includeItemTypes,
    int limit = 300,
  }) async {
    final query = <String, dynamic>{
      'UserId': credentials.userId,
      'Limit': limit,
      'Recursive': recursive,
      'ParentId': parentId,
      'searchTerm': searchTerm,
      'IncludeItemTypes': includeItemTypes?.join(','),
      'Fields': 'BasicInfo,Path',
    }..removeWhere((_, value) => value == null);

    final response = await dio.get<Map<String, dynamic>>(
      '/Items',
      queryParameters: query,
      options: Options(headers: _authHeaders),
    );

    final data = response.data!;
    final items = (data['Items'] as List<dynamic>?) ?? [];
    return items
        .cast<Map<String, dynamic>>()
        .map(JellyfinItem.fromJson)
        .toList();
  }
}
