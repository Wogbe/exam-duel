import 'dart:async';

import 'package:exam_duel/data/game_repository.dart';
import 'package:exam_duel/data/models.dart';
import 'package:exam_duel/state/room_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel, RealtimeClient;

/// A repository with no Supabase behind it: tests push rooms in and read the calls out.
class FakeRepo extends GameRepository {
  FakeRepo({this.me = 'me'});
  final String me;
  DateTime clock = DateTime.utc(2026, 10, 12, 12);
  final rooms = StreamController<Room?>.broadcast();
  final playerList = StreamController<List<Player>>.broadcast();
  final reveals = <int>[];
  final nexts = <int>[];
  final answers = <int>[];
  Object? startError;

  @override
  String? get userId => me;
  @override
  DateTime get serverNow => clock;
  @override
  Stream<Room?> watchRoom(String roomId) => rooms.stream;
  @override
  Stream<List<Player>> watchPlayers(String roomId) => playerList.stream;
  @override
  RealtimeChannel emoteChannel(String roomId, void Function(String, String) onEmote) =>
      RealtimeChannel('room-emotes:$roomId', RealtimeClient('ws://localhost:1/realtime'));
  @override
  Future<void> closeChannel(RealtimeChannel ch) async {}
  @override
  Future<Question> fetchQuestion(String roomId, int idx) async =>
      Question(stem: 'Q$idx', options: const ['a', 'b', 'c', 'd'], category: 'random', answer: null);
  @override
  Future<void> revealQuestion(String roomId, int idx) async => reveals.add(idx);
  @override
  Future<void> nextQuestion(String roomId, int idx) async => nexts.add(idx);
  @override
  Future<AnswerResult?> submitAnswer(String roomId, int idx, int choice) async {
    answers.add(choice);
    return AnswerResult(choice == 1, choice == 1 ? 700 : 0, 1);
  }

  @override
  Future<Room> startGame(String roomId) async {
    if (startError != null) throw startError!;
    return room(RoomStatus.question, index: 0);
  }

  Room room(RoomStatus s, {int index = 0, Duration? since, String host = 'me', int seconds = 15}) => Room(
        id: 'r1',
        code: 'ABCDE',
        hostId: host,
        status: s,
        currentIndex: s == RoomStatus.lobby ? -1 : index,
        questionCount: 3,
        phaseStartedAt: since == null ? null : clock.subtract(since),
        settings: RoomSettings(seconds: seconds),
      );
}

Player player(String id, {int answered = -1}) => Player(
      userId: id,
      nickname: id,
      avatar: 0,
      score: 0,
      streak: 0,
      answeredIndex: answered,
      lastCorrect: false,
      lastPoints: 0,
      isHost: false,
    );

void main() {
  late FakeRepo repo;
  late RoomController ctl;
  final made = <RoomController>[];

  RoomController make(FakeRepo r, Room initial) {
    final c = RoomController(r, initial);
    made.add(c);
    return c;
  }

  // Controllers own a periodic timer, so each one is disposed before the test ends.
  void ctlTest(String name, Future<void> Function(WidgetTester t) body) => testWidgets(name, (t) async {
        try {
          await body(t);
        } finally {
          for (final c in made) {
            c.dispose();
          }
          made.clear();
        }
      });

  /// Starts a controller on the already-created [repo].
  Future<void> start(WidgetTester t, Room initial) async {
    ctl = make(repo, initial);
    await t.pump(const Duration(milliseconds: 10));
  }

  ctlTest('asks the server to reveal once, after the timer runs out', (t) async {
    repo = FakeRepo();
    final r = repo.room(RoomStatus.question, since: const Duration(seconds: 16));
    await start(t, r);
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 600));
    expect(repo.reveals, [0]);
  });

  ctlTest('does not reveal while time is left', (t) async {
    repo = FakeRepo();
    await start(t, repo.room(RoomStatus.question, since: const Duration(seconds: 5)));
    await t.pump(const Duration(seconds: 1));
    expect(repo.reveals, isEmpty);
    expect(ctl.secondsLeft, inInclusiveRange(9, 10));
  });

  ctlTest('host advances after the reveal pause, a guest waits for the fallback', (t) async {
    repo = FakeRepo();
    await start(t, repo.room(RoomStatus.reveal, since: const Duration(seconds: 5)));
    await t.pump(const Duration(milliseconds: 300));
    expect(repo.nexts, [0]);

    repo = FakeRepo(me: 'guest');
    ctl = make(repo, repo.room(RoomStatus.reveal, since: const Duration(seconds: 5)));
    await t.pump(const Duration(milliseconds: 300));
    expect(repo.nexts, isEmpty, reason: 'a guest only steps in after 12.5 s');

    repo.clock = repo.clock.add(const Duration(seconds: 8));
    await t.pump(const Duration(milliseconds: 300));
    expect(repo.nexts, [0]);
  });

  ctlTest('a second tap on an answer is ignored and the server result is kept', (t) async {
    repo = FakeRepo();
    await start(t, repo.room(RoomStatus.question, since: const Duration(seconds: 1)));
    await t.pump(const Duration(milliseconds: 300));
    expect(ctl.question?.stem, 'Q0');
    await ctl.answer(1);
    await ctl.answer(2);
    expect(repo.answers, [1]);
    expect(ctl.myResult?.points, 700);
  });

  ctlTest('a rematch clears the last round', (t) async {
    repo = FakeRepo();
    await start(t, repo.room(RoomStatus.question, since: const Duration(seconds: 1)));
    await t.pump(const Duration(milliseconds: 300));
    await ctl.answer(1);
    repo.rooms.add(repo.room(RoomStatus.finished, index: 2));
    await t.pump(const Duration(milliseconds: 10));
    repo.rooms.add(repo.room(RoomStatus.question, index: 0, since: const Duration(seconds: 1)));
    await t.pump(const Duration(milliseconds: 10));
    expect(ctl.myChoice, isNull);
    expect(ctl.myResult, isNull);
  });

  ctlTest('closes when the room is deleted or we are removed', (t) async {
    repo = FakeRepo();
    await start(t, repo.room(RoomStatus.lobby));
    repo.playerList.add([player('me'), player('friend')]);
    await t.pump(const Duration(milliseconds: 10));
    expect(ctl.closed, isFalse);
    repo.playerList.add([player('friend')]);
    await t.pump(const Duration(milliseconds: 10));
    expect(ctl.closed, isTrue);
  });

  ctlTest('closes when the room row disappears', (t) async {
    repo = FakeRepo();
    await start(t, repo.room(RoomStatus.lobby));
    repo.rooms.add(null);
    await t.pump(const Duration(milliseconds: 10));
    expect(ctl.closed, isTrue);
  });

  ctlTest('start() surfaces the server message and rethrows', (t) async {
    repo = FakeRepo();
    await start(t, repo.room(RoomStatus.lobby));
    repo.startError = GameException('No questions in those categories yet.');
    await expectLater(ctl.start(), throwsA(isA<GameException>()));
    expect(ctl.error, 'No questions in those categories yet.');
  });

  test('Room.fromJson reads a server row and falls back on unknown status', () {
    final r = Room.fromJson({
      'id': 'x',
      'code': 'ABCDE',
      'host_id': 'h',
      'status': 'nonsense',
      'current_index': null,
      'phase_started_at': '2026-10-12T12:00:00Z',
      'settings': {'count': 5, 'seconds': 20, 'ai_batch': {}},
    });
    expect(r.status, RoomStatus.lobby);
    expect(r.currentIndex, -1);
    expect(r.settings.hasAiBatch, isTrue);
    expect(r.phaseStartedAt, DateTime.utc(2026, 10, 12, 12));
  });
}
