import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/study_set.dart';
import '../theme/mastery.dart';

/// What the learner has earned on top of each map's starting levels. Saved on the device once
/// [load] has run; before that (tests, the preview) it lives in memory only.
class Progress extends ChangeNotifier {
  static const _key = 'learn.progress';

  SharedPreferences? _prefs;
  final _gain = <String, Map<int, int>>{}; // set id -> topic index -> levels gained

  Future<void> load() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    _gain.clear();
    try {
      (jsonDecode(prefs.getString(_key) ?? '{}') as Map<String, dynamic>).forEach((id, topics) {
        _gain[id] = {for (final e in (topics as Map<String, dynamic>).entries) int.parse(e.key): (e.value as int).clamp(0, 3)};
      });
    } catch (_) {
      _gain.clear(); // unreadable data: start fresh
    }
    notifyListeners();
  }

  void _save() => _prefs?.setString(
        _key,
        jsonEncode({
          for (final e in _gain.entries) e.key: {for (final g in e.value.entries) '${g.key}': g.value},
        }),
      );

  Mastery mastery(StudySet s, int i) => Mastery.values[(s.topics[i].mastery.index + (_gain[s.id]?[i] ?? 0)).clamp(0, 3)];

  /// Moves a topic up one level (no-op at Ready) and tells the map.
  void levelUp(StudySet s, int i) {
    if (mastery(s, i) == Mastery.ready) return;
    final g = _gain.putIfAbsent(s.id, () => {});
    g[i] = (g[i] ?? 0) + 1;
    _save();
    notifyListeners();
  }

  bool get hasGains => _gain.isNotEmpty;

  int _bonus(StudySet s) => ((_gain[s.id]?.values.fold(0, (a, b) => a + b) ?? 0) * 100 / (3 * s.topics.length)).round();

  int readiness(StudySet s) => (s.readiness + _bonus(s)).clamp(0, 100);

  int delta(StudySet s) => s.delta + _bonus(s);

  /// The topic Eve suggests next: the sample's pick while it's shaky, else any shaky one, else null.
  int? suggest(StudySet s) {
    if (mastery(s, s.duelTopic) == Mastery.shaky) return s.duelTopic;
    final i = List.generate(s.topics.length, (i) => i).indexWhere((i) => mastery(s, i) == Mastery.shaky);
    return i < 0 ? null : i;
  }
}

final progress = Progress();
