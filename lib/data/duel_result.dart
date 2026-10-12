import 'study_set.dart';

/// How a duel or solo round went: points, speed and which answers were right.
class DuelResult {
  const DuelResult({required this.correct, required this.mine, required this.friend, required this.seconds, this.solo = false});
  final List<bool> correct;
  final List<int> mine, friend;
  final List<double> seconds;
  final bool solo;

  int get myTotal => mine.fold(0, (a, b) => a + b);
  int get friendTotal => friend.fold(0, (a, b) => a + b);
  int get rightCount => correct.where((r) => r).length;
  bool get won => !solo && myTotal > friendTotal;
  bool get lost => !solo && myTotal < friendTotal;

  /// A good-looking result for the ?screen=results link.
  factory DuelResult.sample(StudySet set) => DuelResult(
        correct: const [true, true, false],
        mine: const [880, 760, 0],
        friend: [for (var i = 0; i < set.questions.length; i++) set.questions[i].friendPick == set.questions[i].answer ? 620 + 90 * i : 0],
        seconds: const [4.8, 7.1, 20],
      );
}
