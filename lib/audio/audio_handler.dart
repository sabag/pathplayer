import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_api.dart';

/// Audio-service handler backed by [just_audio]'s [AudioPlayer].
///
/// This is what keeps playback alive while the app is in the background and
/// surfaces media controls in the system notification / lock screen.
class AudioPlayerHandler extends BaseAudioHandler {
  AudioPlayerHandler(this._api) {
    // Forward just_audio playback events to audio_service's playbackState.
    _player.playbackEventStream
        .map(_transformEvent)
        .listen((state) => playbackState.add(state));

    // Keep the displayed media item in sync with the current queue index.
    _player.currentIndexStream.listen((index) {
      final queue = this.queue.value;
      if (index != null && index >= 0 && index < queue.length) {
        mediaItem.add(queue[index]);
      }
    });
  }

  final JellyfinApiClient _api;
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  /// Replaces the queue with [items] and starts at [initialIndex].
  Future<void> setQueue(List<JellyfinItem> items, {int initialIndex = 0}) async {
    final mediaItems = items.map(_itemToMediaItem).toList();
    queue.add(mediaItems);

    final children = <AudioSource>[
      for (final item in items) AudioSource.uri(Uri.parse(_api.streamUrl(item.id))),
    ];

    await _player.setAudioSources(
      children,
      initialIndex: initialIndex,
    );
    if (initialIndex == 0) {
      mediaItem.add(mediaItems.isNotEmpty ? mediaItems.first : null);
    }
  }

  Future<void> playItem(JellyfinItem item) async {
    await setQueue([item]);
    await _player.play();
  }

  Future<void> playItems(List<JellyfinItem> items, {bool shuffle = false}) async {
    if (items.isEmpty) return;
    final queue = shuffle ? (List<JellyfinItem>.from(items)..shuffle()) : items;
    await setQueue(queue);
    await _player.play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  MediaItem _itemToMediaItem(JellyfinItem item) {
    return MediaItem(
      id: item.id,
      title: item.name,
      artist: item.artist,
      album: item.album,
      duration: item.duration,
    );
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: event.updatePosition,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
