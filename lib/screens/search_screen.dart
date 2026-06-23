import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/jellyfin_item.dart';
import '../providers/player_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/folder_tile.dart';
import '../widgets/mini_player.dart';
import '../widgets/track_tile.dart';
import 'directory_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = _query.isEmpty
        ? const AsyncValue<List<JellyfinItem>>.data([])
        : ref.watch(searchProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search tracks...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
          onSubmitted: (value) {
            _debounce?.cancel();
            setState(() => _query = value.trim());
          },
        ),
      ),
      body: resultsAsync.when(
        data: (items) {
          if (_query.isEmpty) {
            return const Center(child: Text('Type to search'));
          }
          if (items.isEmpty) {
            return const Center(child: Text('No results found'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item.isFolder) {
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
              }
              return TrackTile(
                item: item,
                onTap: () {
                  ref.read(playerNotifierProvider.notifier).playItem(item);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Search failed: $error'),
          ),
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
