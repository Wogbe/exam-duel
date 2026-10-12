import 'package:flutter/foundation.dart';

import 'proto_kit.dart';

/// Sample content for the design preview. In the real app Eve (AI) builds
/// all of this from what the learner snaps, pastes or types.
class ProtoTopic {
  const ProtoTopic(this.name, this.emoji, this.mastery);
  final String name, emoji;
  final Mastery mastery;
}

class ProtoQuestion {
  const ProtoQuestion({
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
  final List<ProtoTopic> topics;
  final int readiness, delta;

  /// Index of the shaky topic Eve suggests duelling on.
  final int duelTopic;
  final List<ProtoQuestion> questions;

  ProtoTopic get focus => topics[duelTopic];
}

/// The sample streak, shown the same on every screen.
const sampleStreak = 4;

/// The sample friend.
const friendName = 'Leo';

const studySets = <StudySet>[
  StudySet(
    id: 'bio',
    title: 'Cell Biology',
    from: '3 pages of your notes',
    readiness: 62,
    delta: 5,
    duelTopic: 2,
    topics: [
      ProtoTopic('Cell structure', '🔬', Mastery.ready),
      ProtoTopic('Organelles', '🧩', Mastery.solid),
      ProtoTopic('Mitosis', '🧬', Mastery.shaky),
      ProtoTopic('Meiosis', '🔀', Mastery.unseen),
      ProtoTopic('Membranes', '🫧', Mastery.solid),
      ProtoTopic('Enzymes', '⚗️', Mastery.shaky),
      ProtoTopic('Respiration', '🌬️', Mastery.solid),
      ProtoTopic('Photosynthesis', '🌿', Mastery.ready),
      ProtoTopic('DNA', '🧵', Mastery.solid),
      ProtoTopic('Proteins', '🥚', Mastery.unseen),
      ProtoTopic('Cell cycle', '🔄', Mastery.shaky),
      ProtoTopic('Microscopy', '🔭', Mastery.unseen),
    ],
    questions: [
      ProtoQuestion(
        q: 'In which phase of mitosis do chromosomes line up in the middle of the cell?',
        options: ['Prophase', 'Metaphase', 'Anaphase', 'Telophase'],
        answer: 1,
        why: 'Metaphase: "meta" means middle. The spindle pulls every chromosome onto the cell\'s equator.',
        quote: 'During metaphase the chromosomes line up along the middle of the cell, attached to spindle fibres.',
        source: 'Your notes · page 2',
        friendPick: 1,
      ),
      ProtoQuestion(
        q: 'How many daughter cells does one round of mitosis make?',
        options: ['One', 'Two', 'Four', 'Eight'],
        answer: 1,
        why: 'Mitosis makes two identical cells. Four is meiosis, the one that makes sex cells.',
        quote: 'Mitosis produces two genetically identical daughter cells.',
        source: 'Your notes · page 1',
        friendPick: 2,
      ),
      ProtoQuestion(
        q: 'What do sister chromatids do during anaphase?',
        options: ['Join together', 'Copy themselves', 'Pull apart to opposite ends', 'Leave the nucleus'],
        answer: 2,
        why: 'In anaphase the spindle fibres shorten and pull each pair of chromatids to opposite poles.',
        quote: 'In anaphase, sister chromatids separate and move to opposite poles of the cell.',
        source: 'Your notes · page 2',
        friendPick: 2,
      ),
    ],
  ),
  StudySet(
    id: 'fr',
    title: 'French A2',
    from: 'your topic',
    readiness: 48,
    delta: 7,
    duelTopic: 3,
    topics: [
      ProtoTopic('Greetings', '👋', Mastery.ready),
      ProtoTopic('Numbers', '🔢', Mastery.solid),
      ProtoTopic('Food', '🥐', Mastery.solid),
      ProtoTopic('Passé composé', '⏪', Mastery.shaky),
      ProtoTopic('Travel', '🧳', Mastery.shaky),
      ProtoTopic('Family', '👪', Mastery.solid),
      ProtoTopic('Weather', '🌦️', Mastery.unseen),
      ProtoTopic('Directions', '🧭', Mastery.unseen),
      ProtoTopic('Shopping', '🛍️', Mastery.shaky),
      ProtoTopic('Time', '⏰', Mastery.solid),
      ProtoTopic('Hobbies', '🎨', Mastery.unseen),
      ProtoTopic('Body', '🦵', Mastery.unseen),
    ],
    questions: [
      ProtoQuestion(
        q: 'Which is correct for "I went to the market"?',
        options: ["J'ai allé au marché", 'Je suis allé au marché', 'Je vais au marché', "J'allais au marché"],
        answer: 1,
        why: 'Aller is one of the movement verbs that take être in the passé composé: je suis allé(e).',
        quote: 'Verbs of movement such as aller, venir and partir use être: je suis allé(e).',
        source: 'Eve\'s A2 topic guide',
        friendPick: 0,
      ),
      ProtoQuestion(
        q: '"Nous ___ mangé une pizza." Which word fills the gap?',
        options: ['sommes', 'avons', 'êtes', 'ont'],
        answer: 1,
        why: 'Most verbs, including manger, use avoir. With nous it becomes "avons".',
        quote: 'Most verbs form the passé composé with avoir: nous avons mangé.',
        source: 'Eve\'s A2 topic guide',
        friendPick: 1,
      ),
      ProtoQuestion(
        q: 'What is the past participle of "faire"?',
        options: ['fairé', 'fit', 'fait', 'faisé'],
        answer: 2,
        why: 'Faire is irregular: the participle is "fait", as in "j\'ai fait mes devoirs".',
        quote: 'Irregular participles to learn: faire → fait, prendre → pris, voir → vu.',
        source: 'Eve\'s A2 topic guide',
        friendPick: 2,
      ),
    ],
  ),
  StudySet(
    id: 'drive',
    title: 'Driving theory',
    from: 'your topic',
    readiness: 71,
    delta: 3,
    duelTopic: 5,
    topics: [
      ProtoTopic('Road signs', '🛑', Mastery.ready),
      ProtoTopic('Right of way', '↔️', Mastery.solid),
      ProtoTopic('Speed', '🏎️', Mastery.solid),
      ProtoTopic('Roundabouts', '🔁', Mastery.ready),
      ProtoTopic('Parking', '🅿️', Mastery.solid),
      ProtoTopic('Hazards', '⚠️', Mastery.shaky),
      ProtoTopic('Night driving', '🌙', Mastery.shaky),
      ProtoTopic('Bad weather', '🌧️', Mastery.solid),
      ProtoTopic('Pedestrians', '🚶', Mastery.solid),
      ProtoTopic('Safety checks', '🔧', Mastery.unseen),
      ProtoTopic('Motorways', '🛣️', Mastery.unseen),
      ProtoTopic('Emergencies', '🚑', Mastery.unseen),
    ],
    questions: [
      ProtoQuestion(
        q: 'A ball rolls into the road ahead. What should you expect?',
        options: ['Nothing, keep going', 'A child may follow it', 'The road is closed', 'A speed camera'],
        answer: 1,
        why: 'A ball is a classic hazard clue: a child may run out after it. Slow down and be ready to stop.',
        quote: 'Look for clues to hazards, such as a ball in the road, which may be followed by a child.',
        source: 'Eve\'s driving theory guide',
        friendPick: 1,
      ),
      ProtoQuestion(
        q: 'In wet weather, your stopping distance can be about…',
        options: ['The same', 'Half as long', 'Twice as long', 'Ten times as long'],
        answer: 2,
        why: 'Wet roads give tyres less grip, so stopping distances can double. Leave a bigger gap.',
        quote: 'On wet roads, stopping distances can be at least double those on dry roads.',
        source: 'Eve\'s driving theory guide',
        friendPick: 0,
      ),
      ProtoQuestion(
        q: 'What is the safest response to a dazzling oncoming headlight at night?',
        options: ['Flash your lights back', 'Look to the edge of your lane and slow down', 'Close one eye', 'Speed up to pass'],
        answer: 1,
        why: 'Look towards the edge of your lane, away from the glare, and slow down until you can see clearly.',
        quote: 'If dazzled, look towards the edge of your lane and slow down or stop if necessary.',
        source: 'Eve\'s driving theory guide',
        friendPick: 1,
      ),
    ],
  ),
];

StudySet setById(String? id) => studySets.firstWhere((s) => s.id == id, orElse: () => studySets.first);

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
