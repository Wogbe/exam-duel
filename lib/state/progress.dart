import 'package:flutter/foundation.dart';

import '../data/study_set.dart';
import '../theme/mastery.dart';

/// What the learner has earned on top of the sample data. In memory only, so a restart resets it.
class Progress extends ChangeNotifier {
  final _gain = <String, Map<int, int>>{}; // set id -> topic index -> levels gained

  Mastery mastery(StudySet s, int i) => Mastery.values[(s.topics[i].mastery.index + (_gain[s.id]?[i] ?? 0)).clamp(0, 3)];

  /// Moves a topic up one level (no-op at Ready) and tells the map.
  void levelUp(StudySet s, int i) {
    if (mastery(s, i) == Mastery.ready) return;
    final g = _gain.putIfAbsent(s.id, () => {});
    g[i] = (g[i] ?? 0) + 1;
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
