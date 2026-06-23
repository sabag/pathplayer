import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_provider.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerNotifierProvider);
    final media = player.mediaItem;

    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: media == null
          ? const Center(child: Text('Nothing playing'))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  const Icon(Icons.album, size: 160),
                  const SizedBox(height: 32),
                  Text(
                    media.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (media.artist != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        media.artist!,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (media.album != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        media.album!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 32),
                  Slider(
                    value: player.position.inMilliseconds.clamp(
                      0,
                      player.duration.inMilliseconds,
                    ).toDouble(),
                    max: player.duration.inMilliseconds.toDouble().clamp(
                      1,
                      double.maxFinite,
                    ),
                    onChanged: (value) {
                      ref.read(playerNotifierProvider.notifier).seek(
                            Duration(milliseconds: value.toInt()),
                          );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(player.position)),
                        Text(_formatDuration(player.duration)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.skip_previous),
                        onPressed: player.skipToPrevious,
                      ),
                      IconButton(
                        iconSize: 64,
                        icon: Icon(
                          player.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        ),
                        onPressed: player.togglePlayPause,
                      ),
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.skip_next),
                        onPressed: player.skipToNext,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
