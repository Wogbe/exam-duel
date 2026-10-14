import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import 'achievements.dart';

/// An outfit Eve can wear. Bought with coins earned by playing.
class Outfit {
  final String id;
  final String name;
  final int price;
  const Outfit(this.id, this.name, this.price);

  static const all = [
    Outfit('none', 'No outfit', 0),
    Outfit('glasses', 'Reading glasses', 60),
    Outfit('scarf', 'Striped scarf', 120),
    Outfit('headphones', 'Headphones', 150),
    Outfit('cap', 'Graduation cap', 200),
    Outfit('jersey', 'Football jersey', 250),
    Outfit('tie', 'Smart tie', 90),
  ];
}

/// What the streak check did today, so the UI can celebrate it.
enum StreakEvent { none, started, extended, savedByFreeze, reset }

/// Local profile, progress and settings. Persisted with SharedPreferences.
class PlayerStore extends ChangeNotifier {
  PlayerStore(this._p);
  final SharedPreferences _p;

  static Future<PlayerStore> load() async => PlayerStore(await SharedPreferences.getInstance());

  // ---- profile ----
  String get nickname => _p.getString('nickname') ?? '';
  int get avatar => _p.getInt('avatar') ?? 0;
  bool get onboarded => nickname.isNotEmpty;

  Future<void> setProfile(String name, int avatar) async {
    await _p.setString('nickname', name.trim());
    await _p.setInt('avatar', avatar);
    notifyListeners();
  }

  // ---- profile photo ----
  // Stored as base64 so it works the same on phones and on the web.
  Uint8List? _photoCache;
  String? _photoCacheKey;

  String? get photoBase64 => _p.getString('photo');
  bool get hasPhoto => photoBase64 != null;

  Uint8List? get photo {
    final b64 = photoBase64;
    if (b64 == null) return null;
    if (_photoCacheKey != b64) {
      try {
        _photoCache = base64Decode(b64);
      } catch (_) {
        _photoCache = null;
      }
      _photoCacheKey = b64;
    }
    return _photoCache;
  }

  Future<void> setPhoto(Uint8List bytes) async {
    await _p.setString('photo', base64Encode(bytes));
    notifyListeners();
  }

  Future<void> clearPhoto() async {
    await _p.remove('photo');
    notifyListeners();
  }

  // ---- settings ----
  bool get dark => _p.getBool('dark') ?? false;
  bool get reduceMotion => _p.getBool('reduceMotion') ?? false;
  bool get haptics => _p.getBool('haptics') ?? true;
  bool get sound => _p.getBool('sound') ?? true;
  AccentChoice get accent => AccentChoice.byId(_p.getString('accent'));

  Future<void> setDark(bool v) async {
    await _p.setBool('dark', v);
    notifyListeners();
  }

  Future<void> setReduceMotion(bool v) async {
    await _p.setBool('reduceMotion', v);
    notifyListeners();
  }

  Future<void> setHaptics(bool v) async {
    await _p.setBool('haptics', v);
    notifyListeners();
  }

  Future<void> setSound(bool v) async {
    await _p.setBool('sound', v);
    notifyListeners();
  }

  Future<void> setAccent(AccentChoice a) async {
    await _p.setString('accent', a.id);
    notifyListeners();
  }

  // ---- progress ----
  int get xp => _p.getInt('xp') ?? 0;
  int get coins => _p.getInt('coins') ?? 50;
  int get level => 1 + xp ~/ 500;
  double get levelProgress => (xp % 500) / 500;
  int get gamesPlayed => _p.getInt('games') ?? 0;
  int get wins => _p.getInt('wins') ?? 0;
  int get bestQuickFire => _p.getInt('bestQuickFire') ?? 0;

  int get bestSurvival => _p.getInt('bestSurvival') ?? 0;
  int get bestCombo => _p.getInt('bestCombo') ?? 0;
  int get totalCorrect => _p.getInt('totalCorrect') ?? 0;
  int get bibleCorrect => _p.getInt('bibleCorrect') ?? 0;

  /// Counts one correct answer (any mode) for badges and stats.
  Future<void> countCorrect(String category) async {
    await _p.setInt('totalCorrect', totalCorrect + 1);
    if (category == 'bible') await _p.setInt('bibleCorrect', bibleCorrect + 1);
  }

  Future<void> recordCombo(int combo) async {
    if (combo > bestCombo) await _p.setInt('bestCombo', combo);
  }

  /// Returns true if this is a new best.
  Future<bool> recordSurvival(int correct) async {
    if (correct <= bestSurvival) return false;
    await _p.setInt('bestSurvival', correct);
    notifyListeners();
    return true;
  }

  Future<void> addReward({int xp = 0, int coins = 0, bool game = false, bool win = false}) async {
    await _p.setInt('xp', this.xp + xp);
    await _p.setInt('coins', this.coins + coins);
    if (game) await _p.setInt('games', gamesPlayed + 1);
    if (win) await _p.setInt('wins', wins + 1);
    notifyListeners();
  }

  /// Returns true if this is a new best.
  Future<bool> recordQuickFire(int correct) async {
    if (correct <= bestQuickFire) return false;
    await _p.setInt('bestQuickFire', correct);
    notifyListeners();
    return true;
  }

  // ---- Eve's wardrobe ----
  List<String> get ownedOutfits => _p.getStringList('outfits') ?? const ['none'];
  String get outfit => _p.getString('outfit') ?? 'none';

  Future<bool> buyOutfit(Outfit o) async {
    if (ownedOutfits.contains(o.id)) return true;
    if (coins < o.price) return false;
    await _p.setInt('coins', coins - o.price);
    await _p.setStringList('outfits', [...ownedOutfits, o.id]);
    await _p.setString('outfit', o.id);
    notifyListeners();
    return true;
  }

  Future<void> wearOutfit(String id) async {
    await _p.setString('outfit', id);
    notifyListeners();
  }

  // ---- streak ----
  int get _storedStreak => _p.getInt('streak') ?? 0;

  /// Current streak; 0 once it can no longer be saved.
  int get streak {
    final last = _lastDay;
    if (last == null) return 0;
    final d = DateTime.parse(last);
    final now = DateTime.now();
    final gap = DateTime.utc(now.year, now.month, now.day).difference(DateTime.utc(d.year, d.month, d.day)).inDays;
    final allowed = freezes > 0 ? 2 : 1;
    return gap <= allowed ? _storedStreak : 0;
  }
  int get longestStreak => _p.getInt('longest') ?? 0;
  int get freezes => _p.getInt('freezes') ?? 0;
  String? get _lastDay => _p.getString('lastDay');

  /// Days of the current week (Mon..Sun) that were active.
  Set<String> get activeDays => (_p.getStringList('activeDays') ?? const []).toSet();

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get playedToday => _lastDay == dayKey(DateTime.now());

  /// Whether the streak would break if the user skipped today.
  bool get streakAtRisk => streak > 0 && !playedToday;

  /// Marks today as active. Call when the user reads the daily fact
  /// or finishes any game. Safe to call many times a day.
  Future<StreakEvent> markActive({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final todayKey = dayKey(today);
    final last = _lastDay;
    if (last == todayKey) return StreakEvent.none;

    var event = StreakEvent.started;
    var s = 1;
    var f = freezes;
    if (last != null) {
      final lastDate = DateTime.parse(last);
      // UTC dates avoid 23-hour days around daylight-saving changes.
      final gap = DateTime.utc(today.year, today.month, today.day)
          .difference(DateTime.utc(lastDate.year, lastDate.month, lastDate.day))
          .inDays;
      if (gap <= 0) return StreakEvent.none; // clock moved back
      if (gap == 1) {
        s = _storedStreak + 1;
        event = StreakEvent.extended;
      } else if (gap == 2 && f > 0) {
        f -= 1;
        s = _storedStreak + 1;
        event = StreakEvent.savedByFreeze;
      } else {
        event = _storedStreak > 0 ? StreakEvent.reset : StreakEvent.started;
      }
    }
    // Earn a freeze every 7 days of streak, hold at most 2.
    if (s % 7 == 0 && f < 2) f += 1;

    final days = activeDays.where((d) => _sameWeek(DateTime.parse(d), today)).toSet()..add(todayKey);
    await _p.setString('lastDay', todayKey);
    await _p.setInt('streak', s);
    await _p.setInt('freezes', f);
    await _p.setStringList('activeDays', days.toList());
    if (s > longestStreak) await _p.setInt('longest', s);
    notifyListeners();
    return event;
  }

  static bool _sameWeek(DateTime a, DateTime b) {
    DateTime monday(DateTime d) => DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
    return monday(a) == monday(b);
  }

  // ---- daily fact ----
  bool get factSeenToday => _p.getString('factDay') == dayKey(DateTime.now());
  int get factsRead => _p.getInt('factsRead') ?? 0;

  Future<void> markFactSeen() async {
    if (!factSeenToday) await _p.setInt('factsRead', factsRead + 1);
    await _p.setString('factDay', dayKey(DateTime.now()));
    notifyListeners();
  }

  List<int> get _seenFacts => (_p.getStringList('seenFacts') ?? const []).map(int.tryParse).whereType<int>().toList();

  /// Today's fact for this player: a random one they have not seen yet,
  /// fixed for the rest of the day. Everyone gets a different order.
  /// Safe to call from build (it never notifies listeners).
  int dailyFactIndex(int total, {DateTime? now}) {
    if (total <= 0) return 0;
    final today = dayKey(now ?? DateTime.now());
    final stored = _p.getInt('factPickIdx');
    if (_p.getString('factPickDay') == today && stored != null && stored < total) return stored;
    final pick = _pickUnseenFact(total);
    _p.setString('factPickDay', today);
    _p.setInt('factPickIdx', pick);
    return pick;
  }

  /// A bonus fact (not today's), for "Another fact".
  Future<int> bonusFactIndex(int total) async {
    final pick = _pickUnseenFact(total, avoid: _p.getInt('factPickIdx'));
    await _p.setInt('factsRead', factsRead + 1);
    notifyListeners();
    return pick;
  }

  int _pickUnseenFact(int total, {int? avoid}) {
    var seen = _seenFacts.where((i) => i < total).toSet();
    var pool = [for (var i = 0; i < total; i++) if (!seen.contains(i) && i != avoid) i];
    if (pool.isEmpty) {
      // Read them all: start a new cycle.
      seen = {};
      pool = [for (var i = 0; i < total; i++) if (i != avoid) i];
    }
    final pick = pool.isEmpty ? 0 : pool[Random().nextInt(pool.length)];
    _p.setStringList('seenFacts', [...seen.map((i) => '$i'), '$pick']);
    return pick;
  }

  /// +5 XP for reacting to the daily fact, once a day. Returns true if given.
  Future<bool> rewardFactReaction() async {
    final today = dayKey(DateTime.now());
    if (_p.getString('factRewardDay') == today) return false;
    await _p.setString('factRewardDay', today);
    await addReward(xp: 5);
    return true;
  }

  // ---- questions already seen (so solo play keeps finding new ones) ----
  static const _seenCap = 1500;
  static const _remoteCap = 400;

  /// Stable across runs and platforms (String.hashCode is not).
  static String stemKey(String stem) {
    var h = 0x811c9dc5;
    for (final unit in stem.toLowerCase().codeUnits) {
      h ^= unit;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(36);
  }

  Set<String> get seenQuestions => (_p.getStringList('seenQ') ?? const []).toSet();
  List<String> get recentRemoteIds => _p.getStringList('seenRemote') ?? const [];

  Future<void> markQuestionSeen(String stem, {String? remoteId}) async {
    final list = _p.getStringList('seenQ') ?? <String>[];
    final key = stemKey(stem);
    if (!list.contains(key)) {
      list.add(key);
      if (list.length > _seenCap) list.removeRange(0, list.length - _seenCap);
      await _p.setStringList('seenQ', list);
    }
    if (remoteId != null) {
      final r = [...recentRemoteIds.where((x) => x != remoteId), remoteId];
      if (r.length > _remoteCap) r.removeRange(0, r.length - _remoteCap);
      await _p.setStringList('seenRemote', r);
    }
  }

  /// Forgets seen questions (used when every local question was seen).
  Future<void> resetSeenQuestions() => _p.remove('seenQ');

  // ---- badges ----
  Set<String> get badges => (_p.getStringList('badges') ?? const []).toSet();

  /// Unlocks every badge whose goal is now met, pays 20 coins for each, and
  /// returns the new ones so the UI can celebrate.
  Future<List<Achievement>> checkBadges() async {
    final have = badges;
    final fresh = Achievement.all.where((a) => !have.contains(a.id) && a.done(this)).toList();
    if (fresh.isEmpty) return const [];
    await _p.setStringList('badges', [...have, ...fresh.map((a) => a.id)]);
    await _p.setInt('coins', coins + 20 * fresh.length);
    notifyListeners();
    return fresh;
  }
}
