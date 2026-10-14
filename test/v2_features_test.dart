import 'dart:convert';

import 'package:exam_duel/data/achievements.dart';
import 'package:exam_duel/data/game_repository.dart';
import 'package:exam_duel/data/local_bank.dart';
import 'package:exam_duel/data/models.dart';
import 'package:exam_duel/data/player_store.dart';
import 'package:exam_duel/screens/solo_screen.dart';
import 'package:exam_duel/theme/app_theme.dart';
import 'package:exam_duel/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A 1×1 transparent PNG.
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

void main() {
  late PlayerStore store;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    store = await PlayerStore.load();
  });

  group('fact of the day', () {
    test('stays the same all day, and every fact comes up once before any repeats', () {
      const total = 10;
      final picks = <int>[];
      for (var d = 1; d <= total; d++) {
        final morning = store.dailyFactIndex(total, now: DateTime(2026, 10, d, 8));
        final evening = store.dailyFactIndex(total, now: DateTime(2026, 10, d, 21));
        expect(evening, morning, reason: 'day $d changed during the day');
        picks.add(morning);
      }
      expect(picks.toSet().length, total, reason: 'a fact repeated before all were shown: $picks');
      // Day 11 starts a new cycle and still works.
      expect(store.dailyFactIndex(total, now: DateTime(2026, 10, 11)), inInclusiveRange(0, total - 1));
    });

    test('players get different orders (it is random, not by date)', () async {
      final orders = <String>{};
      for (var player = 0; player < 6; player++) {
        SharedPreferences.setMockInitialValues({});
        final s = await PlayerStore.load();
        orders.add([for (var d = 1; d <= 5; d++) s.dailyFactIndex(50, now: DateTime(2026, 10, d))].join(','));
      }
      expect(orders.length, greaterThan(1));
    });

    test('a reaction pays 5 XP once a day; bonus facts count as read', () async {
      expect(await store.rewardFactReaction(), isTrue);
      expect(await store.rewardFactReaction(), isFalse);
      expect(store.xp, 5);
      final today = store.dailyFactIndex(20);
      final bonus = await store.bonusFactIndex(20);
      expect(bonus, isNot(today));
      expect(store.factsRead, 1);
      await store.markFactSeen();
      await store.markFactSeen();
      expect(store.factsRead, 2, reason: 'the daily fact counts once a day');
    });
  });

  group('photos and badges', () {
    test('a photo is saved, read back and removed', () async {
      expect(store.hasPhoto, isFalse);
      await store.setPhoto(_png);
      expect(store.photo, _png);
      await store.clearPhoto();
      expect(store.photo, isNull);
    });

    test('badges unlock once, pay 20 coins each, and survive a reload', () async {
      final coins = store.coins;
      await store.setPhoto(_png);
      await store.addReward(game: true);
      final fresh = await store.checkBadges();
      expect(fresh.map((a) => a.id), containsAll(['photo', 'first_game']));
      expect(store.coins, coins + 20 * fresh.length);
      expect(await store.checkBadges(), isEmpty);
      final again = await PlayerStore.load();
      expect(again.badges, containsAll(['photo', 'first_game']));
    });

    test('every badge has a unique id', () {
      final ids = Achievement.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    testWidgets('Avatar shows a photo when given one, an initial otherwise', (t) async {
      await t.pumpWidget(MaterialApp(
        theme: buildTheme(dark: false, accent: AccentChoice.aqua),
        home: Scaffold(
          body: PlayerPhotos(
            photos: {'u1': _png},
            child: const Column(children: [
              Avatar(initial: 'A', index: 0, userId: 'u1'),
              Avatar(initial: 'B', index: 1, userId: 'u2'),
            ]),
          ),
        ),
      ));
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('A'), findsNothing);
    });
  });

  group('question variety', () {
    test('stem keys are stable and ignore case', () {
      expect(PlayerStore.stemKey('What is 2 + 2?'), PlayerStore.stemKey('what is 2 + 2?'));
      expect(PlayerStore.stemKey('Q1'), isNot(PlayerStore.stemKey('Q2')));
    });

    test('seen questions are capped so storage stays small', () async {
      for (var i = 0; i < 1600; i++) {
        await store.markQuestionSeen('Question $i', remoteId: 'id$i');
      }
      expect(store.seenQuestions.length, 1500);
      expect(store.recentRemoteIds.length, 400);
      expect(store.recentRemoteIds.last, 'id1599');
    });

    testWidgets('a solo game never repeats a question until the pool is used up', (t) async {
      final bank = (await t.runAsync(LocalBank.load))!;
      final feed = QuestionFeed(bank: bank, store: store, repo: GameRepository(), categories: const ['bible']);
      final stems = <String>[];
      for (var i = 0; i < 40; i++) {
        stems.add(feed.next()!.stem);
      }
      expect(stems.toSet().length, 40);
    });

    testWidgets('a new game starts with questions the player has not seen', (t) async {
      final bank = (await t.runAsync(LocalBank.load))!;
      final first = QuestionFeed(bank: bank, store: store, repo: GameRepository(), categories: const ['bible']);
      final seen = {for (var i = 0; i < 20; i++) first.next()!.stem};
      final second = QuestionFeed(bank: bank, store: store, repo: GameRepository(), categories: const ['bible']);
      final next = [for (var i = 0; i < 20; i++) second.next()!.stem];
      expect(next.where(seen.contains), isEmpty);
    });

    testWidgets('the bundled bank has the Bible category and enough facts', (t) async {
      final bank = (await t.runAsync(LocalBank.load))!;
      final bible = bank.drawFresh(500, const {}, PlayerStore.stemKey, categories: const ['bible']);
      expect(bible.length, greaterThanOrEqualTo(50));
      expect(bible.every((q) => q.category == 'bible' && q.options.length == 4 && q.answer != null), isTrue);
      expect(bank.factCount, greaterThanOrEqualTo(90));
      expect(Category.all.any((c) => c.id == 'bible'), isTrue);
    });
  });
}
