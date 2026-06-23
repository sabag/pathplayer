import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/root_indexes_provider.dart';
import '../widgets/folder_tile.dart';
import '../widgets/mini_player.dart';
import 'directory_screen.dart';
import 'search_screen.dart';

class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexesAsync = ref.watch(rootIndexesProvider);

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
        ],
      ),
      body: indexesAsync.when(
        data: (result) => ListView.builder(
          itemCount: result.groups.length,
          itemBuilder: (context, groupIndex) {
            final group = result.groups[groupIndex];
            return ExpansionTile(
              initiallyExpanded: true,
              title: Text(group.name),
              children: group.artists.map((artist) {
                return FolderTile(
                  title: artist.name,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DirectoryScreen(
                          id: artist.id,
                          name: artist.name,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
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
