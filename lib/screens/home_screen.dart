import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/eve/eve.dart';
import '../widgets/week_strip.dart';
import 'fact_screen.dart';
import 'host_setup_screen.dart';
import 'join_screen.dart';
import 'profile_screen.dart';
import 'solo_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Eve's gaze follows the finger anywhere on Home.
  Offset _look = Offset.zero;

  void _track(PointerEvent e) {
    final size = MediaQuery.sizeOf(context);
    // Eve sits top-right; aim relative to her rough position.
    final eve = Offset(size.width - 70, 300);
    final d = e.position - eve;
    setState(() => _look = Offset((d.dx / 160).clamp(-1.0, 1.0), (d.dy / 220).clamp(-1.0, 1.0)));
  }

  void _open(Widget page) => Navigator.of(context).push(softRoute(page));

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final motion = !store.reduceMotion;
    final atRisk = store.streakAtRisk;
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      body: Listener(
        onPointerDown: _track,
        onPointerMove: _track,
        onPointerUp: (_) => setState(() => _look = Offset.zero),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset('assets/icon/icon-512.png', width: 32, height: 32, semanticLabel: 'Exam Duel'),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('exam duel', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.disp(20, color: c.ink))),
                StatPill(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Pastel.coral,
                  value: '${store.streak}',
                  label: '${store.streak} day streak',
                ),
                const SizedBox(width: 8),
                StatPill(icon: Icons.toll_rounded, iconColor: Pastel.kGold, value: '${store.coins}', label: '${store.coins} coins'),
                const SizedBox(width: 8),
                Pressable(
                  onTap: () => _open(const ProfileScreen()),
                  semanticLabel: 'Your profile and settings',
                  child: Stack(clipBehavior: Clip.none, children: [
                    Avatar(initial: store.nickname.isEmpty ? '?' : store.nickname[0].toUpperCase(), index: store.avatar, size: 46),
                    Positioned(
                      right: -4,
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Pastel.lav, shape: BoxShape.circle, border: Border.all(color: c.bg, width: 2)),
                        child: Text('${store.level}', style: T.disp(10, color: Pastel.ink)),
                      ),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 22),
              Text('$greet, ${store.nickname}', style: T.body(15, color: c.muted)),
              const SizedBox(height: 6),
              Text('Ready to outsmart your friends?', style: T.disp(40, color: c.ink)),
              const SizedBox(height: 18),
              WeekStrip(activeDays: store.activeDays),
              const SizedBox(height: 46),
              _hero(c, store.outfit, motion, atRisk),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _tile(
                    c,
                    bg: Pastel.lime,
                    tag: 'Got a code?',
                    title: 'Join a\nroom',
                    icon: Icons.login_rounded,
                    onTap: () => _open(const JoinScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _tile(
                    c,
                    bg: Pastel.sky,
                    tag: store.bestQuickFire > 0 ? 'Best ${store.bestQuickFire}' : 'Solo · 60 s',
                    title: 'Quick\nFire',
                    icon: Icons.bolt_rounded,
                    onTap: () => _open(const SoloScreen()),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Pressable(
                onTap: () => _open(const FactScreen()),
                semanticLabel: 'Fact of the day',
                scale: 0.97,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Pastel.lav, borderRadius: BorderRadius.circular(28)),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Tag(store.factSeenToday ? 'Read today' : 'New today'),
                        const SizedBox(height: 10),
                        Text('Fact of the day', style: T.disp(22, color: Pastel.ink)),
                      ]),
                    ),
                    _goChip(),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              _levelCard(c, store.level, store.levelProgress, store.gamesPlayed, store.wins),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(AppColors c, String outfit, bool motion, bool atRisk) => Pressable(
        onTap: () => _open(const HostSetupScreen()),
        semanticLabel: 'Play with friends: host a room',
        scale: 0.97,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 190),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: c.acc, borderRadius: BorderRadius.circular(32)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Tag('2–12 players · live'),
              const SizedBox(height: 10),
              Text('Play with\nfriends', style: T.disp(46, color: Pastel.ink)),
              const SizedBox(height: 8),
              SizedBox(
                width: 190,
                child: Text(
                  atRisk ? 'Streak at risk… one quick round?' : 'Host a room. Share the code. Battle it out.',
                  style: T.body(14, w: FontWeight.w500, color: Pastel.ink, height: 1.3),
                ),
              ),
            ]),
          ),
          Positioned(
            right: -4,
            top: -46,
            child: IgnorePointer(
              child: Eve(
                size: 140,
                iris: c.iris,
                mood: atRisk ? EveMood.sleepy : EveMood.idle,
                lookX: _look.dx,
                lookY: _look.dy,
                outfit: outfit,
                motion: motion,
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(color: Pastel.ink, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ),
          ),
        ]),
      );

  Widget _goChip() => Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(color: Pastel.ink, shape: BoxShape.circle),
        child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
      );

  Widget _tile(AppColors c,
          {required Color bg, required String tag, required String title, required IconData icon, required VoidCallback onTap}) =>
      Pressable(
        onTap: onTap,
        semanticLabel: title.replaceAll('\n', ' '),
        child: Container(
          height: 158,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(28)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Tag(tag), const Spacer(), Icon(icon, color: Pastel.ink, size: 28)]),
            const Spacer(),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: Text(title, style: T.disp(22, color: Pastel.ink).copyWith(height: 1.05))),
              _goChip(),
            ]),
          ]),
        ),
      );

  Widget _levelCard(AppColors c, int level, double progress, int games, int wins) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(28)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('LEVEL $level', style: T.micro(color: c.muted)),
            const Spacer(),
            Text('$games games · $wins wins', style: T.body(13, color: c.muted)),
          ]),
          const SizedBox(height: 12),
          ProgressBar(value: progress, kente: true, height: 10),
          const SizedBox(height: 8),
          Text('${(progress * 500).round()} / 500 XP to level ${level + 1}', style: T.body(13, color: c.muted)),
        ]),
      );
}
