import 'package:pathplayer/services/navidrome_api.dart';

Future<void> main() async {
  final api = NavidromeApiClient(dio: createNavidromeDio());

  print('--- getIndexes ---');
  final indexes = await api.getIndexes();
  print('Groups: ${indexes.groups.length}');
  final firstGroup = indexes.groups.first;
  print('First group: ${firstGroup.name} (${firstGroup.artists.length} entries)');
  final firstArtist = firstGroup.artists.first;
  print('First entry: ${firstArtist.name} (${firstArtist.id})');

  print('\n--- getMusicDirectory (artist) ---');
  final artistDir = await api.getDirectory(firstArtist.id);
  print('Directory: ${artistDir.name}');
  print('Children: ${artistDir.children.length}');
  for (final child in artistDir.children.take(3)) {
    print('  ${child.isFolder ? "[FOLDER]" : "[TRACK]"} ${child.displayTitle}');
  }

  if (artistDir.folders.isNotEmpty) {
    final album = artistDir.folders.first;
    print('\n--- getMusicDirectory (album) ---');
    final albumDir = await api.getDirectory(album.id);
    print('Directory: ${albumDir.name}');
    print('Tracks: ${albumDir.tracks.length}');
    for (final track in albumDir.tracks.take(3)) {
      print('  ${track.displayTitle}');
    }

    if (albumDir.tracks.isNotEmpty) {
      final trackId = albumDir.tracks.first.id;
      print('\n--- stream URL ---');
      print(api.streamUrl(trackId));
    }
  }

  print('\n--- search3 ---');
  final search = await api.search3('love');
  print('Songs: ${search.songs.length}');
  for (final song in search.songs.take(5)) {
    print('  ${song.title} - ${song.artist}');
  }
}
