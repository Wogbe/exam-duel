import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config.dart';
import 'data/local_bank.dart';
import 'data/player_store.dart';
import 'services/fx.dart';
import 'state/library.dart';
import 'state/progress.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  if (AppConfig.onlineEnabled) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabaseAnonKey);
  }
  final bank = await LocalBank.load();
  final store = await PlayerStore.load();
  await progress.load();
  await library.load();
  Fx.init(sound: store.sound, haptics: store.haptics); // not awaited: audio setup must never delay the app
  store.addListener(() => Fx.update(sound: store.sound, haptics: store.haptics));

  runApp(ProviderScope(
    overrides: [
      localBankProvider.overrideWithValue(bank),
      playerStoreProvider.overrideWith((ref) => store),
    ],
    child: const ExamDuelApp(),
  ));
}
