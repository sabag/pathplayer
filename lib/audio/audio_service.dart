import 'package:audio_service/audio_service.dart';

import 'audio_handler.dart';

/// Initializes the background audio service and returns its handler.
///
/// Call once before [runApp]. Subsequent calls return the same handler.
Future<AudioPlayerHandler> initAudioService() async {
  return AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.sabag.pathplayer.channel.audio',
      androidNotificationChannelName: 'PathPlayer playback',
      androidNotificationOngoing: true,
    ),
  );
}
