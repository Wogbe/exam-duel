import 'package:exam_duel/app.dart';
import 'package:exam_duel/data/local_bank.dart';
import 'package:exam_duel/data/player_store.dart';
import 'package:exam_duel/data/sample_sets.dart';
import 'package:exam_duel/screens/home_screen.dart';
import 'package:exam_duel/screens/map_screen.dart';
import 'package:exam_duel/state/library.dart';
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

  testWidgets('Home leads with Learn anything, which opens the Snap screen', (t) async {
    final store = await _store(reduceMotion: true);
    await t.binding.setSurfaceSize(const Size(800, 1600));
    await t.pumpWidget(ProviderScope(
      overrides: [playerStoreProvider.overrideWith((ref) => store)],
      child: MaterialApp(theme: buildTheme(dark: false, accent: store.accent), home: const HomeScreen(), builder: (c, child) => ViewSettings(motionOn: false, dark: false, toggleMotion: () {}, toggleDark: () {}, child: child!)),
    ));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('What are you\nlearning today?'), findsOneWidget);
    await t.tap(find.text('Learn\nanything'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(SnapScreen), findsOneWidget);
  });

  testWidgets('the wide Home layout builds with the new order', (t) async {
    final store = await _store(reduceMotion: true);
    final bank = (await t.runAsync(LocalBank.load))!;
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);
    // 1100 logical pixels wide (wide layout, no text links in the top bar). Pixel ratio 1, or the
    // test surface would be a third of that. The test font is wider than the real ones, so a wider
    // window would overflow the link row here even though it fits on a device.
    t.view.devicePixelRatio = 1.0;
    await t.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [
        playerStoreProvider.overrideWith((ref) => store),
        localBankProvider.overrideWith((ref) => bank),
      ],
      child: MaterialApp(theme: buildTheme(dark: false, accent: store.accent), home: const HomeScreen(), builder: (c, child) => ViewSettings(motionOn: false, dark: false, toggleMotion: () {}, toggleDark: () {}, child: child!)),
    ));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('What are you learning today?'), findsOneWidget);
    expect(find.text('Play with\nfriends'), findsOneWidget);
    expect(find.text('Quick Fire'), findsWidgets);
    // The test font is far wider than the real ones, so overflow warnings are expected here and prove
    // nothing. Anything else thrown (a crash, a null error) is a real failure.
    expect(errors, isNotEmpty);
    expect(errors.every((e) => e.exceptionAsString().contains('overflowed')), isTrue, reason: errors.map((e) => e.exceptionAsString()).join('\n'));
  });

  testWidgets('Home lists saved maps and opens one', (t) async {
    final store = await _store(reduceMotion: true);
    await t.binding.setSurfaceSize(const Size(800, 1600));
    await t.pumpWidget(ProviderScope(
      overrides: [playerStoreProvider.overrideWith((ref) => store)],
      child: MaterialApp(theme: buildTheme(dark: false, accent: store.accent), home: const HomeScreen(), builder: (c, child) => ViewSettings(motionOn: false, dark: false, toggleMotion: () {}, toggleDark: () {}, child: child!)),
    ));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('YOUR MAPS'), findsNothing);
    library.add(studySets.first);
    await t.pump();
    expect(find.text('YOUR MAPS'), findsOneWidget);
    await t.tap(find.text(studySets.first.title));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(MapScreen), findsOneWidget);
  });

  testWidgets('finishing Snap saves the new map to the library', (t) async {
    await t.binding.setSurfaceSize(const Size(800, 1600));
    final pick = studySets[1];
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(dark: false, accent: AccentChoice.aqua),
      builder: (c, child) => ViewSettings(motionOn: false, dark: false, toggleMotion: () {}, toggleDark: () {}, child: child!),
      home: const SnapScreen(),
    ));
    await t.pump(const Duration(seconds: 1));
    await t.ensureVisible(find.text(pick.title));
    await t.tap(find.text(pick.title));
    await t.pump();
    await t.pump(const Duration(seconds: 3));
    expect(library.maps.first.id, pick.id);
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(MapScreen), findsOneWidget);
  });

  testWidgets('a saved map can be removed and put back with Undo', (t) async {
    final store = await _store(reduceMotion: true);
    await t.binding.setSurfaceSize(const Size(800, 1600));
    library.add(studySets.first);
    await t.pumpWidget(ProviderScope(
      overrides: [playerStoreProvider.overrideWith((ref) => store)],
      child: MaterialApp(theme: buildTheme(dark: false, accent: store.accent), home: const HomeScreen(), builder: (c, child) => ViewSettings(motionOn: false, dark: false, toggleMotion: () {}, toggleDark: () {}, child: child!)),
    ));
    await t.pump(const Duration(seconds: 1));
    final title = studySets.first.title;
    expect(find.text(title), findsOneWidget);
    await t.tap(find.byTooltip('More for $title'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Remove map'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(library.maps.any((m) => m.id == studySets.first.id), isFalse);
    expect(find.text('$title removed'), findsOneWidget);
    await t.tap(find.text('Undo'));
    await t.pump();
    expect(library.maps.any((m) => m.id == studySets.first.id), isTrue);
  });
}
