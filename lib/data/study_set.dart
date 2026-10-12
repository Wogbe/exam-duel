import '../theme/mastery.dart';

class StudyTopic {
  const StudyTopic(this.name, this.emoji, this.mastery);
  final String name, emoji;
  final Mastery mastery;

  Map<String, dynamic> toJson() => {'name': name, 'emoji': emoji, 'mastery': mastery.index};

  factory StudyTopic.fromJson(Map<String, dynamic> j) =>
      StudyTopic(j['name'] as String, j['emoji'] as String, Mastery.values[(j['mastery'] as int).clamp(0, 3)]);
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

  Map<String, dynamic> toJson() =>
      {'q': q, 'options': options, 'answer': answer, 'why': why, 'quote': quote, 'source': source, 'friendPick': friendPick};

  factory StudyQuestion.fromJson(Map<String, dynamic> j) {
    final options = (j['options'] as List).cast<String>();
    final answer = j['answer'] as int;
    if (options.length != 4 || answer < 0 || answer > 3) throw const FormatException('bad question');
    return StudyQuestion(
      q: j['q'] as String,
      options: options,
      answer: answer,
      why: j['why'] as String,
      quote: j['quote'] as String,
      source: j['source'] as String,
      friendPick: (j['friendPick'] as int).clamp(0, 3),
    );
  }
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'from': from,
        'readiness': readiness,
        'delta': delta,
        'duelTopic': duelTopic,
        'topics': [for (final t in topics) t.toJson()],
        'questions': [for (final q in questions) q.toJson()],
      };

  /// Throws if the data is not a usable set, so a corrupt saved map can be skipped.
  factory StudySet.fromJson(Map<String, dynamic> j) {
    final topics = [for (final t in j['topics'] as List) StudyTopic.fromJson(t as Map<String, dynamic>)];
    final questions = [for (final q in j['questions'] as List) StudyQuestion.fromJson(q as Map<String, dynamic>)];
    final duelTopic = j['duelTopic'] as int;
    if (topics.isEmpty || questions.isEmpty || duelTopic < 0 || duelTopic >= topics.length) throw const FormatException('bad set');
    return StudySet(
      id: j['id'] as String,
      title: j['title'] as String,
      from: j['from'] as String,
      topics: topics,
      readiness: (j['readiness'] as int).clamp(0, 100),
      delta: j['delta'] as int,
      duelTopic: duelTopic,
      questions: questions,
    );
  }
}
