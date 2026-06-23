import 'package:audio_service/audio_service.dart';

import '../services/jellyfin_api.dart';
import 'audio_handler.dart';

/// Initializes [AudioService] with our [AudioPlayerHandler].
///
/// [api] is required so the handler can build authenticated Jellyfin stream
/// URLs for [just_audio].
Future<AudioPlayerHandler> initAudioService(JellyfinApiClient api) async {
  return AudioService.init(
    builder: () => AudioPlayerHandler(api),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.sabag.pathplayer.channel.audio',
      androidNotificationChannelName: 'PathPlayer playback',
      androidNotificationOngoing: true,
    ),
  );
}
