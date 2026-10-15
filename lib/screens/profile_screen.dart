import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/achievements.dart';
import '../data/player_store.dart';
import '../services/photo_picker.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/badges.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import '../widgets/eve/eve.dart';

/// Icon and pastel colour for each outfit, so the wardrobe reads at a glance.
const _wardrobe = <String, (IconData, int)>{
  'none': (Icons.not_interested_rounded, 6),
  'glasses': (Icons.visibility_rounded, 7),
  'scarf': (Icons.waves_rounded, 4),
  'headphones': (Icons.headphones_rounded, 1),
  'cap': (Icons.school_rounded, 5),
  'jersey': (Icons.sports_soccer_rounded, 0),
  'tie': (Icons.work_rounded, 3),
};

/// Profile, stats, Eve's wardrobe and settings on one scrolling page.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _preview; // outfit being previewed

  Future<void> _editName(PlayerStore store) async {
    final c = context.c;
    final ctrl = TextEditingController(text: store.nickname);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Your nickname', style: T.disp(24, color: c.ink)),
        content: TextField(controller: ctrl, autofocus: true, maxLength: 20, style: T.body(17, color: c.ink)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: T.body(15, color: c.muted))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Save', style: T.body(15, w: FontWeight.w700, color: c.ink)),
          ),
        ],
      ),
    );
    // Controller is left to GC: disposing while the dialog animates out can throw.
    if (name != null && name.isNotEmpty) await store.setProfile(name, store.avatar);
  }

  Future<void> _tapOutfit(PlayerStore store, Outfit o) async {
    final owned = store.ownedOutfits.contains(o.id);
    if (owned) {
      await store.wearOutfit(o.id);
      if (mounted) setState(() => _preview = null);
      return;
    }
    if (_preview != o.id) {
      setState(() => _preview = o.id);
      return;
    }
    final ok = await store.buyOutfit(o);
    if (!mounted) return;
    if (ok) {
      tick(store.haptics, heavy: true);
      setState(() => _preview = null);
      showToast(context, 'Eve loves her ${o.name.toLowerCase()}!');
      await announceBadges(context, store);
    } else {
      showToast(context, 'You need ${o.price - store.coins} more coins. Play a round!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final motion = !store.reduceMotion;
    final showing = _preview ?? store.outfit;

    return Scaffold(
      body: PageBody(maxWidth: 860,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(children: [
              CircleIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
              const Spacer(),
              StatPill(icon: Icons.toll_rounded, iconColor: Pastel.coin, value: '${store.coins}', label: '${store.coins} coins'),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Pressable(
                onTap: () => editPhoto(context, store),
                semanticLabel: store.hasPhoto ? 'Change profile photo' : 'Add a profile photo',
                child: Stack(clipBehavior: Clip.none, children: [
                  Avatar(
                    initial: store.nickname.isEmpty ? '?' : store.nickname[0].toUpperCase(),
                    index: store.avatar,
                    size: 72,
                    photo: store.photo,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle, border: Border.all(color: c.bg, width: 2)),
                      child: Icon(Icons.photo_camera_rounded, size: 14, color: c.onPrimary),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(store.nickname, style: T.disp(32, color: c.ink)),
                  const SizedBox(height: 4),
                  Text('Level ${store.level} · ${store.xp} XP', style: T.body(15, color: c.muted)),
                ]),
              ),
              CircleIconButton(icon: Icons.edit_rounded, label: 'Edit nickname', onTap: () => _editName(store)),
            ]),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (var i = 0; i < Pastel.all.length; i++)
                Pressable(
                  onTap: () => store.setProfile(store.nickname, i),
                  semanticLabel: 'Avatar colour ${i + 1}',
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Pastel.all[i],
                      shape: BoxShape.circle,
                      border: Border.all(color: i == store.avatar ? c.ink : Colors.transparent, width: 2.5),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              _stat(c, '${store.streak}', 'Day streak', Pastel.peach),
              const SizedBox(width: 10),
              _stat(c, '${store.longestStreak}', 'Longest', Pastel.pink),
              const SizedBox(width: 10),
              _stat(c, '${store.wins}', 'Wins', Pastel.mint),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _stat(c, '${store.gamesPlayed}', 'Games', Pastel.sky),
              const SizedBox(width: 10),
              _stat(c, '${store.bestQuickFire}', 'Quick Fire best', Pastel.lime),
              const SizedBox(width: 10),
              _stat(c, '${store.freezes}', 'Streak freezes', Pastel.lav),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _stat(c, '${store.bestSurvival}', 'Survival best', Pastel.coral),
              const SizedBox(width: 10),
              _stat(c, '${store.bestCombo}', 'Best combo', Pastel.aqua),
              const SizedBox(width: 10),
              _stat(c, '${store.factsRead}', 'Facts read', Pastel.peach),
            ]),
            const SizedBox(height: 28),
            Row(children: [
              Text('BADGES', style: T.micro(color: c.muted)),
              const Spacer(),
              Text('${store.badges.length} of ${Achievement.all.length} · tap one to see its goal', style: T.body(12, color: c.muted)),
            ]),
            const SizedBox(height: 12),
            BadgeShelf(store: store),
            const SizedBox(height: 28),
            Text('EVE’S WARDROBE', style: T.micro(color: c.muted)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.acc, borderRadius: BorderRadius.circular(32)),
              child: Column(children: [
                Eve(size: 170, iris: c.iris, mood: _preview != null ? EveMood.surprised : EveMood.happy, outfit: showing, motion: motion, bob: true),
                if (_preview != null) ...[
                  const SizedBox(height: 6),
                  Text('Tap again to buy', style: T.body(14, w: FontWeight.w700, color: Pastel.ink)),
                ],
              ]),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: isWide(context) ? 4 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.80,
              children: [for (final o in Outfit.all) _outfitTile(c, store, o)],
            ),
            const SizedBox(height: 28),
            Text('SETTINGS', style: T.micro(color: c.muted)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(28)),
              child: Column(children: [
                _toggle(c, 'Dark mode', store.dark, store.setDark),
                Divider(color: c.line, height: 1),
                _toggle(c, 'Reduce motion', store.reduceMotion, store.setReduceMotion),
                Divider(color: c.line, height: 1),
                _toggle(c, 'Sound effects', store.sound, store.setSound),
                Divider(color: c.line, height: 1),
                _toggle(c, 'Haptics', store.haptics, store.setHaptics),
                Divider(color: c.line, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(children: [
                    Expanded(child: Text('Eve’s eyes', style: T.body(16, w: FontWeight.w600, color: c.ink))),
                    for (final a in AccentChoice.values)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Pressable(
                          onTap: () => store.setAccent(a),
                          semanticLabel: '${a.name}${a.id == store.accent.id ? ', selected' : ''}',
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: a.iris,
                              shape: BoxShape.circle,
                              border: Border.all(color: a.id == store.accent.id ? c.ink : Colors.transparent, width: 3),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Text(
              'Extra questions come from the Open Trivia Database (opentdb.com), shared under CC BY-SA 4.0.',
              style: T.body(12, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(AppColors c, String value, String label, Color bg) => Expanded(
        child: Container(
          height: 88,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(value, style: T.num(32, color: Pastel.ink)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body(12, w: FontWeight.w700, color: Pastel.ink)),
          ]),
        ),
      );

  Widget _outfitTile(AppColors c, PlayerStore store, Outfit o) {
    final owned = store.ownedOutfits.contains(o.id);
    final wearing = store.outfit == o.id;
    final previewing = _preview == o.id;
    final look = _wardrobe[o.id] ?? (Icons.checkroom_rounded, 1);
    final ring = wearing || previewing;
    final fg = owned ? Pastel.ink : c.ink;
    return Pressable(
      onTap: () => _tapOutfit(store, o),
      semanticLabel: '${o.name}, ${wearing ? 'wearing' : owned ? 'owned, tap to wear' : '${o.price} coins'}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: owned ? Pastel.all[look.$2] : c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: ring ? c.ink : (owned ? Colors.transparent : c.line),
            width: ring ? 2.5 : 1.5,
          ),
        ),
        child: Stack(children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DotPattern(owned ? Pastel.ink.withValues(alpha: 0.09) : c.line.withValues(alpha: 0.5)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            child: Column(children: [
              Stack(clipBehavior: Clip.none, children: [
                AnimatedScale(
                  scale: ring ? 1.08 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: owned ? Colors.white.withValues(alpha: 0.75) : c.surface2,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(look.$1, size: 23, color: fg),
                  ),
                ),
                if (wearing)
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Pastel.ink,
                        shape: BoxShape.circle,
                        border: Border.all(color: Pastel.all[look.$2], width: 2),
                      ),
                      child: const Icon(Icons.check_rounded, size: 11, color: Colors.white),
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  o.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: T.body(12, w: FontWeight.w700, color: fg, height: 1.15),
                ),
              ),
              if (wearing)
                Text('Wearing', style: T.body(11, w: FontWeight.w700, color: fg))
              else if (owned)
                Text('Tap to wear', style: T.body(11, w: FontWeight.w600, color: fg))
              else
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.toll_rounded, color: Pastel.coin, size: 13),
                  const SizedBox(width: 3),
                  Text('${o.price}', style: T.disp(13, color: c.ink)),
                ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _toggle(AppColors c, String label, bool value, Future<void> Function(bool) onChanged) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: T.body(16, w: FontWeight.w600, color: c.ink))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: c.onPrimary,
            activeTrackColor: c.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: c.surface2,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ]),
      );
}

/// Faint dots behind each wardrobe tile, so the shelf has a little texture.
class _DotPattern extends CustomPainter {
  const _DotPattern(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 15.0;
    var row = 0;
    for (var y = 7.0; y < size.height; y += step) {
      final offset = row.isEven ? 0.0 : step / 2;
      for (var x = 7.0 + offset; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.7, paint);
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(_DotPattern old) => old.color != color;
}
