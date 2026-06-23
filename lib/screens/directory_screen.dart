import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/jellyfin_item.dart';
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
        data: (items) => _DirectoryList(
          items: items,
          onPlayItem: (item) {
            ref.read(playerNotifierProvider.notifier).playItem(item);
          },
          onShuffle: (items) {
            ref.read(playerNotifierProvider.notifier).playItems(
                  items,
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
    required this.items,
    required this.onPlayItem,
    required this.onShuffle,
  });

  final List<JellyfinItem> items;
  final ValueChanged<JellyfinItem> onPlayItem;
  final ValueChanged<List<JellyfinItem>> onShuffle;

  @override
  Widget build(BuildContext context) {
    final audioItems = items.where((item) => item.isAudio).toList();
    final folderItems = items.where((item) => item.isFolder).toList();

    return ListView.builder(
      itemCount: folderItems.length +
          audioItems.length +
          (audioItems.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (audioItems.isNotEmpty && index == 0) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.shuffle),
              label: const Text('Shuffle Play Folder'),
              onPressed: () => onShuffle(audioItems),
            ),
          );
        }

        final offset = audioItems.isNotEmpty ? 1 : 0;
        final folderIndex = index - offset;

        if (folderIndex < folderItems.length) {
          final folder = folderItems[folderIndex];
          return FolderTile(
            title: folder.displayName,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DirectoryScreen(
                    id: folder.id,
                    name: folder.displayName,
                  ),
                ),
              );
            },
          );
        }

        final track = audioItems[folderIndex - folderItems.length];
        return TrackTile(
          item: track,
          onTap: () => onPlayItem(track),
        );
      },
    );
  }
}
