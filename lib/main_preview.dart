import 'package:flutter/material.dart';

import 'data/duel_result.dart';
import 'data/map_builder.dart';
import 'data/sample_sets.dart';
import 'data/study_set.dart';
import 'preview/style_board.dart';
import 'screens/duel_screen.dart';
import 'screens/map_screen.dart';
import 'screens/results_screen.dart';
import 'screens/snap_screen.dart';
import 'screens/topic_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/view_settings.dart';

/// Design preview of the new direction (Snap → Map → Duel), with sample data.
/// Run: flutter run -d chrome -t lib/main_preview.dart
/// Deep links on web: ?screen=board|snap|thinking|map|topic|duel|results&set=bio|fr|drive&dark=1&motion=0&fail=offline|error
/// (duel also takes &pick=0..3 to answer the first question automatically).
void main() => runApp(const PreviewApp());

class PreviewApp extends StatefulWidget {
  const PreviewApp({super.key});

  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  final _q = Uri.base.queryParameters;
  late bool _dark = _q['dark'] == '1';
  late bool _motion = _q['motion'] != '0';

  /// ?fail=offline|error makes the typed/pasted path fail after a moment, to preview the error states.
  Future<StudySet> _builder(String input) async {
    final fail = _q['fail'];
    if (fail == null) return sampleBuilder(input);
    await Future<void>.delayed(const Duration(seconds: 1));
    throw MapBuildError(offline: fail == 'offline');
  }

  Widget _start() {
    final set = setById(_q['set']);
    return switch (_q['screen']) {
      'snap' => SnapScreen(builder: _builder),
      'thinking' => SnapScreen(autoStart: set, builder: _builder),
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
        builder: (context, child) => ViewSettings(
          motionOn: _motion,
          dark: _dark,
          toggleMotion: () => setState(() => _motion = !_motion),
          toggleDark: () => setState(() => _dark = !_dark),
          child: child!,
        ),
        home: _start(),
      );
}
