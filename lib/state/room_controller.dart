import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

import '../data/game_repository.dart';
import '../data/models.dart';

/// Live state of one online room, shared by lobby, game and results screens.
class RoomController extends ChangeNotifier {
  RoomController(this.repo, Room initial) : room = initial {
    _roomSub = repo.watchRoom(initial.id).listen(_onRoom, onError: (_) => _setError('Connection lost. Reconnecting…'));
    _playersSub = repo.watchPlayers(initial.id).listen(_onPlayers, onError: (_) {});
    _emotes = repo.emoteChannel(initial.id, _onEmote);
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  static const revealDuration = Duration(milliseconds: 4500);

  final GameRepository repo;
  Room room;
  List<Player> players = const [];
  Question? question;
  int? myChoice;
  AnswerResult? myResult;
  String? error;
  bool closed = false; // room deleted or we left

  /// Players' profile photos by user id (only those who added one).
  Map<String, Uint8List> photos = const {};
  String _photoIds = '';

  /// Latest emote per player, cleared after a few seconds.
  final Map<String, ({String emote, DateTime at})> emotes = {};

  StreamSubscription<Room?>? _roomSub;
  StreamSubscription<List<Player>>? _playersSub;
  RealtimeChannel? _emotes;
  Timer? _ticker;
  int _loadedIdx = -1;
  bool _loadedRevealed = false;
  int _revealAskedFor = -1;
  int _nextAskedFor = -1;

  String? get me => repo.userId;
  bool get isHost => room.hostId == me;
  Player? get mePlayer => players.where((p) => p.userId == me).firstOrNull;

  List<Player> get ranked => [...players]..sort((a, b) => b.score.compareTo(a.score));

  int get answeredCount => players.where((p) => p.answeredIndex >= room.currentIndex).length;

  DateTime? get _deadline => room.phaseStartedAt?.add(Duration(seconds: room.settings.seconds));

  /// 1.0 at the start of a question, 0.0 when time is up.
  double get timeLeftFraction {
    final d = _deadline;
    if (d == null || room.status != RoomStatus.question) return 0;
    final left = d.difference(repo.serverNow).inMilliseconds / (room.settings.seconds * 1000);
    return left.clamp(0.0, 1.0);
  }

  int get secondsLeft => (timeLeftFraction * room.settings.seconds).ceil();

  /// 1.0 → 0.0 during the reveal pause, for the "next question" bar.
  double get revealProgress {
    final start = room.phaseStartedAt;
    if (start == null || room.status != RoomStatus.reveal) return 0;
    final t = repo.serverNow.difference(start).inMilliseconds / revealDuration.inMilliseconds;
    return t.clamp(0.0, 1.0);
  }

  void _onRoom(Room? r) {
    if (r == null) {
      closed = true;
      notifyListeners();
      return;
    }
    final prev = room;
    final newGame = r.status == RoomStatus.question &&
        (prev.status == RoomStatus.lobby ||
            prev.status == RoomStatus.finished ||
            r.currentIndex < prev.currentIndex);
    room = r;
    error = null;
    if (newGame) {
      // Rematch or first game: forget everything from the last round.
      _revealAskedFor = -1;
      _nextAskedFor = -1;
      _resetQuestion();
    } else if (r.currentIndex != prev.currentIndex) {
      _resetQuestion();
    }
    if (r.status == RoomStatus.lobby) _resetQuestion();
    _ensureQuestion();
    notifyListeners();
  }

  void _resetQuestion() {
    question = null;
    myChoice = null;
    myResult = null;
    _loadedIdx = -1;
    _loadedRevealed = false;
  }

  /// Loads the current question, or reloads it to get the revealed answer.
  void _ensureQuestion() {
    final r = room;
    if ((r.status != RoomStatus.question && r.status != RoomStatus.reveal) || r.currentIndex < 0) return;
    final wantRevealed = r.status == RoomStatus.reveal;
    if (r.currentIndex != _loadedIdx || (wantRevealed && !_loadedRevealed)) {
      _loadQuestion(r.currentIndex, wantRevealed);
    }
  }

  Future<void> _loadQuestion(int idx, bool revealed) async {
    _loadedIdx = idx;
    _loadedRevealed = revealed;
    try {
      final q = await repo.fetchQuestion(room.id, idx);
      // Ignore stale responses (a newer index, or the revealed copy already arrived).
      if (room.currentIndex != idx || (!revealed && question?.answer != null)) return;
      question = q;
      error = null;
      if (revealed && q.answer == null) _loadedRevealed = false; // retry on next tick
      notifyListeners();
    } catch (e) {
      if (room.currentIndex == idx) {
        _loadedIdx = -1;
        _loadedRevealed = false;
      }
      _setError(e.toString());
    }
  }

  void _onPlayers(List<Player> list) {
    players = list;
    final ids = (list.map((p) => '${p.userId}:${p.hasPhoto}').toList()..sort()).join(',');
    if (ids != _photoIds) {
      _photoIds = ids;
      _loadPhotos();
    }
    if (me != null && list.isNotEmpty && !list.any((p) => p.userId == me)) {
      closed = true; // we were removed
    }
    notifyListeners();
  }

  void _onEmote(String userId, String emote) {
    emotes[userId] = (emote: emote, at: DateTime.now());
    notifyListeners();
  }

  void _tick() {
    final now = repo.serverNow;
    _ensureQuestion(); // retries failed loads
    emotes.removeWhere((_, v) => DateTime.now().difference(v.at) > const Duration(seconds: 3));

    if (room.status == RoomStatus.question) {
      final d = _deadline;
      if (d != null && now.isAfter(d.add(const Duration(milliseconds: 400))) && _revealAskedFor != room.currentIndex) {
        _revealAskedFor = room.currentIndex;
        repo.revealQuestion(room.id, room.currentIndex).catchError((Object _) {
          _revealAskedFor = -1;
        });
      }
    } else if (room.status == RoomStatus.reveal) {
      final start = room.phaseStartedAt;
      if (start != null && _nextAskedFor != room.currentIndex) {
        final waited = now.difference(start);
        // Host advances; anyone else steps in if the host has gone quiet.
        if ((isHost && waited >= revealDuration) || waited >= const Duration(milliseconds: 12500)) {
          _nextAskedFor = room.currentIndex;
          repo.nextQuestion(room.id, room.currentIndex).catchError((Object _) {
            _nextAskedFor = -1;
          });
        }
      }
    }
    if (room.status == RoomStatus.question || room.status == RoomStatus.reveal || emotes.isNotEmpty) {
      notifyListeners();
    }
  }

  Future<void> answer(int choice) async {
    if (myChoice != null || question == null || room.status != RoomStatus.question) return;
    final idx = room.currentIndex;
    myChoice = choice;
    notifyListeners();
    try {
      final res = await repo.submitAnswer(room.id, idx, choice);
      if (room.currentIndex == idx) myResult = res;
    } catch (e) {
      _setError(e.toString());
    }
    notifyListeners();
  }

  Future<void> start() async {
    try {
      _onRoom(await repo.startGame(room.id));
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> updateSettings(RoomSettings s) async {
    try {
      _onRoom(await repo.updateSettings(room.id, s));
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _loadPhotos() async {
    final p = await repo.fetchRoomPhotos(room.id);
    if (_disposed) return;
    photos = p;
    notifyListeners();
  }

  /// Shares our photo with the room, then refreshes everyone's.
  Future<void> sharePhoto(String base64Photo) async {
    await repo.setRoomPhoto(room.id, base64Photo);
    await _loadPhotos();
  }

  Future<int> addAiQuestions(String topic, int count) => repo.generateAiQuestions(room.id, topic, count);

  Future<void> sendEmote(String emote) async {
    final ch = _emotes;
    if (ch == null || me == null) return;
    _onEmote(me!, emote); // show our own instantly
    await repo.sendEmote(ch, emote);
  }

  Future<void> leave() async {
    closed = true;
    try {
      await repo.leaveRoom(room.id);
    } catch (_) {}
  }

  void _setError(String e) {
    error = e;
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _roomSub?.cancel();
    _playersSub?.cancel();
    final ch = _emotes;
    if (ch != null) repo.closeChannel(ch);
    super.dispose();
  }
}
