import 'package:exam_duel/prototype/map_screen.dart';
import 'package:exam_duel/prototype/proto_data.dart';
import 'package:exam_duel/prototype/proto_kit.dart';
import 'package:exam_duel/prototype/results_screen.dart';
import 'package:exam_duel/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  final set = studySets.first;

  test('levelUp raises mastery and readiness, and stops at Ready', () {
    final p = Progress();
    final i = set.duelTopic;
    expect(p.mastery(set, i), Mastery.shaky);
    final before = p.readiness(set);
    p.levelUp(set, i);
    expect(p.mastery(set, i), Mastery.solid);
    expect(p.readiness(set), greaterThan(before));
    p.levelUp(set, i);
    p.levelUp(set, i);
    expect(p.mastery(set, i), Mastery.ready);
  });

  test('suggest moves on once the suggested topic is no longer shaky', () {
    final p = Progress();
    expect(p.suggest(set), set.duelTopic);
    p.levelUp(set, set.duelTopic);
    expect(p.suggest(set), isNot(set.duelTopic));
  });

  testWidgets('map tile updates after a level up', (t) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final semantics = t.ensureSemantics();
    await t.binding.setSurfaceSize(const Size(480, 1400));
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(dark: false, accent: AccentChoice.aqua),
      builder: (c, child) => ProtoScope(motionOn: false, dark: false, toggleMotion: () {}, toggleDark: () {}, child: child!),
      home: MapScreen(set: set),
    ));
    await t.pump(const Duration(seconds: 2));
    final name = set.topics[set.duelTopic].name;
    expect(find.bySemanticsLabel(RegExp('$name,\\s*Shaky')), findsOneWidget);
    progress.levelUp(set, set.duelTopic);
    await t.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel(RegExp('$name,\\s*Solid')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('results over the map levels the topic up without build errors', (t) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await t.binding.setSurfaceSize(const Size(480, 1400));
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(dark: false, accent: AccentChoice.aqua),
      builder: (c, child) => ProtoScope(motionOn: false, dark: false, toggleMotion: () {}, toggleDark: () {}, child: child!),
      home: MapScreen(set: set),
    ));
    await t.pump(const Duration(seconds: 2));
    final topic = progress.suggest(set)!;
    final before = progress.mastery(set, topic);
    final nav = t.state<NavigatorState>(find.byType(Navigator));
    nav.push(MaterialPageRoute<void>(builder: (_) => ResultsScreen(set: set, topic: topic, result: DuelResult.sample(set))));
    await t.pump(const Duration(seconds: 3));
    expect(t.takeException(), isNull);
    expect(progress.mastery(set, topic).index, before.index + 1);
  });
}
