import 'package:flutter/material.dart';

import 'app_theme.dart';

/// How well a topic is known, from never practised to ready for the test.
enum Mastery { unseen, shaky, solid, ready }

extension MasteryLook on Mastery {
  String get label => const ['New', 'Shaky', 'Solid', 'Ready'][index];

  Color fill(AppColors c) => switch (this) {
        Mastery.unseen => c.surface2,
        Mastery.shaky => Pastel.peach,
        Mastery.solid => Pastel.mint,
        Mastery.ready => Pastel.gold,
      };

  Color ink(AppColors c) => this == Mastery.unseen ? c.ink : Pastel.ink;

  /// 0–4 filled pips shown on a tile.
  int get pips => const [0, 2, 3, 4][index];

  String get emoji => const ['⬜', '🟧', '🟩', '🟨'][index];
}
