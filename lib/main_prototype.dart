import 'package:flutter/material.dart';

import 'prototype/duel_screen.dart';
import 'prototype/map_screen.dart';
import 'prototype/proto_data.dart';
import 'prototype/proto_kit.dart';
import 'prototype/results_screen.dart';
import 'prototype/snap_screen.dart';
import 'prototype/style_board.dart';
import 'prototype/topic_screen.dart';
import 'theme/app_theme.dart';

/// Design preview of the new direction (Snap → Map → Duel), with sample data.
/// Run: flutter run -d chrome -t lib/main_prototype.dart
/// Deep links on web: ?screen=board|snap|thinking|map|topic|duel|results&set=bio|fr|drive&dark=1&motion=0
/// (duel also takes &pick=0..3 to answer the first question automatically).
void main() => runApp(const ProtoApp());

class ProtoApp extends StatefulWidget {
  const ProtoApp({super.key});

  @override
  State<ProtoApp> createState() => _ProtoAppState();
}

class _ProtoAppState extends State<ProtoApp> {
  final _q = Uri.base.queryParameters;
  late bool _dark = _q['dark'] == '1';
  late bool _motion = _q['motion'] != '0';

  Widget _start() {
    final set = setById(_q['set']);
    return switch (_q['screen']) {
      'snap' => const SnapScreen(),
      'thinking' => SnapScreen(autoStart: set),
      'map' => MapScreen(set: set),
      'topic' => TopicScreen(set: set),
      'duel' => DuelScreen(set: set, autoPick: int.tryParse(_q['pick'] ?? '')),
      'results' => ResultsScreen(set: set, result: DuelResult.sample(set)),
      _ => const StyleBoard(),
    };
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Exam Duel · preview',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(dark: false, accent: AccentChoice.aqua),
        darkTheme: buildTheme(dark: true, accent: AccentChoice.aqua),
        themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => ProtoScope(
          motionOn: _motion,
          dark: _dark,
          toggleMotion: () => setState(() => _motion = !_motion),
          toggleDark: () => setState(() => _dark = !_dark),
          child: child!,
        ),
        home: _start(),
      );
}
