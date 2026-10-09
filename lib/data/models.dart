import 'dart:math';

/// A trivia category. `id` matches the `category` column in Supabase.
class Category {
  final String id;
  final String name;
  final int colorIndex; // index into Pastel.all
  const Category(this.id, this.name, this.colorIndex);

  static const all = [
    Category('ghana', 'Ghana & Africa', 3),
    Category('history', 'History', 1),
    Category('science', 'Science', 2),
    Category('geography', 'Geography', 6),
    Category('sports', 'Sports', 0),
    Category('entertainment', 'Music & Movies', 4),
    Category('tech', 'Tech', 7),
    Category('random', 'Random', 5),
  ];

  static const ai = Category('ai', 'Eve’s pick', 1);

  static Category byId(String id) =>
      id == 'ai' ? ai : all.firstWhere((c) => c.id == id, orElse: () => all.last);
}

/// A question ready to show. `answer` is null for live online questions
/// until the server reveals it.
class Question {
  final String stem;
  final List<String> options;
  final String category;
  final int? answer;
  const Question({required this.stem, required this.options, required this.category, this.answer});

  /// Builds a shuffled question from the bundled format:
  /// `{c, q, a, w: [3 wrong]}`.
  factory Question.fromBank(Map<String, dynamic> j, Random rng) {
    final correct = j['a'] as String;
    final opts = <String>[correct, ...(j['w'] as List).cast<String>()]..shuffle(rng);
    return Question(
      stem: j['q'] as String,
      options: opts,
      category: j['c'] as String,
      answer: opts.indexOf(correct),
    );
  }
}

class Fact {
  final String text;
  final String category;
  const Fact(this.text, this.category);
}

enum RoomStatus { lobby, question, reveal, finished }

RoomStatus _status(String s) => RoomStatus.values.firstWhere((e) => e.name == s, orElse: () => RoomStatus.lobby);

class RoomSettings {
  final int count;
  final int seconds;
  final List<String> categories;
  final String? topic;
  final bool hasAiBatch; // Eve's questions are waiting for the next game
  const RoomSettings({this.count = 10, this.seconds = 15, this.categories = const [], this.topic, this.hasAiBatch = false});

  String get summary {
    final cats = categories.isEmpty
        ? 'All categories'
        : categories.length == 1
            ? Category.byId(categories.first).name
            : '${categories.length} categories';
    return '$count questions · ${seconds}s · $cats';
  }

  Map<String, dynamic> toJson() => {
        'count': count,
        'seconds': seconds,
        'categories': categories,
        if (topic != null && topic!.isNotEmpty) 'topic': topic,
      };

  factory RoomSettings.fromJson(Map<String, dynamic>? j) {
    j ??= const {};
    return RoomSettings(
      count: (j['count'] as num?)?.toInt() ?? 10,
      seconds: (j['seconds'] as num?)?.toInt() ?? 15,
      categories: ((j['categories'] as List?) ?? const []).cast<String>(),
      topic: j['topic'] as String?,
      hasAiBatch: j['ai_batch'] != null,
    );
  }
}

class Room {
  final String id;
  final String code;
  final String hostId;
  final RoomStatus status;
  final int currentIndex;
  final int questionCount;
  final DateTime? phaseStartedAt;
  final RoomSettings settings;
  const Room({
    required this.id,
    required this.code,
    required this.hostId,
    required this.status,
    required this.currentIndex,
    required this.questionCount,
    required this.phaseStartedAt,
    required this.settings,
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
        id: j['id'] as String,
        code: j['code'] as String,
        hostId: j['host_id'] as String,
        status: _status(j['status'] as String),
        currentIndex: (j['current_index'] as num?)?.toInt() ?? -1,
        questionCount: (j['question_count'] as num?)?.toInt() ?? 0,
        phaseStartedAt: j['phase_started_at'] == null ? null : DateTime.parse(j['phase_started_at'] as String),
        settings: RoomSettings.fromJson(j['settings'] as Map<String, dynamic>?),
      );
}

class Player {
  final String userId;
  final String nickname;
  final int avatar;
  final int score;
  final int streak;
  final int answeredIndex;
  final bool lastCorrect;
  final int lastPoints;
  final bool isHost;
  const Player({
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.score,
    required this.streak,
    required this.answeredIndex,
    required this.lastCorrect,
    required this.lastPoints,
    required this.isHost,
  });

  factory Player.fromJson(Map<String, dynamic> j) => Player(
        userId: j['user_id'] as String,
        nickname: j['nickname'] as String,
        avatar: (j['avatar'] as num?)?.toInt() ?? 0,
        score: (j['score'] as num?)?.toInt() ?? 0,
        streak: (j['streak'] as num?)?.toInt() ?? 0,
        answeredIndex: (j['answered_index'] as num?)?.toInt() ?? -1,
        lastCorrect: j['last_correct'] as bool? ?? false,
        lastPoints: (j['last_points'] as num?)?.toInt() ?? 0,
        isHost: j['is_host'] as bool? ?? false,
      );

  String get initial => nickname.isEmpty ? '?' : nickname.substring(0, 1).toUpperCase();
}

/// Result of `submit_answer` from the server.
class AnswerResult {
  final bool correct;
  final int points;
  final int streak;
  const AnswerResult(this.correct, this.points, this.streak);
}
