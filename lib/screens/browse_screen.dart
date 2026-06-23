import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_controller.dart';
import '../providers/player_provider.dart';
import '../providers/root_indexes_provider.dart';
import '../widgets/folder_tile.dart';
import '../widgets/mini_player.dart';
import '../widgets/track_tile.dart';
import 'directory_screen.dart';
import 'search_screen.dart';

class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(rootItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PathPlayer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SearchScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authControllerProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item.isAudio) {
              return TrackTile(
                item: item,
                onTap: () {
                  ref.read(playerNotifierProvider.notifier).playItem(item);
                },
              );
            }
            return FolderTile(
              title: item.displayName,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DirectoryScreen(
                      id: item.id,
                      name: item.displayName,
                    ),
                  ),
                );
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load library: $error'),
          ),
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
