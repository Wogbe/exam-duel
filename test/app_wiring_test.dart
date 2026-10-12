import 'package:exam_duel/app.dart';
import 'package:exam_duel/data/local_bank.dart';
import 'package:exam_duel/data/player_store.dart';
import 'package:exam_duel/screens/home_screen.dart';
import 'package:exam_duel/screens/snap_screen.dart';
import 'package:exam_duel/state/providers.dart';
import 'package:exam_duel/theme/app_theme.dart';
import 'package:exam_duel/widgets/view_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PlayerStore> _store({bool reduceMotion = false}) async {
  SharedPreferences.setMockInitialValues({'reduceMotion': reduceMotion, 'nickname': 'Ama', 'onboarded': true});
  return PlayerStore.load();
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('the app hands the Reduce motion setting to the study screens', (t) async {
    final store = await _store(reduceMotion: true);
    await t.pumpWidget(ProviderScope(overrides: [playerStoreProvider.overrideWith((ref) => store)], child: const ExamDuelApp()));
    await t.pump();
    expect(t.widget<ViewSettings>(find.byType(ViewSettings)).motionOn, isFalse);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('Home has a Learn anything card that opens the Snap screen', (t) async {
    final store = await _store(reduceMotion: true);
    await t.binding.setSurfaceSize(const Size(800, 1600));
    await t.pumpWidget(ProviderScope(
      overrides: [playerStoreProvider.overrideWith((ref) => store)],
      child: MaterialApp(theme: buildTheme(dark: false, accent: store.accent), home: const HomeScreen(), builder: (c, child) => ViewSettings(motionOn: false, dark: false, toggleMotion: () {}, toggleDark: () {}, child: child!)),
    ));
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.text('Learn anything'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(SnapScreen), findsOneWidget);
  });

  testWidgets('the wide Home layout fits the extra card', (t) async {
    final store = await _store(reduceMotion: true);
    final bank = (await t.runAsync(LocalBank.load))!;
    await t.binding.setSurfaceSize(const Size(1280, 900));
    await t.pumpWidget(ProviderScope(
      overrides: [
        playerStoreProvider.overrideWith((ref) => store),
        localBankProvider.overrideWith((ref) => bank),
      ],
      child: MaterialApp(theme: buildTheme(dark: false, accent: store.accent), home: const HomeScreen(), builder: (c, child) => ViewSettings(motionOn: false, dark: false, toggleMotion: () {}, toggleDark: () {}, child: child!)),
    ));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Learn anything'), findsWidgets);
    expect(t.takeException(), isNull);
  });
}
