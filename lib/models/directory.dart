import 'subsonic_response.dart';

/// A directory returned by `getMusicDirectory`.
class Directory {
  const Directory({
    required this.id,
    required this.name,
    required this.children,
  });

  final String id;
  final String name;
  final List<DirectoryItem> children;

  bool get hasTracks => children.any((c) => !c.isFolder);

  List<DirectoryItem> get folders =>
      children.where((c) => c.isFolder).toList();

  List<DirectoryItem> get tracks =>
      children.where((c) => !c.isFolder).toList();

  factory Directory.fromResponse(Map<String, dynamic> body) {
    final json = unwrapSubsonicResponse(body);
    final dir = json['directory'] as Map<String, dynamic>;
    return Directory(
      id: dir['id'] as String,
      name: dir['name'] as String,
      children: _toList(dir['child'])
          .map((e) => DirectoryItem.fromJson(e))
          .toList(),
    );
  }
}

/// A child node inside a directory. May be either a folder (album) or a
/// playable track.
class DirectoryItem {
  const DirectoryItem({
    required this.id,
    required this.parent,
    required this.isFolder,
    required this.title,
    this.name,
    this.album,
    this.artist,
    this.duration,
    this.coverArt,
    this.songCount,
  });

  final String id;
  final String? parent;
  final bool isFolder;
  final String title;
  final String? name;
  final String? album;
  final String? artist;
  final int? duration;
  final String? coverArt;
  final int? songCount;

  /// Display name for folders that expose a `name` field.
  String get displayTitle => name ?? title;

  factory DirectoryItem.fromJson(Map<String, dynamic> json) {
    return DirectoryItem(
      id: json['id'] as String,
      parent: json['parent'] as String?,
      isFolder: (json['isDir'] as bool?) ?? false,
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      name: json['name'] as String?,
      album: json['album'] as String?,
      artist: json['artist'] as String?,
      duration: json['duration'] as int?,
      coverArt: json['coverArt'] as String?,
      songCount: json['songCount'] as int?,
    );
  }
}

List<Map<String, dynamic>> _toList(dynamic value) {
  if (value == null) return const [];
  if (value is Map<String, dynamic>) return [value];
  return (value as List).cast<Map<String, dynamic>>();
}
