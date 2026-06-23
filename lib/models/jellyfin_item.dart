import 'package:meta/meta.dart';

/// A generic Jellyfin library item used for folder-style browsing.
@immutable
class JellyfinItem {
  const JellyfinItem({
    required this.id,
    required this.name,
    required this.type,
    this.isFolder = false,
    this.collectionType,
    this.artist,
    this.album,
    this.duration,
    this.path,
  });

  final String id;
  final String name;
  final String type;
  final bool isFolder;
  final String? collectionType;
  final String? artist;
  final String? album;
  final Duration? duration;
  final String? path;

  factory JellyfinItem.fromJson(Map<String, dynamic> json) {
    final runTimeTicks = json['RunTimeTicks'] as int?;
    final artists = json['Artists'] as List<dynamic>?;

    return JellyfinItem(
      id: json['Id'] as String,
      name: (json['Name'] as String?) ?? '',
      type: json['Type'] as String,
      isFolder: json['IsFolder'] as bool? ?? false,
      collectionType: json['CollectionType'] as String?,
      artist: (json['AlbumArtist'] as String?) ??
          (artists != null && artists.isNotEmpty
              ? artists.first as String
              : null),
      album: json['Album'] as String?,
      duration: runTimeTicks != null
          ? Duration(milliseconds: (runTimeTicks / 10000).round())
          : null,
      path: json['Path'] as String?,
    );
  }

  /// Whether this item can be played as audio.
  bool get isAudio => type == 'Audio';

  /// Returns the filesystem name for folders/tracks when a path is available,
  /// falling back to the Jellyfin metadata name.
  String get displayName {
    final p = path;
    if (p != null && p.isNotEmpty) {
      // Use the filesystem basename, stripping a trailing separator and
      // a known audio extension for tracks.
      final basename = p.replaceAll(RegExp(r'[\\/]+$'), '').split(RegExp(r'[\\/]')).last;
      if (isAudio) {
        return basename.replaceAll(RegExp(r'\.(mp3|aac|flac|m4a|ogg|wma|wav)$', caseSensitive: false), '');
      }
      return basename;
    }
    return name;
  }

  @override
  String toString() => 'JellyfinItem(id: $id, name: $name, type: $type)';
}
