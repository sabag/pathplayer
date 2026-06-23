import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/directory.dart';
import '../models/track.dart';
import '../providers/directory_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/folder_tile.dart';
import '../widgets/mini_player.dart';
import '../widgets/track_tile.dart';

class DirectoryScreen extends ConsumerWidget {
  const DirectoryScreen({
    super.key,
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directoryAsync = ref.watch(directoryProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: directoryAsync.when(
        data: (directory) => _DirectoryList(
          directory: directory,
          onPlayTrack: (track) {
            ref.read(playerNotifierProvider.notifier).playTrack(track);
          },
          onShuffle: (tracks) {
            ref.read(playerNotifierProvider.notifier).playTracks(
                  tracks,
                  shuffle: true,
                );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load directory: $error'),
          ),
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}

class _DirectoryList extends StatelessWidget {
  const _DirectoryList({
    required this.directory,
    required this.onPlayTrack,
    required this.onShuffle,
  });

  final Directory directory;
  final ValueChanged<Track> onPlayTrack;
  final ValueChanged<List<Track>> onShuffle;

  @override
  Widget build(BuildContext context) {
    final tracks = directory.tracks.map(Track.fromDirectoryItem).toList();

    return ListView.builder(
      itemCount: directory.children.length + (tracks.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (tracks.isNotEmpty && index == 0) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.shuffle),
              label: const Text('Shuffle Play Folder'),
              onPressed: () => onShuffle(tracks),
            ),
          );
        }

        final childIndex = tracks.isNotEmpty ? index - 1 : index;
        final item = directory.children[childIndex];

        if (item.isFolder) {
          return FolderTile(
            title: item.displayTitle,
            subtitle: item.artist,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DirectoryScreen(
                    id: item.id,
                    name: item.displayTitle,
                  ),
                ),
              );
            },
          );
        }

        final track = Track.fromDirectoryItem(item);
        return TrackTile(
          track: track,
          onTap: () => onPlayTrack(track),
        );
      },
    );
  }
}
