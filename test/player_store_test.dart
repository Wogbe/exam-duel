import 'package:exam_duel/data/models.dart';
import 'package:exam_duel/data/player_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PlayerStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await PlayerStore.load();
  });

  DateTime day(int d) => DateTime(2026, 10, d, 9);

  test('streak starts, extends, ignores repeats', () async {
    expect(await store.markActive(now: day(1)), StreakEvent.started);
    expect(await store.markActive(now: day(1)), StreakEvent.none);
    expect(await store.markActive(now: day(2)), StreakEvent.extended);
    expect(store.longestStreak, 2);
  });

  test('missing a day resets without a freeze', () async {
    await store.markActive(now: day(1));
    await store.markActive(now: day(2));
    expect(await store.markActive(now: day(4)), StreakEvent.reset);
    expect(store.longestStreak, 2);
  });

  test('7-day streak earns a freeze that saves one missed day', () async {
    for (var d = 1; d <= 7; d++) {
      await store.markActive(now: day(d));
    }
    expect(store.freezes, 1);
    expect(await store.markActive(now: day(9)), StreakEvent.savedByFreeze);
    expect(store.freezes, 0);
    expect(store.longestStreak, 8);
  });

  test('cannot buy without enough coins, can after earning', () async {
    final cap = Outfit.all.firstWhere((o) => o.id == 'cap');
    expect(await store.buyOutfit(cap), isFalse);
    await store.addReward(coins: 200);
    expect(await store.buyOutfit(cap), isTrue);
    expect(store.outfit, 'cap');
    expect(store.coins, 50);
  });

  test('room settings parse server JSON', () {
    final s = RoomSettings.fromJson({'count': 5, 'seconds': 20, 'categories': ['science'], 'ai_batch': 'x'});
    expect(s.count, 5);
    expect(s.hasAiBatch, isTrue);
    expect(s.summary, '5 questions · 20s · Science');
    expect(s.toJson().containsKey('ai_batch'), isFalse);
  });
}
