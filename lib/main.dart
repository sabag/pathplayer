import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_controller.dart';
import 'screens/browse_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PathPlayerApp()));
}

class PathPlayerApp extends ConsumerWidget {
  const PathPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

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
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
      home: _homeForState(authState),
    );
  }

  Widget _homeForState(AuthState state) {
    if (state is AuthLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is AuthUnauthenticated) {
      return LoginScreen(
        prefillUrl: state.prefillUrl,
        prefillUsername: state.prefillUsername,
        error: state.error,
      );
    }

    return const BrowseScreen();
  }
}
