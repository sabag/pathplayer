import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/jellyfin_item.dart';
import '../providers/auth_controller.dart';
import '../providers/directory_provider.dart';
import '../providers/player_provider.dart';
import '../utils/error_message.dart';
import '../widgets/folder_tile.dart';
import '../widgets/mini_player.dart';
import '../widgets/track_tile.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({
    super.key,
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  bool _shuffling = false;

  Future<void> _shuffleAll() async {
    setState(() => _shuffling = true);

    try {
      final api = ref.read(apiClientProvider);
      final audio = await api.getRecursiveAudio(widget.id);

      if (!mounted) return;

      if (audio.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No audio files found in this folder.')),
        );
        return;
      }

      await ref.read(playerNotifierProvider.notifier).playItems(
            audio,
            shuffle: true,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load tracks: ${apiErrorMessage(e)}')),
      );
    } finally {
      if (mounted) {
        setState(() => _shuffling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final directoryAsync = ref.watch(directoryProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: directoryAsync.when(
        data: (items) => _DirectoryList(
          items: items,
          isShuffling: _shuffling,
          onPlayItem: (item, audioItems) {
            final startIndex = audioItems.indexOf(item);
            ref.read(playerNotifierProvider.notifier).playItemsFrom(
                  audioItems,
                  startIndex,
                );
          },
          onShuffleAll: _shuffleAll,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load directory: ${apiErrorMessage(error)}'),
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
    required this.isShuffling,
    required this.onPlayItem,
    required this.onShuffleAll,
  });

  final List<JellyfinItem> items;
  final bool isShuffling;
  final void Function(JellyfinItem item, List<JellyfinItem> audioItems) onPlayItem;
  final VoidCallback onShuffleAll;

  @override
  Widget build(BuildContext context) {
    final audioItems = items.where((item) => item.isAudio).toList();
    final folderItems = items.where((item) => item.isFolder).toList();
    final canShuffle = items.isNotEmpty;

    return ListView.builder(
      itemCount: folderItems.length +
          audioItems.length +
          (canShuffle ? 1 : 0),
      itemBuilder: (context, index) {
        if (canShuffle && index == 0) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              icon: isShuffling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shuffle),
              label: Text(isShuffling ? 'Loading tracks…' : 'Shuffle All'),
              onPressed: isShuffling ? null : onShuffleAll,
            ),
          );
        }

        final offset = canShuffle ? 1 : 0;
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
          onTap: () => onPlayItem(track, audioItems),
        );
      },
    );
  }
}
