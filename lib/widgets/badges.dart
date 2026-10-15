import 'package:flutter/material.dart';

import '../data/achievements.dart';
import '../data/player_store.dart';
import '../services/fx.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'eve/eve.dart';

/// Celebrates a new level, then unlocks and announces any new badges.
/// Call after a game, a fact or a profile change.
Future<void> announceBadges(BuildContext context, PlayerStore store) async {
  final level = await store.takeLevelUp();
  if (level != null && context.mounted) {
    await _celebrateLevel(context, store, level);
  }
  if (!context.mounted) return;
  final fresh = await store.checkBadges();
  if (fresh.isEmpty || !context.mounted) return;
  Fx.play(Sfx.badge);
  Fx.buzz(heavy: true);
  final names = fresh.map((a) => a.name).join(', ');
  showToast(context, fresh.length == 1 ? 'Badge unlocked: $names · +20 coins' : 'Badges unlocked: $names · +${20 * fresh.length} coins');
}

/// A short, skippable "you reached level N" sheet.
Future<void> _celebrateLevel(BuildContext context, PlayerStore store, int level) async {
  final c = context.c;
  Fx.play(Sfx.win);
  Fx.buzz(heavy: true);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: PopIn(
              enabled: !store.reduceMotion,
              child: Eve(
                size: 150,
                iris: c.iris,
                mood: EveMood.cheering,
                outfit: store.outfit,
                motion: !store.reduceMotion,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text('LEVEL UP', style: T.micro(color: c.muted))),
          const SizedBox(height: 6),
          Center(child: Text('Level $level', style: T.disp(44, color: c.ink))),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Eve is impressed. ${500 - store.xp % 500} XP to level ${level + 1}.',
              textAlign: TextAlign.center,
              style: T.body(15, color: c.muted),
            ),
          ),
          const SizedBox(height: 18),
          ProgressBar(value: store.levelProgress, striped: true, height: 10),
          const SizedBox(height: 18),
          GoButton(label: 'Nice', icon: Icons.check_rounded, onTap: () => Navigator.pop(ctx)),
        ]),
      ),
    ),
  );
}

/// The Profile badge shelf: unlocked badges in colour, locked ones faded.
class BadgeShelf extends StatelessWidget {
  const BadgeShelf({super.key, required this.store});
  final PlayerStore store;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final have = store.badges;
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth >= 640 ? 5 : (box.maxWidth >= 420 ? 4 : 3);
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
        children: [
          for (final a in Achievement.all)
            Tooltip(
              message: '${a.name}: ${a.goal}',
              triggerMode: TooltipTriggerMode.tap,
              child: Semantics(
                label: '${a.name}, ${a.goal}, ${have.contains(a.id) ? 'unlocked' : 'locked'}',
                excludeSemantics: true,
                child: _tile(c, a, have.contains(a.id)),
              ),
            ),
        ],
      );
    });
  }

  Widget _tile(AppColors c, Achievement a, bool on) => Container(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        decoration: BoxDecoration(
          color: on ? Pastel.all[a.colorIndex] : c.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: on ? Colors.transparent : c.line, width: 1.5),
        ),
        child: Column(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: on ? Pastel.ink : c.surface2, shape: BoxShape.circle),
            child: Icon(on ? a.icon : Icons.lock_rounded, color: on ? Colors.white : c.muted, size: 22),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              a.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: T.body(12, w: FontWeight.w700, color: on ? Pastel.ink : c.muted, height: 1.15),
            ),
          ),
        ]),
      );
}
