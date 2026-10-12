import 'package:exam_duel/data/map_builder.dart';
import 'package:exam_duel/screens/snap_screen.dart';
import 'package:exam_duel/theme/app_theme.dart';
import 'package:exam_duel/widgets/view_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _pump(WidgetTester t, MapBuilder b) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await t.binding.setSurfaceSize(const Size(480, 1000));
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(dark: false, accent: AccentChoice.aqua),
    builder: (c, child) => ViewSettings(motionOn: false, dark: false, toggleMotion: () {}, toggleDark: () {}, child: child!),
    home: SnapScreen(builder: b),
  ));
  await t.pump(const Duration(seconds: 1));
  await t.enterText(find.byType(TextField), 'Cell biology');
  await t.testTextInput.receiveAction(TextInputAction.go);
}

void main() {
  testWidgets('offline failure shows the offline card and keeps the text', (t) async {
    await _pump(t, (_) async => throw const MapBuildError(offline: true));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.text('You\'re offline'), findsOneWidget);
    expect(find.text('Cell biology'), findsOneWidget);
  });

  testWidgets('generic failure shows the stuck card and Try again retries', (t) async {
    var calls = 0;
    await _pump(t, (_) async {
      calls++;
      throw Exception('boom');
    });
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Eve got stuck'), findsOneWidget);
    await t.tap(find.text('Try again'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(calls, 2);
  });
}
