import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio/audio_service.dart';
import 'providers/player_provider.dart';
import 'screens/browse_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final handler = await initAudioService();

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(handler),
      ],
      child: const PathPlayerApp(),
    ),
  );
}

class PathPlayerApp extends StatelessWidget {
  const PathPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PathPlayer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const BrowseScreen(),
    );
  }
}
