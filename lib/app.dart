import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/splash_screen.dart';
import 'state/providers.dart';
import 'theme/app_theme.dart';

class ExamDuelApp extends ConsumerWidget {
  const ExamDuelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(playerStoreProvider);
    return MaterialApp(
      title: 'Exam Duel',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(dark: false, accent: store.accent),
      darkTheme: buildTheme(dark: true, accent: store.accent),
      themeMode: store.dark ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: const Duration(milliseconds: 300),
      home: const SplashScreen(),
    );
  }
}
