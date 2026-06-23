import 'directory.dart';
import 'subsonic_response.dart';

/// A playable track. Used for queue items and search results.
class Track {
  const Track({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.duration,
    this.coverArt,
  });

  final String id;
  final String title;
  final String? artist;
  final String? album;
  final int? duration;
  final String? coverArt;

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      duration: json['duration'] as int?,
      coverArt: json['coverArt'] as String?,
    );
  }

  factory Track.fromDirectoryItem(DirectoryItem item) {
    return Track(
      id: item.id,
      title: item.title,
      artist: item.artist,
      album: item.album,
      duration: item.duration,
      coverArt: item.coverArt,
    );
  }
}

class Search3Result {
  const Search3Result({required this.songs});

  final List<Track> songs;

  factory Search3Result.fromResponse(Map<String, dynamic> body) {
    final json = unwrapSubsonicResponse(body);
    final searchResult = json['searchResult3'] as Map<String, dynamic>?;
    if (searchResult == null) {
      return const Search3Result(songs: []);
    }
    return Search3Result(
      songs: _toList(searchResult['song'])
          .map((e) => Track.fromJson(e))
          .toList(),
    );
  }
}

List<Map<String, dynamic>> _toList(dynamic value) {
  if (value == null) return const [];
  if (value is Map<String, dynamic>) return [value];
  return (value as List).cast<Map<String, dynamic>>();
}
