import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/player_store.dart';
import '../services/fx.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/badges.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import '../widgets/eve/eve.dart';
import '../widgets/week_strip.dart';
import 'home_screen.dart';

/// Streak celebration after the daily fact.
class StreakScreen extends ConsumerStatefulWidget {
  const StreakScreen({super.key, required this.event});
  final StreakEvent event;

  @override
  ConsumerState<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends ConsumerState<StreakScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = ref.read(playerStoreProvider);
      tick(store.haptics, heavy: true);
      Fx.play(widget.event == StreakEvent.reset ? Sfx.pop : Sfx.streak);
      announceBadges(context, store);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final motion = !store.reduceMotion;
    final s = store.streak;
    final milestone = s == 7 || s == 30 || s == 100 || s == 365;
    final (title, line) = switch (widget.event) {
      StreakEvent.savedByFreeze => ('Saved!', 'A streak freeze kept your flame alive.'),
      StreakEvent.reset => ('Fresh start', 'New streak. Let’s build it back.'),
      StreakEvent.started => ('Day one!', 'Come back tomorrow to grow it.'),
      _ => (milestone ? '$s days!' : 'Streak +1', milestone ? 'Look how far you’ve come.' : 'Sharp. See you tomorrow.'),
    };
    return Scaffold(
      body: Stack(children: [
        if (motion && widget.event != StreakEvent.reset) const Positioned.fill(child: ConfettiBurst()),
        PageBody(
          maxWidth: 600,
          child: FillScroll(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Spacer(),
              PopIn(
                enabled: motion,
                child: Eve(
                  size: 200,
                  iris: c.iris,
                  mood: widget.event == StreakEvent.reset ? EveMood.proud : EveMood.fire,
                  outfit: store.outfit,
                  motion: motion,
                ),
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Icon(Icons.local_fire_department_rounded, color: Pastel.coral, size: 64),
                CountUp(value: s, style: T.num(110, color: c.ink), duration: Duration(milliseconds: motion ? 900 : 1)),
              ]),
              Text(title, style: T.disp(40, color: c.ink)),
              const SizedBox(height: 8),
              Text(line, style: T.body(17, color: c.muted), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              WeekStrip(activeDays: store.activeDays),
              const SizedBox(height: 18),
              Text(
                store.freezes == 0 ? 'Earn a streak freeze every 7 days.' : 'Streak freezes: ${store.freezes} of 2',
                style: T.body(14, color: c.muted),
              ),
              const Spacer(),
              GoButton(
                label: 'Let’s play',
                onTap: () => Navigator.of(context).pushReplacement(softRoute(const HomeScreen())),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
