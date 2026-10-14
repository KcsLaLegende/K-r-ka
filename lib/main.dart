import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'store.dart';
import 'theme.dart';
import 'screens/auth.dart';
import 'screens/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();
  runApp(ChangeNotifierProvider.value(value: store, child: const KorobaApp()));
}

class KorobaApp extends StatelessWidget {
  const KorobaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kôrôba',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const Root(),
    );
  }
}

/// Aiguille l'utilisateur selon son état : non connecté, métier non choisi, ou accueil.
class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    if (!s.connecte) return const WelcomeScreen();
    if (s.user!.metier == null) return const MetierScreen();
    return const HomeShell();
  }
}
