import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: OrcaFacilApp()));
}

/// Raiz do aplicativo OrçaFácil.
///
/// Em S11-T01 a app exibe apenas uma tela placeholder. As telas reais
/// (Splash, Login, Cadastro) são introduzidas em S11-T03.
class OrcaFacilApp extends StatelessWidget {
  const OrcaFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrçaFácil',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OrçaFácil')),
      body: const Center(
        child: Text('OrçaFácil — estrutura inicial'),
      ),
    );
  }
}
