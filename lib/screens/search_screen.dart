import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track.dart';
import '../providers/player_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/mini_player.dart';
import '../widgets/track_tile.dart';

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
        ? const AsyncValue<Search3Result>.data(Search3Result(songs: []))
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
        data: (result) {
          if (_query.isEmpty) {
            return const Center(child: Text('Type to search'));
          }
          if (result.songs.isEmpty) {
            return const Center(child: Text('No tracks found'));
          }
          return ListView.builder(
            itemCount: result.songs.length,
            itemBuilder: (context, index) {
              final track = result.songs[index];
              return TrackTile(
                track: track,
                onTap: () {
                  ref.read(playerNotifierProvider.notifier).playTrack(track);
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
