import 'package:flutter/material.dart';

import 'player_store.dart';

/// A badge on the Profile shelf. Unlocking one pays 20 coins.
class Achievement {
  final String id;
  final String name;
  final String goal;
  final IconData icon;
  final int colorIndex; // index into Pastel.all
  final bool Function(PlayerStore s) done;
  const Achievement(this.id, this.name, this.goal, this.icon, this.colorIndex, this.done);

  static final all = <Achievement>[
    Achievement('first_game', 'First steps', 'Finish any game', Icons.flag_rounded, 2, (s) => s.gamesPlayed >= 1),
    Achievement('first_win', 'Champion', 'Win an online room', Icons.emoji_events_rounded, 0, (s) => s.wins >= 1),
    Achievement('streak_3', 'Warming up', 'Keep a 3-day streak', Icons.local_fire_department_rounded, 4, (s) => s.longestStreak >= 3),
    Achievement('streak_7', 'On fire', 'Keep a 7-day streak', Icons.whatshot_rounded, 0, (s) => s.longestStreak >= 7),
    Achievement('streak_30', 'Unstoppable', 'Keep a 30-day streak', Icons.bolt_rounded, 5, (s) => s.longestStreak >= 30),
    Achievement('combo_5', 'Combo king', 'Get 5 right in a row', Icons.flash_on_rounded, 6, (s) => s.bestCombo >= 5),
    Achievement('combo_10', 'Mind reader', 'Get 10 right in a row', Icons.psychology_rounded, 1, (s) => s.bestCombo >= 10),
    Achievement('quickfire_20', 'Speed demon', 'Score 20 in Quick Fire', Icons.speed_rounded, 3, (s) => s.bestQuickFire >= 20),
    Achievement('survival_15', 'Survivor', 'Reach 15 in Survival', Icons.favorite_rounded, 4, (s) => s.bestSurvival >= 15),
    Achievement('century', 'Century', '100 correct answers', Icons.military_tech_rounded, 7, (s) => s.totalCorrect >= 100),
    Achievement('bible_10', 'Bible scholar', '10 Bible questions right', Icons.menu_book_rounded, 2, (s) => s.bibleCorrect >= 10),
    Achievement('facts_10', 'Curious owl', 'Read 10 facts', Icons.lightbulb_rounded, 5, (s) => s.factsRead >= 10),
    Achievement('photo', 'Say cheese', 'Add a profile photo', Icons.photo_camera_rounded, 3, (s) => s.hasPhoto),
    Achievement('level_5', 'Rising star', 'Reach level 5', Icons.star_rounded, 6, (s) => s.level >= 5),
    Achievement('wardrobe', 'Fashion owl', 'Own 3 outfits for Eve', Icons.checkroom_rounded, 1, (s) => s.ownedOutfits.length >= 4),
  ];
}
