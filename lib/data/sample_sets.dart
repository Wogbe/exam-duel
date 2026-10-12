import '../theme/mastery.dart';
import 'study_set.dart';

// Sample content for the preview. In the real app Eve (AI) builds all of this
// from what the learner snaps, pastes or types.

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
      StudyTopic('Cell structure', '🔬', Mastery.ready),
      StudyTopic('Organelles', '🧩', Mastery.solid),
      StudyTopic('Mitosis', '🧬', Mastery.shaky),
      StudyTopic('Meiosis', '🔀', Mastery.unseen),
      StudyTopic('Membranes', '🫧', Mastery.solid),
      StudyTopic('Enzymes', '⚗️', Mastery.shaky),
      StudyTopic('Respiration', '🌬️', Mastery.solid),
      StudyTopic('Photosynthesis', '🌿', Mastery.ready),
      StudyTopic('DNA', '🧵', Mastery.solid),
      StudyTopic('Proteins', '🥚', Mastery.unseen),
      StudyTopic('Cell cycle', '🔄', Mastery.shaky),
      StudyTopic('Microscopy', '🔭', Mastery.unseen),
    ],
    questions: [
      StudyQuestion(
        q: 'In which phase of mitosis do chromosomes line up in the middle of the cell?',
        options: ['Prophase', 'Metaphase', 'Anaphase', 'Telophase'],
        answer: 1,
        why: 'Metaphase: "meta" means middle. The spindle pulls every chromosome onto the cell\'s equator.',
        quote: 'During metaphase the chromosomes line up along the middle of the cell, attached to spindle fibres.',
        source: 'Your notes · page 2',
        friendPick: 1,
      ),
      StudyQuestion(
        q: 'How many daughter cells does one round of mitosis make?',
        options: ['One', 'Two', 'Four', 'Eight'],
        answer: 1,
        why: 'Mitosis makes two identical cells. Four is meiosis, the one that makes sex cells.',
        quote: 'Mitosis produces two genetically identical daughter cells.',
        source: 'Your notes · page 1',
        friendPick: 2,
      ),
      StudyQuestion(
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
      StudyTopic('Greetings', '👋', Mastery.ready),
      StudyTopic('Numbers', '🔢', Mastery.solid),
      StudyTopic('Food', '🥐', Mastery.solid),
      StudyTopic('Passé composé', '⏪', Mastery.shaky),
      StudyTopic('Travel', '🧳', Mastery.shaky),
      StudyTopic('Family', '👪', Mastery.solid),
      StudyTopic('Weather', '🌦️', Mastery.unseen),
      StudyTopic('Directions', '🧭', Mastery.unseen),
      StudyTopic('Shopping', '🛍️', Mastery.shaky),
      StudyTopic('Time', '⏰', Mastery.solid),
      StudyTopic('Hobbies', '🎨', Mastery.unseen),
      StudyTopic('Body', '🦵', Mastery.unseen),
    ],
    questions: [
      StudyQuestion(
        q: 'Which is correct for "I went to the market"?',
        options: ["J'ai allé au marché", 'Je suis allé au marché', 'Je vais au marché', "J'allais au marché"],
        answer: 1,
        why: 'Aller is one of the movement verbs that take être in the passé composé: je suis allé(e).',
        quote: 'Verbs of movement such as aller, venir and partir use être: je suis allé(e).',
        source: 'Eve\'s A2 topic guide',
        friendPick: 0,
      ),
      StudyQuestion(
        q: '"Nous ___ mangé une pizza." Which word fills the gap?',
        options: ['sommes', 'avons', 'êtes', 'ont'],
        answer: 1,
        why: 'Most verbs, including manger, use avoir. With nous it becomes "avons".',
        quote: 'Most verbs form the passé composé with avoir: nous avons mangé.',
        source: 'Eve\'s A2 topic guide',
        friendPick: 1,
      ),
      StudyQuestion(
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
      StudyTopic('Road signs', '🛑', Mastery.ready),
      StudyTopic('Right of way', '↔️', Mastery.solid),
      StudyTopic('Speed', '🏎️', Mastery.solid),
      StudyTopic('Roundabouts', '🔁', Mastery.ready),
      StudyTopic('Parking', '🅿️', Mastery.solid),
      StudyTopic('Hazards', '⚠️', Mastery.shaky),
      StudyTopic('Night driving', '🌙', Mastery.shaky),
      StudyTopic('Bad weather', '🌧️', Mastery.solid),
      StudyTopic('Pedestrians', '🚶', Mastery.solid),
      StudyTopic('Safety checks', '🔧', Mastery.unseen),
      StudyTopic('Motorways', '🛣️', Mastery.unseen),
      StudyTopic('Emergencies', '🚑', Mastery.unseen),
    ],
    questions: [
      StudyQuestion(
        q: 'A ball rolls into the road ahead. What should you expect?',
        options: ['Nothing, keep going', 'A child may follow it', 'The road is closed', 'A speed camera'],
        answer: 1,
        why: 'A ball is a classic hazard clue: a child may run out after it. Slow down and be ready to stop.',
        quote: 'Look for clues to hazards, such as a ball in the road, which may be followed by a child.',
        source: 'Eve\'s driving theory guide',
        friendPick: 1,
      ),
      StudyQuestion(
        q: 'In wet weather, your stopping distance can be about…',
        options: ['The same', 'Half as long', 'Twice as long', 'Ten times as long'],
        answer: 2,
        why: 'Wet roads give tyres less grip, so stopping distances can double. Leave a bigger gap.',
        quote: 'On wet roads, stopping distances can be at least double those on dry roads.',
        source: 'Eve\'s driving theory guide',
        friendPick: 0,
      ),
      StudyQuestion(
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
