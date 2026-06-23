import 'package:dio/dio.dart';

import '../config.dart';
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

  /// Returns the contents of the root music folder.
  Future<List<JellyfinItem>> getTopLevelItems() async {
    final folders = await _getItems();
    final musicFolder = folders.firstWhere(
      (item) => item.isFolder && item.collectionType == 'music',
      orElse: () => folders.firstWhere(
        (item) => item.isFolder,
        orElse: () => throw Exception('No top-level folder found'),
      ),
    );
    return getChildren(musicFolder.id);
  }

  /// Returns the immediate children of [parentId].
  Future<List<JellyfinItem>> getChildren(String parentId) async {
    return _getItems(parentId: parentId);
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
    return '${JellyfinConfig.baseUrl}/Audio/$itemId/stream'
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
