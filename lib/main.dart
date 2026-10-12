import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config.dart';
import 'data/local_bank.dart';
import 'data/player_store.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  if (AppConfig.onlineEnabled) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabaseAnonKey);
  }
  final bank = await LocalBank.load();
  final store = await PlayerStore.load();

  runApp(ProviderScope(
    overrides: [
      localBankProvider.overrideWithValue(bank),
      playerStoreProvider.overrideWith((ref) => store),
    ],
    child: const ExamDuelApp(),
  ));
}
