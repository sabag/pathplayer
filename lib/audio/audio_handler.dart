import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/jellyfin_item.dart';
import '../services/jellyfin_api.dart';

/// Audio-service handler backed by [just_audio]'s [AudioPlayer].
///
/// This is what keeps playback alive while the app is in the background and
/// surfaces media controls in the system notification / lock screen.
///
/// To avoid the long initialization times (and occasional hangs) that come
/// from handing [just_audio] hundreds of network audio sources at once, we
/// keep the queue in memory and only set a single [AudioSource] at a time.
class AudioPlayerHandler extends BaseAudioHandler {
  AudioPlayerHandler(this._api) {
    // Forward just_audio playback events to audio_service's playbackState.
    _player.playbackEventStream
        .map(_transformEvent)
        .listen((state) => playbackState.add(state));

    // When the current track finishes, advance to the next one manually.
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  final JellyfinApiClient _api;
  final AudioPlayer _player = AudioPlayer();

  List<JellyfinItem> _queue = [];
  int _queueIndex = -1;

  AudioPlayer get player => _player;

  @override
  Future<void> skipToNext() async {
    if (_queueIndex < _queue.length - 1) {
      _queueIndex++;
      await _loadQueueIndex();
    } else {
      await _player.pause();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queueIndex > 0) {
      _queueIndex--;
      await _loadQueueIndex();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  /// Replaces the in-memory queue with [items] and loads the item at
  /// [initialIndex]. The audio-service queue is updated so the system
  /// notification sees the full playlist, but only the current item is given
  /// to [just_audio].
  Future<void> setQueue(List<JellyfinItem> items, {int initialIndex = 0}) async {
    _queue = List<JellyfinItem>.from(items);
    _queueIndex = _queue.isEmpty
        ? -1
        : initialIndex.clamp(0, _queue.length - 1);

    final mediaItems = _queue.map(_itemToMediaItem).toList();
    queue.add(mediaItems);

    if (_queueIndex >= 0) {
      await _loadQueueIndex();
    }
  }

  Future<void> playItem(JellyfinItem item) async {
    await setQueue([item]);
    // Start playback without awaiting: the completion future from the platform
    // can hang, but the audio itself begins as soon as the source is loaded.
    _playWithTimeout();
  }

  Future<void> playItems(List<JellyfinItem> items, {bool shuffle = false}) async {
    if (items.isEmpty) return;
    final queue = shuffle ? (List<JellyfinItem>.from(items)..shuffle()) : items;
    await setQueue(queue);
    // Start playback without awaiting so the UI spinner disappears as soon as
    // the queue is loaded and audio begins.
    _playWithTimeout();
  }

  /// Plays [items] starting from the track at [startIndex].
  /// Used when a user taps a single track in a directory and wants playback
  /// to continue through the rest of that directory.
  Future<void> playItemsFrom(List<JellyfinItem> items, int startIndex) async {
    if (items.isEmpty) return;
    await setQueue(items, initialIndex: startIndex);
    _playWithTimeout();
  }

  /// Calls [AudioPlayer.play] with a timeout so a platform/ExoPlayer hang
  /// cannot block the UI indefinitely. Playback usually starts even when the
  /// completion future is slow to return.
  Future<void> _playWithTimeout() async {
    try {
      await _player.play().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      // The play command was accepted but the completion future never arrived.
      // Continue so the UI is not frozen; audio is already playing or will.
    }
  }

  Future<void> _loadQueueIndex() async {
    if (_queueIndex < 0 || _queueIndex >= _queue.length) return;

    final item = _queue[_queueIndex];
    mediaItem.add(_itemToMediaItem(item));

    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(_api.streamUrl(item.id))),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

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
      queueIndex: _queueIndex >= 0 ? _queueIndex : null,
    );
  }
}
