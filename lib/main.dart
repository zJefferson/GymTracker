import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/database_provider.dart';
import 'providers/settings_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const GymTrackerApp(),
    ),
  );
}

class GymTrackerApp extends ConsumerWidget {
  const GymTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final seed = ref.watch(seedProvider);

    return MaterialApp.router(
      title: 'GymTracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
      builder: (context, child) {
        return seed.when(
          data: (_) => child ?? const SizedBox.shrink(),
          loading: () => const _SplashScreen(),
          error: (err, stack) => _SplashScreen(error: err.toString()),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  final String? error;
  const _SplashScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erro ao iniciar: $error'),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.fitness_center, size: 48),
                  SizedBox(height: 16),
                  CircularProgressIndicator(),
                ],
              ),
      ),
    );
  }
}
