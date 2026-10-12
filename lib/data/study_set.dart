import '../theme/mastery.dart';

class StudyTopic {
  const StudyTopic(this.name, this.emoji, this.mastery);
  final String name, emoji;
  final Mastery mastery;
}

class StudyQuestion {
  const StudyQuestion({
    required this.q,
    required this.options,
    required this.answer,
    required this.why,
    required this.quote,
    required this.source,
    required this.friendPick,
  });
  final String q;
  final List<String> options;
  final int answer;
  final String why;

  /// The sentence from the learner's own material that backs the answer.
  final String quote;
  final String source;

  /// What the sample friend answers, to make the duel feel alive.
  final int friendPick;
}

class StudySet {
  const StudySet({
    required this.id,
    required this.title,
    required this.from,
    required this.topics,
    required this.readiness,
    required this.delta,
    required this.duelTopic,
    required this.questions,
  });
  final String id, title, from;
  final List<StudyTopic> topics;
  final int readiness, delta;

  /// Index of the shaky topic Eve suggests duelling on.
  final int duelTopic;
  final List<StudyQuestion> questions;

  StudyTopic get focus => topics[duelTopic];
}
