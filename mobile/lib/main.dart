import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/theme/app_colors.dart';
import 'features/settings/application/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (_) {
    // .env ausente: segue com defaults definidos em AppEnv.
  }
  runApp(const ProviderScope(child: OrcaFacilApp()));
}

/// Raiz do aplicativo OrçaFácil — usa GoRouter alimentado pelo `AuthState`.
class OrcaFacilApp extends ConsumerWidget {
  const OrcaFacilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsControllerProvider);
    return MaterialApp.router(
      title: 'OrçaFácil',
      theme: ThemeData(
        colorScheme: appLightScheme(),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: appDarkScheme(),
        useMaterial3: true,
      ),
      themeMode: settings.themeMode.materialMode,
      routerConfig: router,
    );
  }
}
