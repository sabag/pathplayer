import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio/audio_handler.dart';
import 'audio/audio_service.dart';
import 'config.dart';
import 'providers/api_client_provider.dart';
import 'providers/player_provider.dart';
import 'screens/browse_screen.dart';
import 'services/jellyfin_api.dart';
import 'services/jellyfin_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AuthGate());
}

/// Handles Jellyfin authentication before the rest of the app is built.
///
/// If authentication or the audio service fails, an error screen with a
/// retry button is shown instead of a blank page.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  Object? _error;

  late Dio _dio;
  late JellyfinApiClient _api;
  late AudioPlayerHandler _handler;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _dio = Dio(
        BaseOptions(
          baseUrl: JellyfinConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final credentials = await JellyfinAuth(_dio).authenticate();
      _api = JellyfinApiClient(dio: _dio, credentials: credentials);
      _handler = await initAudioService(_api);

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e, st) {
      debugPrint('Auth/audio init failed: $e');
      debugPrint(st.toString());
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _retry() async {
    _dio.close();
    await _init();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
    );

    if (_loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Could not connect to Jellyfin',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(_dio),
        apiClientProvider.overrideWithValue(_api),
        audioHandlerProvider.overrideWithValue(_handler),
      ],
      child: const PathPlayerApp(),
    );
  }
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
