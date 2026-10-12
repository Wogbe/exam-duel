import 'sample_sets.dart';
import 'study_set.dart';

/// Turns what the learner typed or pasted into a study set. The real build swaps
/// this for the AI call; sample data stands in until then.
typedef MapBuilder = Future<StudySet> Function(String input);

/// Thrown by a [MapBuilder] when the AI call fails. [offline] picks the wording.
class MapBuildError implements Exception {
  const MapBuildError({this.offline = false});
  final bool offline;
}

Future<StudySet> sampleBuilder(String input) async {
  final t = input.toLowerCase();
  return setById(t.contains('fren')
      ? 'fr'
      : (t.contains('driv') || t.contains('road') ? 'drive' : (t.contains('bio') || t.contains('cell') ? 'bio' : null)));
}
