import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

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

  // ---- settings ----
  bool get dark => _p.getBool('dark') ?? false;
  bool get reduceMotion => _p.getBool('reduceMotion') ?? false;
  bool get haptics => _p.getBool('haptics') ?? true;
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
  Future<void> markFactSeen() async {
    await _p.setString('factDay', dayKey(DateTime.now()));
    notifyListeners();
  }
}
