import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_handler.dart';
import '../models/jellyfin_item.dart';
import 'auth_controller.dart';

final playerNotifierProvider = ChangeNotifierProvider<PlayerNotifier>(
  (ref) => PlayerNotifier(ref.watch(audioHandlerProvider)),
);

/// UI-facing player state backed by the global [AudioPlayerHandler].
class PlayerNotifier extends ChangeNotifier {
  PlayerNotifier(this._handler) {
    _handler.player.currentIndexStream.listen((_) => notifyListeners());
    _handler.player.playingStream.listen((_) => notifyListeners());
    _handler.player.positionStream.listen((_) => notifyListeners());
    _handler.player.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });
    _handler.mediaItem.listen((item) {
      _mediaItem = item;
      notifyListeners();
    });
  }

  final AudioPlayerHandler _handler;

  MediaItem? _mediaItem;
  Duration _duration = Duration.zero;

  MediaItem? get mediaItem => _mediaItem;

  bool get hasMedia => _mediaItem != null;

  bool get isPlaying => _handler.player.playing;

  Duration get position => _handler.player.position;

  Duration get duration => _duration;

  Future<void> playItem(JellyfinItem item) => _handler.playItem(item);

  Future<void> playItems(List<JellyfinItem> items, {bool shuffle = false}) =>
      _handler.playItems(items, shuffle: shuffle);

  Future<void> togglePlayPause() async {
    if (_handler.player.playing) {
      await _handler.pause();
    } else {
      await _handler.play();
    }
  }

  Future<void> seek(Duration position) => _handler.seek(position);

  Future<void> skipToNext() => _handler.skipToNext();

  Future<void> skipToPrevious() => _handler.skipToPrevious();
}
