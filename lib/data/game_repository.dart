import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import 'models.dart';

/// Friendly error shown to players.
class GameException implements Exception {
  final String message;
  GameException(this.message);
  @override
  String toString() => message;
}

/// All online multiplayer calls. Scoring and timing happen on the server
/// (see supabase/migrations); this class only calls RPCs and listens.
class GameRepository {
  GameRepository();

  bool get enabled => AppConfig.onlineEnabled;
  SupabaseClient get _db => Supabase.instance.client;
  String? get userId => enabled ? _db.auth.currentUser?.id : null;

  /// Difference between server and device clocks.
  Duration serverOffset = Duration.zero;
  DateTime get serverNow => DateTime.now().add(serverOffset);

  Future<void> ensureSignedIn() async {
    if (!enabled) throw GameException('Online play is not set up yet. See the README.');
    if (_db.auth.currentSession == null) {
      await _guard(() => _db.auth.signInAnonymously());
    }
    await syncClock();
  }

  Future<void> syncClock() async {
    final sent = DateTime.now();
    final res = await _db.rpc('server_now');
    final received = DateTime.now();
    final server = DateTime.parse(res as String);
    final midpoint = sent.add(received.difference(sent) ~/ 2);
    serverOffset = server.difference(midpoint);
  }

  Future<Room> createRoom(String nickname, int avatar, RoomSettings settings) => _guard(() async {
        final res = await _db.rpc('create_room', params: {
          'p_nickname': nickname,
          'p_avatar': avatar,
          'p_settings': settings.toJson(),
        });
        return Room.fromJson(_row(res));
      });

  Future<Room> joinRoom(String code, String nickname, int avatar) => _guard(() async {
        final res = await _db.rpc('join_room', params: {
          'p_code': code.trim().toUpperCase(),
          'p_nickname': nickname,
          'p_avatar': avatar,
        });
        return Room.fromJson(_row(res));
      });

  Future<void> leaveRoom(String roomId) => _guard(() => _db.rpc('leave_room', params: {'p_room': roomId}));

  Future<Room> updateSettings(String roomId, RoomSettings s) => _guard(() async {
        final res = await _db.rpc('update_room_settings', params: {'p_room': roomId, 'p_settings': s.toJson()});
        return Room.fromJson(_row(res));
      });

  Future<Room> startGame(String roomId) => _guard(() async {
        final res = await _db.rpc('start_game', params: {'p_room': roomId});
        return Room.fromJson(_row(res));
      });

  /// Returns null when the server ignored the answer (late or duplicate).
  Future<AnswerResult?> submitAnswer(String roomId, int idx, int choice) => _guard(() async {
        final res = await _db.rpc('submit_answer', params: {'p_room': roomId, 'p_idx': idx, 'p_choice': choice});
        final m = Map<String, dynamic>.from(res as Map);
        if (m['accepted'] != true) return null;
        return AnswerResult(m['correct'] == true, (m['points'] as num).toInt(), (m['streak'] as num).toInt());
      });

  Future<void> revealQuestion(String roomId, int idx) =>
      _guard(() => _db.rpc('reveal_question', params: {'p_room': roomId, 'p_idx': idx}));

  Future<void> nextQuestion(String roomId, int idx) =>
      _guard(() => _db.rpc('next_question', params: {'p_room': roomId, 'p_idx': idx}));

  Future<Question> fetchQuestion(String roomId, int idx) => _guard(() async {
        final row = await _db
            .from('room_questions')
            .select()
            .eq('room_id', roomId)
            .eq('idx', idx)
            .single();
        return Question(
          stem: row['stem'] as String,
          options: (row['options'] as List).cast<String>(),
          category: row['category'] as String,
          answer: (row['revealed_index'] as num?)?.toInt(),
        );
      });

  /// Asks Eve (Claude, via the edge function) for questions on a topic and
  /// attaches them to the room. Returns how many were added.
  Future<int> generateAiQuestions(String roomId, String topic, int count) => _guard(() async {
        final res = await _db.functions.invoke('generate-questions', body: {
          'room_id': roomId,
          'topic': topic,
          'count': count,
        });
        final data = Map<String, dynamic>.from(res.data as Map);
        if (data['error'] != null) throw GameException(data['error'] as String);
        return (data['count'] as num).toInt();
      });

  Stream<Room?> watchRoom(String roomId) => _db
      .from('rooms')
      .stream(primaryKey: ['id'])
      .eq('id', roomId)
      .map((rows) => rows.isEmpty ? null : Room.fromJson(rows.first));

  Stream<List<Player>> watchPlayers(String roomId) => _db
      .from('room_players')
      .stream(primaryKey: ['room_id', 'user_id'])
      .eq('room_id', roomId)
      .map((rows) => rows.map(Player.fromJson).toList());

  /// Fresh questions from the online bank for solo play (thousands, growing
  /// daily). Works without signing in. Returns an empty list when offline.
  Future<List<Question>> practiceQuestions({
    int count = 30,
    List<String> categories = const [],
    List<String> exclude = const [],
  }) async {
    if (!enabled) return const [];
    try {
      final res = await _db.rpc('practice_questions', params: {
        'p_count': count,
        'p_categories': categories,
        'p_exclude': exclude,
      });
      if (res is! List) return const [];
      final rng = Random();
      return [
        for (final e in res)
          if (e is Map) Question.fromBank(Map<String, dynamic>.from(e), rng),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Shares the player's photo with everyone in the room. Best effort.
  Future<void> setRoomPhoto(String roomId, String base64Photo) async {
    if (!enabled) return;
    try {
      await _db.rpc('set_room_photo', params: {'p_room': roomId, 'p_photo': base64Photo});
    } catch (_) {
      // Photos are decoration; the game goes on without them.
    }
  }

  /// Photos of the players in a room, by user id.
  Future<Map<String, Uint8List>> fetchRoomPhotos(String roomId) async {
    if (!enabled) return const {};
    try {
      final rows = await _db.from('room_player_photos').select('user_id, photo').eq('room_id', roomId);
      final out = <String, Uint8List>{};
      for (final r in rows) {
        try {
          out[r['user_id'] as String] = base64Decode(r['photo'] as String);
        } catch (_) {}
      }
      return out;
    } catch (_) {
      return const {};
    }
  }

  /// Lightweight emote channel (not stored).
  RealtimeChannel emoteChannel(String roomId, void Function(String userId, String emote) onEmote) {
    final ch = _db.channel('room-emotes:$roomId');
    ch.onBroadcast(
      event: 'emote',
      callback: (msg) {
        // Depending on the client version the data may be nested in 'payload'.
        final p = msg['payload'] is Map ? Map<String, dynamic>.from(msg['payload'] as Map) : msg;
        onEmote(p['user'] as String? ?? '', p['emote'] as String? ?? '');
      },
    );
    ch.subscribe();
    return ch;
  }

  Future<void> sendEmote(RealtimeChannel ch, String emote) =>
      ch.sendBroadcastMessage(event: 'emote', payload: {'user': userId, 'emote': emote});

  Future<void> closeChannel(RealtimeChannel ch) => _db.removeChannel(ch);

  static Map<String, dynamic> _row(dynamic res) {
    if (res is List) return Map<String, dynamic>.from(res.first as Map);
    return Map<String, dynamic>.from(res as Map);
  }

  Future<R> _guard<R>(Future<R> Function() f) async {
    try {
      return await f();
    } on GameException {
      rethrow;
    } on PostgrestException catch (e) {
      throw GameException(_friendly(e.message));
    } on FunctionException catch (e) {
      final d = e.details;
      throw GameException(d is Map && d['error'] != null ? d['error'].toString() : 'Eve could not reach the server.');
    } on AuthException catch (e) {
      throw GameException(e.message.contains('Anonymous')
          ? 'Turn on anonymous sign-ins in Supabase (Auth › Providers).'
          : e.message);
    } catch (_) {
      throw GameException('No connection. Check your data and try again.');
    }
  }

  static String _friendly(String m) {
    if (m.contains('room not found')) return 'No room with that code.';
    if (m.contains('already started')) return 'That game has already started.';
    if (m.contains('full')) return 'That room is full (12 players).';
    if (m.contains('no questions')) return 'No questions in those categories yet.';
    return m;
  }
}
