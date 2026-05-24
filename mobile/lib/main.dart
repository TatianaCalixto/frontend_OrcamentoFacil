import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';

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
    return MaterialApp.router(
      title: 'OrçaFácil',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
