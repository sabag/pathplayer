import 'subsonic_response.dart';

/// A grouping returned by `getIndexes` (e.g. letter "A", "B", "#").
class IndexGroup {
  const IndexGroup({required this.name, required this.artists});

  final String name;
  final List<ArtistEntry> artists;

  factory IndexGroup.fromJson(Map<String, dynamic> json) {
    return IndexGroup(
      name: json['name'] as String,
      artists: _toList(json['artist'])
          .map((e) => ArtistEntry.fromJson(e))
          .toList(),
    );
  }
}

/// A root-level entry returned by `getIndexes`. In Navidrome these are
/// simulated as top-level artists/folders.
class ArtistEntry {
  const ArtistEntry({
    required this.id,
    required this.name,
    this.coverArt,
  });

  final String id;
  final String name;
  final String? coverArt;

  factory ArtistEntry.fromJson(Map<String, dynamic> json) {
    return ArtistEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      coverArt: json['coverArt'] as String?,
    );
  }
}

class GetIndexesResult {
  const GetIndexesResult({required this.groups});

  final List<IndexGroup> groups;

  factory GetIndexesResult.fromResponse(Map<String, dynamic> body) {
    final json = unwrapSubsonicResponse(body);
    final indexes = json['indexes'] as Map<String, dynamic>;
    return GetIndexesResult(
      groups: _toList(indexes['index'])
          .map((e) => IndexGroup.fromJson(e))
          .toList(),
    );
  }
}

List<Map<String, dynamic>> _toList(dynamic value) {
  if (value == null) return const [];
  if (value is Map<String, dynamic>) return [value];
  return (value as List).cast<Map<String, dynamic>>();
}
