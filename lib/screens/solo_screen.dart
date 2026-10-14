import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_repository.dart';
import '../data/local_bank.dart';
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

enum _Phase { setup, play, done }

/// Solo modes. Both work offline; online they also pull fresh questions
/// from the shared bank.
enum SoloMode { quickFire, survival }

/// Endless question supply for one solo game. Local questions you haven't
/// seen come first; online questions are mixed in as they arrive. Nothing
/// repeats within a game unless every question has been used.
class QuestionFeed {
  QuestionFeed({required this.bank, required this.store, required this.repo, required this.categories});

  final LocalBank bank;
  final PlayerStore store;
  final GameRepository repo;
  final List<String> categories;

  final _queue = <Question>[];
  final _used = <String>{};
  bool _fetching = false;
  int _remoteMisses = 0;

  /// Starts loading online questions in the background.
  void prime() => _fetchRemote();

  Question? next() {
    if (_queue.length < 6) _fillLocal();
    if (_queue.length < 12) _fetchRemote();
    while (_queue.isNotEmpty) {
      final q = _queue.removeAt(0);
      final key = PlayerStore.stemKey(q.stem);
      if (_used.add(key)) {
        store.markQuestionSeen(q.stem, remoteId: q.id);
        return q;
      }
    }
    // Everything here was used this game: allow repeats rather than stop.
    if (_used.isEmpty) return null;
    _used.clear();
    return next();
  }

  void _fillLocal() {
    final batch = bank.drawFresh(30, store.seenQuestions, PlayerStore.stemKey, categories: categories);
    _queue.addAll(batch.where((q) => !_used.contains(PlayerStore.stemKey(q.stem))));
    // Seen every local question in these categories? Start a new cycle next time.
    if (bank.freshCount(store.seenQuestions, PlayerStore.stemKey, categories: categories) == 0) {
      store.resetSeenQuestions();
    }
  }

  Future<void> _fetchRemote() async {
    if (_fetching || _remoteMisses >= 2 || !repo.enabled) return;
    _fetching = true;
    final got = await repo.practiceQuestions(count: 30, categories: categories, exclude: store.recentRemoteIds);
    _fetching = false;
    final fresh = got.where((q) => !_used.contains(PlayerStore.stemKey(q.stem))).toList();
    if (fresh.isEmpty) {
      _remoteMisses++;
      return;
    }
    // Interleave so online and bundled questions alternate.
    final merged = <Question>[];
    final local = [..._queue];
    for (var i = 0; i < max(local.length, fresh.length); i++) {
      if (i < fresh.length) merged.add(fresh[i]);
      if (i < local.length) merged.add(local[i]);
    }
    _queue
      ..clear()
      ..addAll(merged);
  }
}

/// Quick Fire (60 s) and Survival (3 lives, the clock speeds up).
class SoloScreen extends ConsumerStatefulWidget {
  const SoloScreen({super.key});

  @override
  ConsumerState<SoloScreen> createState() => _SoloScreenState();
}

class _SoloScreenState extends ConsumerState<SoloScreen> {
  static const _total = Duration(seconds: 60);
  static const _lives = 3;

  _Phase _phase = _Phase.setup;
  SoloMode _mode = SoloMode.quickFire;
  String? _cat; // null = all
  late QuestionFeed _feed;
  Question? _q;
  int? _picked;
  bool _timedOut = false;
  Set<int> _hidden = {}; // options removed by 50/50
  bool _fiftyUsed = false;
  int _correct = 0, _answered = 0, _combo = 0, _bestCombo = 0, _score = 0, _livesLeft = _lives;
  DateTime? _endsAt; // Quick Fire: end of game. Survival: end of this question.
  Duration _qTime = const Duration(seconds: 12);
  Timer? _timer;
  int _lastTickSec = -1;
  bool _newBest = false;
  bool _finishing = false;
  int _xp = 0, _coins = 0;
  final _cardKey = GlobalKey();

  bool get _survival => _mode == SoloMode.survival;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    final store = ref.read(playerStoreProvider);
    _feed = QuestionFeed(
      bank: ref.read(localBankProvider),
      store: store,
      repo: ref.read(gameRepoProvider),
      categories: _cat == null ? const [] : [_cat!],
    )..prime();
    _correct = _answered = _combo = _bestCombo = _score = 0;
    _livesLeft = _lives;
    _fiftyUsed = false;
    _finishing = false;
    _newBest = false;
    _next();
    if (!_survival) _endsAt = DateTime.now().add(_total);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _onTick());
    Fx.play(Sfx.go);
    Fx.buzz(heavy: true);
    setState(() => _phase = _Phase.play);
  }

  void _onTick() {
    if (_phase != _Phase.play || _endsAt == null) return;
    final left = _endsAt!.difference(DateTime.now());
    final waiting = _picked == null && !_timedOut;
    if (waiting || !_survival) {
      final sec = (left.inMilliseconds / 1000).ceil();
      final warnFrom = _survival ? 3 : 5;
      if (sec != _lastTickSec && sec >= 1 && sec <= warnFrom) Fx.countdown();
      _lastTickSec = sec;
    }
    if (left.isNegative) {
      if (!_survival) {
        _finish();
        return;
      }
      if (waiting) _timeout();
    }
    if (mounted) setState(() {});
  }

  void _next() {
    _q = _feed.next();
    _picked = null;
    _timedOut = false;
    _hidden = {};
    _lastTickSec = -1;
    if (_survival) {
      // 12 s at the start, one second less every 5 correct, never under 6 s.
      _qTime = Duration(seconds: max(6, 12 - _correct ~/ 5));
      _endsAt = DateTime.now().add(_qTime);
    }
  }

  Future<void> _timeout() async {
    if (_q == null) return;
    setState(() {
      _timedOut = true;
      _answered++;
      _combo = 0;
      _livesLeft--;
    });
    Fx.wrong();
    await _afterAnswer(false);
  }

  Future<void> _answer(int i) async {
    if (_picked != null || _timedOut || _q == null || _phase != _Phase.play || _hidden.contains(i)) return;
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
        if (_survival) _livesLeft--;
      }
    });
    if (ok) {
      store.countCorrect(_q!.category);
      if (_combo == 3 || _combo == 5 || _combo == 10 || (_combo > 10 && _combo % 5 == 0)) {
        Fx.play(Sfx.streak);
        Fx.buzz(heavy: true);
      } else {
        Fx.correct();
      }
    } else {
      Fx.wrong();
    }
    await _afterAnswer(ok);
  }

  Future<void> _afterAnswer(bool ok) async {
    await Future.delayed(Duration(milliseconds: ok ? 420 : 950));
    if (!mounted || _phase != _Phase.play) return;
    if (_survival && _livesLeft <= 0) {
      _finish();
      return;
    }
    setState(_next);
  }

  void _fiftyFifty() {
    final q = _q;
    if (_fiftyUsed || q == null || q.answer == null || _picked != null || _timedOut) return;
    final wrong = [for (var i = 0; i < q.options.length; i++) if (i != q.answer) i]..shuffle();
    Fx.play(Sfx.pop);
    Fx.buzz();
    setState(() {
      _fiftyUsed = true;
      _hidden = wrong.take(2).toSet();
    });
  }

  Future<void> _finish() async {
    if (_phase != _Phase.play || _finishing) return;
    _finishing = true;
    _timer?.cancel();
    final store = ref.read(playerStoreProvider);
    _xp = _correct * 10 + 10;
    _coins = (_correct / 2).floor() + 5;
    _newBest = _survival ? await store.recordSurvival(_correct) : await store.recordQuickFire(_correct);
    await store.recordCombo(_bestCombo);
    await store.addReward(xp: _xp, coins: _coins, game: true);
    await store.markActive();
    _finishing = false;
    if (!mounted) return;
    setState(() => _phase = _Phase.done);
    if (_newBest) {
      Fx.celebrate();
    } else {
      Fx.reward();
    }
    await announceBadges(context, store);
  }

  void _share() {
    final mode = _survival ? 'Survival' : 'Quick Fire';
    final best = _newBest ? ' A new personal best!' : '';
    final text = 'I got $_correct right in Exam Duel $mode ($_score points, best combo ×$_bestCombo).$best 🦉 '
        'Can you beat me? Play free: $appLink';
    shareCard(context, _cardKey, text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBody(maxWidth: 760,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_phase) {
            _Phase.setup => KeyedSubtree(key: const ValueKey('s'), child: _setup(context)),
            _Phase.play => KeyedSubtree(
                key: const ValueKey('p'),
                child: AnswerKeys(onPick: _picked == null && !_timedOut ? _answer : null, child: _play(context)),
              ),
            _Phase.done => KeyedSubtree(key: const ValueKey('d'), child: _done(context)),
          },
        ),
      ),
    );
  }

  Widget _setup(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final best = _survival ? store.bestSurvival : store.bestQuickFire;
    return FillScroll(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          CircleIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
        ]),
        const Spacer(),
        Center(
          child: Eve(
            size: 160,
            iris: c.iris,
            mood: _survival ? EveMood.proud : EveMood.fire,
            outfit: store.outfit,
            motion: !store.reduceMotion,
            bob: true,
          ),
        ),
        const SizedBox(height: 18),
        Row(children: [
          _modeTile(c, SoloMode.quickFire, 'Quick Fire', '60 seconds', Icons.bolt_rounded, Pastel.sky),
          const SizedBox(width: 10),
          _modeTile(c, SoloMode.survival, 'Survival', '3 lives', Icons.favorite_rounded, Pastel.pink),
        ]),
        const SizedBox(height: 16),
        Text(
          _survival
              ? 'Three lives. The clock gets faster as you go. How far can you get?'
              : '60 seconds. As many as you can. Combos multiply your points.',
          style: T.body(16, color: c.muted),
        ),
        const SizedBox(height: 6),
        Text('One free 50/50 each game.', style: T.body(14, color: c.muted)),
        if (best > 0) ...[
          const SizedBox(height: 8),
          Text('Your best: $best correct', style: T.body(15, w: FontWeight.w700, color: c.ink)),
        ],
        const SizedBox(height: 18),
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

  Widget _modeTile(AppColors c, SoloMode mode, String title, String sub, IconData icon, Color bg) {
    final on = _mode == mode;
    return Expanded(
      child: Pressable(
        onTap: () => setState(() => _mode = mode),
        semanticLabel: '$title, $sub${on ? ', selected' : ''}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: on ? c.ink : Colors.transparent, width: 2.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(icon, color: Pastel.ink, size: 20),
              const Spacer(),
              if (on) const Icon(Icons.check_circle_rounded, color: Pastel.ink, size: 20),
            ]),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.disp(18, color: Pastel.ink)),
            Text(sub, style: T.body(12, w: FontWeight.w700, color: Pastel.ink)),
          ]),
        ),
      ),
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
    final span = _survival ? _qTime : _total;
    final leftMs = _endsAt == null ? 0 : _endsAt!.difference(DateTime.now()).inMilliseconds;
    final frozen = _survival && (_picked != null || _timedOut);
    final left = frozen ? 0.0 : (leftMs / span.inMilliseconds).clamp(0.0, 1.0);
    final q = _q;
    final revealed = _picked != null || _timedOut;
    final ok = _picked != null && q != null && _picked == q.answer;
    final mood = !revealed
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
                child: Text('×${_combo.clamp(1, 5)} combo', style: T.disp(15, color: Pastel.ink)),
              ),
            ),
          TimerRing(fraction: left, seconds: frozen ? 0 : (leftMs / 1000).ceil().clamp(0, span.inSeconds)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          if (_survival)
            Semantics(
              label: '$_livesLeft of $_lives lives left',
              excludeSemantics: true,
              child: Row(children: [
                for (var i = 0; i < _lives; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedScale(
                      scale: i < _livesLeft ? 1 : 0.7,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        i < _livesLeft ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: i < _livesLeft ? Pastel.coralDeep : c.muted,
                        size: 26,
                      ),
                    ),
                  ),
              ]),
            ),
          const Spacer(),
          Pressable(
            onTap: _fiftyUsed || revealed ? null : _fiftyFifty,
            sound: false,
            semanticLabel: _fiftyUsed ? '50/50 used' : 'Use 50/50: remove two wrong answers',
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _fiftyUsed ? Colors.transparent : Pastel.lime,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _fiftyUsed ? c.line : Colors.transparent, width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.call_split_rounded, size: 18, color: _fiftyUsed ? c.muted : Pastel.ink),
                const SizedBox(width: 6),
                Text('50/50', style: T.disp(15, color: _fiftyUsed ? c.muted : Pastel.ink)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 14),
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
                    if (_timedOut) ...[
                      const SizedBox(height: 10),
                      Text('Too slow! −1 life', style: T.body(14, w: FontWeight.w700, color: c.muted)),
                    ],
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
            AnimatedOpacity(
              opacity: _hidden.contains(i) ? 0.25 : 1,
              duration: const Duration(milliseconds: 250),
              child: _option(c, q, i, motion),
            ),
            const SizedBox(height: 10),
          ],
        const Spacer(),
        Text('$_correct correct · $_answered answered', textAlign: TextAlign.center, style: T.body(14, color: c.muted)),
      ]),
    );
  }

  Widget _option(AppColors c, Question q, int i, bool motion) {
    final revealed = _picked != null || _timedOut;
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
      onTap: revealed || _hidden.contains(i) ? null : () => _answer(i),
      scale: 0.95,
      sound: false,
      semanticLabel: 'Answer ${String.fromCharCode(65 + i)}: ${q.options[i]}',
      child: isPicked && !isAnswer ? Shake(trigger: '$_answered', enabled: motion, child: child) : child,
    );
  }

  Widget _done(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final motion = !store.reduceMotion;
    final title = _newBest ? 'New best!' : (_survival ? 'Out of lives!' : 'Time!');
    return Stack(children: [
      if (_newBest && motion) const Positioned.fill(child: ConfettiBurst()),
      FillScroll(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Spacer(),
          // Captured as an image when sharing the score.
          RepaintBoundary(
            key: _cardKey,
            child: Container(
              color: c.bg,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(
                  child: Eve(
                    size: 150,
                    iris: c.iris,
                    mood: _newBest ? EveMood.cheering : EveMood.proud,
                    outfit: store.outfit,
                    motion: motion,
                  ),
                ),
                const SizedBox(height: 12),
                Text(title, style: T.disp(44, color: c.ink), textAlign: TextAlign.center),
                Text(
                  '${_survival ? 'Survival' : 'Quick Fire'} · ${store.nickname}',
                  style: T.body(14, w: FontWeight.w600, color: c.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(children: [
                  _stat(c, 'Correct', _correct, Pastel.mint),
                  const SizedBox(width: 10),
                  _stat(c, 'Best combo', _bestCombo, Pastel.peach),
                  const SizedBox(width: 10),
                  _stat(c, 'Score', _score, Pastel.lav),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.accSoft, borderRadius: BorderRadius.circular(22)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              CountUp(value: _xp, prefix: '+', style: T.disp(24, color: c.ink)),
              Text(' XP', style: T.body(15, w: FontWeight.w600, color: c.muted)),
              const SizedBox(width: 22),
              const Icon(Icons.toll_rounded, color: Pastel.coin),
              const SizedBox(width: 4),
              CountUp(value: _coins, prefix: '+', style: T.disp(24, color: c.ink)),
            ]),
          ),
          const Spacer(),
          GoButton(label: 'Play again', icon: Icons.replay_rounded, onTap: _start),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: GhostButton(label: 'Share', icon: Icons.ios_share_rounded, onTap: _share)),
            const SizedBox(width: 10),
            Expanded(child: GhostButton(label: 'Home', onTap: () => Navigator.of(context).pop())),
          ]),
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
