import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/eve/eve.dart';

enum _Phase { setup, play, done }

/// Quick Fire: answer as many as you can in 60 seconds. Works offline.
class SoloScreen extends ConsumerStatefulWidget {
  const SoloScreen({super.key});

  @override
  ConsumerState<SoloScreen> createState() => _SoloScreenState();
}

class _SoloScreenState extends ConsumerState<SoloScreen> {
  static const _total = Duration(seconds: 60);

  _Phase _phase = _Phase.setup;
  String? _cat; // null = all
  late Iterator<Question> _stream;
  Question? _q;
  int? _picked;
  int _correct = 0, _answered = 0, _combo = 0, _bestCombo = 0, _score = 0;
  DateTime? _endsAt;
  Timer? _timer;
  bool _newBest = false;
  bool _finishing = false;
  int _xp = 0, _coins = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    final bank = ref.read(localBankProvider);
    _stream = bank.endless(categories: _cat == null ? const [] : [_cat!]).iterator;
    _correct = _answered = _combo = _bestCombo = _score = 0;
    _picked = null;
    _next();
    _endsAt = DateTime.now().add(_total);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (DateTime.now().isAfter(_endsAt!)) {
        _finish();
      } else {
        setState(() {});
      }
    });
    setState(() => _phase = _Phase.play);
  }

  void _next() {
    _q = _stream.moveNext() ? _stream.current : null;
    _picked = null;
  }

  Future<void> _answer(int i) async {
    if (_picked != null || _q == null || _phase != _Phase.play) return;
    final store = ref.read(playerStoreProvider);
    final ok = i == _q!.answer;
    setState(() {
      _picked = i;
      _answered++;
      if (ok) {
        _correct++;
        _combo++;
        if (_combo > _bestCombo) _bestCombo = _combo;
        _score += 100 * (1 + (_combo - 1).clamp(0, 4));
      } else {
        _combo = 0;
      }
    });
    tick(store.haptics, heavy: ok);
    await Future.delayed(Duration(milliseconds: ok ? 420 : 900));
    if (!mounted || _phase != _Phase.play) return;
    setState(_next);
  }

  Future<void> _finish() async {
    if (_phase != _Phase.play || _finishing) return;
    _finishing = true;
    _timer?.cancel();
    final store = ref.read(playerStoreProvider);
    _xp = _correct * 10 + 10;
    _coins = (_correct / 2).floor() + 5;
    _newBest = await store.recordQuickFire(_correct);
    await store.addReward(xp: _xp, coins: _coins, game: true);
    await store.markActive();
    _finishing = false;
    if (mounted) setState(() => _phase = _Phase.done);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_phase) {
            _Phase.setup => KeyedSubtree(key: const ValueKey('s'), child: _setup(context)),
            _Phase.play => KeyedSubtree(key: const ValueKey('p'), child: _play(context)),
            _Phase.done => KeyedSubtree(key: const ValueKey('d'), child: _done(context)),
          },
        ),
      ),
    );
  }

  Widget _setup(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    return FillScroll(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          CircleIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
        ]),
        const Spacer(),
        Center(child: Eve(size: 170, iris: c.iris, mood: EveMood.fire, outfit: store.outfit, motion: !store.reduceMotion, bob: true)),
        const SizedBox(height: 20),
        Text('Quick Fire', style: T.disp(46, color: c.ink)),
        const SizedBox(height: 8),
        Text('60 seconds. As many as you can. Combos multiply your points.', style: T.body(16, color: c.muted)),
        if (store.bestQuickFire > 0) ...[
          const SizedBox(height: 8),
          Text('Your best: ${store.bestQuickFire} correct', style: T.body(15, w: FontWeight.w700, color: c.ink)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            _catChip(c, null, 'All mixed'),
            for (final cat in Category.all) _catChip(c, cat.id, cat.name),
          ]),
        ),
        const Spacer(),
        GoButton(label: 'Start', onTap: _start),
      ]),
    );
  }

  Widget _catChip(AppColors c, String? id, String label) {
    final on = _cat == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: () => setState(() => _cat = id),
        semanticLabel: '$label${on ? ', selected' : ''}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? c.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? c.primary : c.line, width: 1.5),
          ),
          child: Text(label, style: T.body(15, w: FontWeight.w600, color: on ? c.onPrimary : c.ink)),
        ),
      ),
    );
  }

  Widget _play(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final motion = !store.reduceMotion;
    final left = _endsAt == null ? 0.0 : _endsAt!.difference(DateTime.now()).inMilliseconds / _total.inMilliseconds;
    final q = _q;
    final ok = _picked != null && q != null && _picked == q.answer;
    final mood = _picked == null
        ? (_combo >= 3 ? EveMood.fire : EveMood.thinking)
        : ok
            ? (_combo >= 3 ? EveMood.fire : EveMood.happy)
            : EveMood.oops;

    return FillScroll(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          CircleIconButton(icon: Icons.close_rounded, label: 'Stop', onTap: _finish),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SCORE', style: T.micro(color: c.muted)),
              Text('$_score', style: T.num(40, color: c.ink)),
            ]),
          ),
          if (_combo >= 2)
            PopIn(
              key: ValueKey(_combo),
              enabled: motion,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Pastel.coral, borderRadius: BorderRadius.circular(999)),
                child: Text('×${(_combo).clamp(1, 5)} combo', style: T.disp(15, color: Pastel.ink)),
              ),
            ),
          TimerRing(fraction: left.clamp(0.0, 1.0), seconds: (left * 60).ceil().clamp(0, 60)),
        ]),
        const SizedBox(height: 16),
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 160),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(28)),
            child: q == null
                ? Text('No questions here yet.', style: T.disp(22, color: c.ink))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Tag(Category.byId(q.category).name, color: Pastel.all[Category.byId(q.category).colorIndex]),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(right: 60),
                      child: Text(q.stem, style: T.disp(24, color: c.ink).copyWith(height: 1.15)),
                    ),
                  ]),
          ),
          Positioned(
            right: -6,
            top: -20,
            child: Eve(size: 80, iris: c.iris, mood: mood, outfit: store.outfit, motion: motion, sparkle: ok, glow: _combo >= 3),
          ),
        ]),
        const SizedBox(height: 14),
        if (q != null)
          for (var i = 0; i < q.options.length; i++) ...[
            _option(c, q, i, motion),
            const SizedBox(height: 10),
          ],
        const Spacer(),
        Text('$_correct correct · $_answered answered', textAlign: TextAlign.center, style: T.body(14, color: c.muted)),
      ]),
    );
  }

  Widget _option(AppColors c, Question q, int i, bool motion) {
    final revealed = _picked != null;
    final isAnswer = q.answer == i;
    final isPicked = _picked == i;
    final bg = !revealed
        ? c.surface
        : isAnswer
            ? Pastel.okBg
            : isPicked
                ? Pastel.badBg
                : Colors.transparent;
    final fg = revealed && (isAnswer || isPicked) ? Pastel.ink : c.ink;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: revealed && !isAnswer && !isPicked ? c.line : Colors.transparent, width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: revealed && isAnswer ? Pastel.ink : c.surface2, shape: BoxShape.circle),
          child: Text(String.fromCharCode(65 + i), style: T.disp(16, color: revealed && isAnswer ? Colors.white : c.ink)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(q.options[i], style: T.body(16, w: FontWeight.w600, color: fg, height: 1.25))),
        if (revealed && isAnswer) const Icon(Icons.check_rounded, color: Pastel.ink),
        if (revealed && isPicked && !isAnswer) const Icon(Icons.close_rounded, color: Pastel.ink),
      ]),
    );
    return Pressable(
      onTap: revealed ? null : () => _answer(i),
      scale: 0.95,
      semanticLabel: 'Answer ${String.fromCharCode(65 + i)}: ${q.options[i]}',
      child: isPicked && !isAnswer ? Shake(trigger: '$_answered', enabled: motion, child: child) : child,
    );
  }

  Widget _done(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final motion = !store.reduceMotion;
    return Stack(children: [
      if (_newBest && motion) const Positioned.fill(child: ConfettiBurst()),
      FillScroll(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Spacer(),
          Center(child: Eve(size: 170, iris: c.iris, mood: _newBest ? EveMood.cheering : EveMood.proud, outfit: store.outfit, motion: motion)),
          const SizedBox(height: 16),
          Text(_newBest ? 'New best!' : 'Time!', style: T.disp(46, color: c.ink), textAlign: TextAlign.center),
          const SizedBox(height: 18),
          Row(children: [
            _stat(c, 'Correct', _correct, Pastel.mint),
            const SizedBox(width: 10),
            _stat(c, 'Best combo', _bestCombo, Pastel.peach),
            const SizedBox(width: 10),
            _stat(c, 'Score', _score, Pastel.lav),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.accSoft, borderRadius: BorderRadius.circular(22)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              CountUp(value: _xp, prefix: '+', style: T.disp(24, color: c.ink)),
              Text(' XP', style: T.body(15, w: FontWeight.w600, color: c.muted)),
              const SizedBox(width: 22),
              const Icon(Icons.toll_rounded, color: Pastel.kGold),
              const SizedBox(width: 4),
              CountUp(value: _coins, prefix: '+', style: T.disp(24, color: c.ink)),
            ]),
          ),
          const Spacer(),
          GoButton(label: 'Play again', icon: Icons.replay_rounded, onTap: _start),
          const SizedBox(height: 10),
          GhostButton(label: 'Home', onTap: () => Navigator.of(context).pop()),
        ]),
      ),
    ]);
  }

  Widget _stat(AppColors c, String label, int value, Color bg) => Expanded(
        child: Container(
          height: 96,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: T.body(12, w: FontWeight.w700, color: Pastel.ink)),
            CountUp(value: value, style: T.num(34, color: Pastel.ink)),
          ]),
        ),
      );
}
