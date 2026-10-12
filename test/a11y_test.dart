import 'package:exam_duel/prototype/duel_screen.dart';
import 'package:exam_duel/prototype/proto_data.dart';
import 'package:exam_duel/prototype/proto_kit.dart';
import 'package:exam_duel/theme/app_theme.dart';
import 'package:exam_duel/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

double _contrast(Color a, Color b) {
  final hi = a.computeLuminance() > b.computeLuminance() ? a : b;
  final lo = identical(hi, a) ? b : a;
  return (hi.computeLuminance() + .05) / (lo.computeLuminance() + .05);
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Pressable can be reached with Tab and activated with Enter and Space', (t) async {
    var taps = 0;
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(dark: false, accent: AccentChoice.aqua),
      home: Scaffold(body: Center(child: Pressable(onTap: () => taps++, semanticLabel: 'Go', child: const SizedBox(width: 80, height: 48)))),
    ));
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 2);
  });

  testWidgets('a disabled Pressable is skipped by Tab', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(dark: false, accent: AccentChoice.aqua),
      home: const Scaffold(body: Center(child: Pressable(semanticLabel: 'Off', child: SizedBox(width: 80, height: 48)))),
    ));
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    expect(find.byType(Focus).evaluate().any((e) => (e.widget as Focus).focusNode?.hasPrimaryFocus ?? false), isFalse);
  });

  for (final dark in [false, true]) {
    testWidgets('TimerRing low-time text has 4.5:1 contrast (dark: $dark)', (t) async {
      final theme = buildTheme(dark: dark, accent: AccentChoice.aqua);
      await t.pumpWidget(MaterialApp(theme: theme, home: const Scaffold(body: Center(child: TimerRing(fraction: 0.1, seconds: 2)))));
      final colour = t.widget<Text>(find.text('2')).style!.color!;
      expect(_contrast(colour, theme.scaffoldBackgroundColor), greaterThanOrEqualTo(4.5));
    });
  }

  testWidgets('leaving a duel asks first once an answer has been given', (t) async {
    await t.binding.setSurfaceSize(const Size(480, 1000));
    final set = studySets.first;
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(dark: false, accent: AccentChoice.aqua),
      builder: (c, child) => ProtoScope(motionOn: false, dark: false, toggleMotion: () {}, toggleDark: () {}, child: child!),
      home: Builder(builder: (context) => TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DuelScreen(set: set, solo: true))), child: const Text('open'))),
    ));
    await t.tap(find.text('open'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    final close = find.byIcon(Icons.close_rounded);

    await t.tap(close); // nothing answered yet: leaves straight away
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(DuelScreen), findsNothing);

    await t.tap(find.text('open'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    final q = set.questions.first;
    await t.tap(find.text(q.options[q.answer]));
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(close);
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Leave this round?'), findsOneWidget);
    await t.tap(find.text('Keep playing'));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byType(DuelScreen), findsOneWidget);
    await t.tap(close);
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('Leave'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(DuelScreen), findsNothing);
  });
}
