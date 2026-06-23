import 'package:flutter_test/flutter_test.dart';
import 'package:pathplayer/models/jellyfin_item.dart';
import 'package:pathplayer/services/jellyfin_auth.dart';

void main() {
  group('JellyfinAuth', () {
    test('authHeader includes device info and optional token', () {
      final header = JellyfinAuth.authHeader(token: 'abc123');
      expect(header, startsWith('MediaBrowser '));
      expect(header, contains('Client="PathPlayer"'));
      expect(header, contains('Token="abc123"'));
    });

    test('authHeader omits token when not provided', () {
      final header = JellyfinAuth.authHeader();
      expect(header, isNot(contains('Token=')));
    });
  });

  group('JellyfinItem', () {
    test('fromJson parses an audio item', () {
      final item = JellyfinItem.fromJson(const {
        'Id': 'track-1',
        'Name': 'Song Title',
        'Type': 'Audio',
        'IsFolder': false,
        'AlbumArtist': 'Artist Name',
        'Album': 'Album Name',
        'RunTimeTicks': 100000000,
      });

      expect(item.id, 'track-1');
      expect(item.name, 'Song Title');
      expect(item.type, 'Audio');
      expect(item.isFolder, false);
      expect(item.isAudio, true);
      expect(item.artist, 'Artist Name');
      expect(item.album, 'Album Name');
      expect(item.duration, const Duration(seconds: 10));
    });

    test('fromJson parses a folder item', () {
      final item = JellyfinItem.fromJson(const {
        'Id': 'folder-1',
        'Name': 'My Music',
        'Type': 'Folder',
        'IsFolder': true,
        'CollectionType': 'music',
      });

      expect(item.id, 'folder-1');
      expect(item.isFolder, true);
      expect(item.isAudio, false);
      expect(item.collectionType, 'music');
      expect(item.duration, isNull);
    });

    test('displayName uses filesystem basename for folders', () {
      final item = JellyfinItem.fromJson(const {
        'Id': 'folder-2',
        'Name': 'I Follow Rivers',
        'Type': 'MusicAlbum',
        'IsFolder': true,
        'Path': '/mnt/media/mp3/various dance',
      });

      expect(item.displayName, 'various dance');
    });

    test('displayName strips audio extension for tracks', () {
      final item = JellyfinItem.fromJson(const {
        'Id': 'track-2',
        'Name': 'Song Title',
        'Type': 'Audio',
        'IsFolder': false,
        'Path': '/music/Artist - Track Name.mp3',
      });

      expect(item.displayName, 'Artist - Track Name');
    });

    test('displayName falls back to Name when path is missing', () {
      final item = JellyfinItem.fromJson(const {
        'Id': 'track-3',
        'Name': 'Fallback Title',
        'Type': 'Audio',
        'IsFolder': false,
      });

      expect(item.displayName, 'Fallback Title');
    });
  });
}
