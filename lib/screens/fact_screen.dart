import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/player_store.dart';
import '../services/fx.dart';
import '../services/share.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/badges.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import '../widgets/eve/eve.dart';
import 'home_screen.dart';
import 'streak_screen.dart';

/// Fact of the Day: tap the card to flip it. Reading it keeps the streak.
class FactScreen extends ConsumerStatefulWidget {
  const FactScreen({super.key, this.firstOpen = false});
  final bool firstOpen;

  @override
  ConsumerState<FactScreen> createState() => _FactScreenState();
}

class _FactScreenState extends ConsumerState<FactScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  final _rng = math.Random();
  bool _flipped = false;
  String? _reaction;
  String? _cheer; // Eve's line after a reaction
  String? _float; // "+5 XP" rising from the buttons
  int? _factIdx;
  bool _bonus = false; // showing an extra fact, not today's

  static const _knewLines = [
    'Big brain! You knew it.',
    'Look at you, walking encyclopedia!',
    'Sharp! Eve is impressed.',
    'Of course you knew. Genius move.',
    'Nothing gets past you!',
  ];
  static const _blownLines = [
    'Right?! Eve’s mind is blown too.',
    'Now drop that one at dinner tonight.',
    'Share it and blow someone else’s mind!',
    'That’s why we read facts. Brain +1!',
    'Hoo-hoo! Learned something new.',
  ];

  @override
  void initState() {
    super.initState();
    if (!widget.firstOpen) {
      _flipped = true;
      _flip.value = 1;
    }
  }

  Fact _fact() {
    final bank = ref.read(localBankProvider);
    _factIdx ??= ref.read(playerStoreProvider).dailyFactIndex(bank.factCount);
    return bank.factAt(_factIdx!);
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _doFlip() {
    if (_flipped) return;
    final store = ref.read(playerStoreProvider);
    tick(store.haptics);
    Fx.play(Sfx.whoosh);
    setState(() => _flipped = true);
    if (store.reduceMotion) {
      _flip.value = 1;
    } else {
      _flip.forward();
    }
  }

  Future<void> _continue() async {
    final store = ref.read(playerStoreProvider);
    await store.markFactSeen();
    final event = await store.markActive();
    if (!mounted) return;
    await announceBadges(context, store);
    if (!mounted) return;
    if (!widget.firstOpen) {
      Navigator.of(context).pop();
      return;
    }
    final Widget next = switch (event) {
      StreakEvent.started || StreakEvent.extended || StreakEvent.savedByFreeze || StreakEvent.reset =>
        StreakScreen(event: event),
      StreakEvent.none => const HomeScreen(),
    };
    Navigator.of(context).pushReplacement(softRoute(next));
  }

  void _share(String text) =>
      shareText(context, 'Did you know? $text\n\n— Fact of the Day from Eve the owl, Exam Duel. Get yours: $appLink');

  Future<void> _react(String id) async {
    final store = ref.read(playerStoreProvider);
    final lines = id == 'knew' ? _knewLines : _blownLines;
    setState(() {
      _reaction = id;
      _cheer = lines[_rng.nextInt(lines.length)];
    });
    final rewarded = await store.rewardFactReaction();
    if (!mounted) return;
    if (rewarded) {
      Fx.reward();
      setState(() => _float = '+5 XP');
      showToast(context, id == 'knew' ? 'Brainy! +5 XP for today’s fact.' : 'Learning pays! +5 XP for today’s fact.');
    } else {
      Fx.play(Sfx.pop);
      Fx.buzz();
    }
  }

  /// Shows one more fact (they keep reading, Eve keeps cheering).
  Future<void> _another() async {
    final store = ref.read(playerStoreProvider);
    final idx = await store.bonusFactIndex(ref.read(localBankProvider).factCount);
    if (!mounted) return;
    Fx.play(Sfx.whoosh);
    setState(() {
      _factIdx = idx;
      _bonus = true;
      _reaction = null;
      _cheer = null;
      _float = null;
    });
    if (!store.reduceMotion) _flip.forward(from: 0.5);
    await announceBadges(context, store);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final fact = _fact();
    final motion = !store.reduceMotion;
    final mood = !_flipped
        ? EveMood.idle
        : _reaction == 'blown'
            ? EveMood.cheering
            : _reaction == 'knew'
                ? EveMood.proud
                : EveMood.surprised;

    return Scaffold(
      body: PageBody(maxWidth: 680,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              if (!widget.firstOpen)
                CircleIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
              const Spacer(),
              Text(_bonus ? 'BONUS FACT' : 'FACT OF THE DAY', style: T.micro(color: c.muted)),
              const Spacer(),
              if (!widget.firstOpen) const SizedBox(width: 48),
            ]),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Bubble(!_flipped
                      ? 'Tap the card. Go on.'
                      : _cheer ?? (_bonus ? 'Ooh, here’s another one!' : 'Wait… you HAVE to see this.')),
                ),
              ),
              Eve(size: 120, iris: c.iris, mood: mood, outfit: store.outfit, motion: motion, sparkle: _reaction == 'blown'),
            ]),
            const SizedBox(height: 8),
            Expanded(
              child: GestureDetector(
                onTap: _doFlip,
                child: AnimatedBuilder(
                  animation: _flip,
                  builder: (_, __) {
                    final t = Curves.easeOutBack.transform(_flip.value).clamp(0.0, 1.2);
                    final angle = t * math.pi;
                    final showBack = angle > math.pi / 2;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(angle),
                      child: showBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _back(c, fact.text, fact.category),
                            )
                          : _front(c),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: _flipped ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_flipped,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                    Row(children: [
                      _reactButton(c, 'knew', 'Knew it', Icons.check_rounded, Pastel.mint),
                      const SizedBox(width: 10),
                      _reactButton(c, 'blown', 'Mind blown', Icons.auto_awesome_rounded, Pastel.peach),
                    ]),
                    if (_float != null && motion) Positioned(top: -30, child: IgnorePointer(child: FloatUp(text: _float!))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    CircleIconButton(icon: Icons.share_rounded, label: 'Share this fact', onTap: () => _share(fact.text)),
                    const SizedBox(width: 10),
                    CircleIconButton(icon: Icons.casino_rounded, label: 'Another fact', onTap: _another),
                    const SizedBox(width: 10),
                    Expanded(child: GoButton(label: widget.firstOpen ? 'Keep streak' : 'Done', onTap: _continue)),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _front(AppColors c) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: Pastel.lav, borderRadius: BorderRadius.circular(32)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Tag('Did you know?'),
          const Spacer(),
          Text('Today’s fact is\nwaiting.', style: T.disp(40, color: Pastel.ink)),
          const SizedBox(height: 12),
          Row(children: [
            Text('Tap to reveal', style: T.body(16, w: FontWeight.w600, color: Pastel.ink)),
            const SizedBox(width: 6),
            const Icon(Icons.touch_app_rounded, color: Pastel.ink, size: 20),
          ]),
        ]),
      );

  Widget _back(AppColors c, String text, String category) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(32)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Tag(category[0].toUpperCase() + category.substring(1), color: c.accSoft, dark: true),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(child: Text(text, style: T.disp(30, color: c.ink, w: FontWeight.w600).copyWith(height: 1.15))),
          ),
        ]),
      );

  Widget _reactButton(AppColors c, String id, String label, IconData icon, Color bg) => Expanded(
        child: Pressable(
          onTap: () => _react(id),
          sound: false,
          semanticLabel: label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 64,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _reaction == id ? c.ink : Colors.transparent, width: 2.5),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: Pastel.ink, size: 20),
              const SizedBox(width: 8),
              Text(label, style: T.disp(17, color: Pastel.ink)),
            ]),
          ),
        ),
      );
}
