import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'core/auth_service.dart';
import 'core/remote_config.dart';
import 'core/theme_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnv();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Use LocalAuthService for now - Firebase Auth has configuration issues
  final authService = LocalAuthService();
  await authService.ensureSignedIn();
  final remoteConfigService = RemoteConfigService();

  runApp(
    ProviderScope(
      overrides: [
        remoteConfigProvider.overrideWithValue(remoteConfigService),
        authServiceProvider.overrideWith((ref) {
          ref.onDispose(authService.dispose);
          return authService;
        }),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: ".env");
  } on FileNotFoundError {
    dotenv.testLoad(fileInput: '');
    debugPrint('No .env file found; continuing with defaults.');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeController = ref.watch(themeControllerProvider.notifier);
    final themePrefs = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'My Way',
      theme: themeController.lightTheme,
      darkTheme: themeController.darkTheme,
      themeMode: switch (themePrefs.themeMode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      },
      routerConfig: router,
    );
  }
}
