import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_provider.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _handleSwipe(DragEndDetails details, PlayerNotifier player) {
    final velocity = details.primaryVelocity;
    if (velocity == null) return;
    if (velocity > 200) {
      player.skipToPrevious();
    } else if (velocity < -200) {
      player.skipToNext();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerNotifierProvider);
    if (!player.hasMedia) return const SizedBox.shrink();

    final media = player.mediaItem!;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Container(
        height: 120 + bottomInset,
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 8,
          bottom: 8 + bottomInset,
        ),
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NowPlayingScreen(),
                  ),
                );
              },
              onHorizontalDragEnd: (details) => _handleSwipe(details, player),
              child: Row(
                children: [
                  const Icon(Icons.music_note),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          media.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (media.artist != null)
                          Text(
                            media.artist!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      player.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: player.togglePlayPause,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: player.skipToNext,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  _formatDuration(player.position),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Expanded(
                  child: Slider(
                    value: player.position.inMilliseconds
                        .clamp(0, player.duration.inMilliseconds)
                        .toDouble(),
                    max: player.duration.inMilliseconds.toDouble().clamp(
                      1,
                      double.maxFinite,
                    ),
                    onChanged: (value) {
                      player.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                Text(
                  _formatDuration(player.duration),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
