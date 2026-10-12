import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/eve/eve.dart';
import '../widgets/responsive.dart';
import 'proto_data.dart';
import 'proto_kit.dart';
import 'results_screen.dart';

/// Step 3: the duel. Answer, see Eve's explanation and where it came from.
class DuelScreen extends StatefulWidget {
  const DuelScreen({super.key, required this.set, this.topic, this.solo = false, this.autoPick});
  final StudySet set;
  final bool solo;

  /// Topic being practised; defaults to the one Eve suggests.
  final int? topic;

  /// Answers the first question by itself (used by the ?pick= preview link).
  final int? autoPick;

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> with SingleTickerProviderStateMixin {
  static const _seconds = 20;
  late final AnimationController _timer = AnimationController(vsync: this, duration: const Duration(seconds: _seconds))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _pick(-1);
    });

  int _qi = 0;
  int? _picked; // -1 = ran out of time
  bool _showSource = false;
  int _lastGain = 0;
  final _correct = <bool>[];
  final _mine = <int>[];
  final _friend = <int>[];
  final _secs = <double>[];

  List<ProtoQuestion> get _qs => widget.set.questions;
  ProtoQuestion get _q => _qs[_qi];
  bool get _revealed => _picked != null;

  @override
  void initState() {
    super.initState();
    _timer.forward();
    final pick = widget.autoPick;
    if (pick != null) Future.delayed(const Duration(milliseconds: 600), () => mounted ? _pick(pick) : null);
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  void _pick(int i) {
    if (_revealed) return;
    _timer.stop();
    final left = 1 - _timer.value;
    final right = i == _q.answer;
    tick(true, heavy: !right);
    setState(() {
      _picked = i;
      _correct.add(right);
      _lastGain = right ? 500 + (500 * left).round() : 0;
      _mine.add(_lastGain);
      _friend.add(_q.friendPick == _q.answer ? 620 + 90 * _qi : 0);
      _secs.add(_seconds * _timer.value);
    });
  }

  void _next() {
    if (_qi == _qs.length - 1) {
      final result = DuelResult(correct: _correct, mine: _mine, friend: _friend, seconds: _secs, solo: widget.solo);
      Navigator.of(context).pushReplacement(softRoute(ResultsScreen(set: widget.set, topic: widget.topic, result: result)));
      return;
    }
    setState(() {
      _qi++;
      _picked = null;
      _showSource = false;
    });
    _timer
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      // Next sits pinned to the bottom so it's never below the fold after a reveal.
      bottomNavigationBar: !_revealed
          ? null
          : SafeArea(
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                    child: FadeRise(
                      key: ValueKey('next$_qi'),
                      child: GoButton(label: _qi == _qs.length - 1 ? 'See results' : 'Next question', onTap: _next),
                    ),
                  ),
                ),
              ),
            ),
      body: PageBody(
        maxWidth: 560,
        child: AnswerKeys(
          onPick: _revealed ? null : _pick,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(children: [
                CircleIconButton(icon: Icons.close_rounded, label: 'Leave duel', onTap: () => Navigator.of(context).maybePop()),
                const SizedBox(width: 10),
                ProtoPill(
                  '${widget.solo ? 'Solo' : 'Live'} · Q${_qi + 1}/${_qs.length}',
                  bg: c.surface,
                  fg: c.ink,
                  liveDot: !widget.solo,
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _timer,
                  builder: (_, __) => TimerRing(
                    fraction: 1 - _timer.value,
                    seconds: (_seconds * (1 - _timer.value)).ceil(),
                    size: 52,
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              _players(context),
              const SizedBox(height: 14),
              Text('${widget.set.title} · ${widget.set.topics[widget.topic ?? widget.set.duelTopic].name}'.toUpperCase(), style: mono(color: c.muted)),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: Duration(milliseconds: context.motion ? 380 : 0),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(a), child: child),
                ),
                child: Column(
                  key: ValueKey(_qi),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(26)),
                      child: Text(_q.q, style: T.disp(23, color: c.ink).copyWith(height: 1.18)),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _q.options.length; i++) _answer(context, i),
                  ],
                ),
              ),
              if (_revealed) _reveal(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _players(BuildContext context) {
    final c = context.c;
    Widget lane(String name, int idx, List<int> pts, List<bool> marks) {
      final total = pts.fold(0, (a, b) => a + b);
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Avatar(initial: name[0], index: idx, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: T.body(13, w: FontWeight.w700, color: c.muted)),
                CountUp(key: ValueKey(total), value: total, style: T.disp(20, color: c.ink), duration: const Duration(milliseconds: 600)),
                const SizedBox(height: 6),
                Row(children: [
                  for (var q = 0; q < _qs.length; q++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 5,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          color: q < marks.length ? (marks[q] ? Proto.right : Proto.wrong) : c.line,
                        ),
                      ),
                    ),
                ]),
              ]),
            ),
          ]),
        ),
      );
    }

    final friendMarks = [for (final p in _friend) p > 0];
    return Stack(clipBehavior: Clip.none, children: [
      Row(children: [
        lane('You', 1, _mine, _correct),
        if (!widget.solo) ...[
          const SizedBox(width: 10),
          lane(friendName, 4, _friend, friendMarks),
        ],
      ]),
      if (_revealed && _lastGain > 0)
        Positioned(
          left: 60,
          top: -6,
          child: IgnorePointer(child: FloatUp(text: '+$_lastGain', color: c.ink)),
        ),
    ]);
  }

  Widget _answer(BuildContext context, int i) {
    final c = context.c;
    final isRight = i == _q.answer;
    final isPicked = i == _picked;
    final friendHere = !widget.solo && _revealed && _q.friendPick == i;

    Color bg = c.surface;
    Color fg = c.ink;
    if (_revealed && isRight) {
      bg = Proto.right;
      fg = Pastel.ink;
    } else if (_revealed && isPicked) {
      bg = Proto.wrong;
      fg = Pastel.ink;
    }

    Widget tile = AnimatedContainer(
      duration: Duration(milliseconds: context.motion ? 260 : 0),
      curve: Curves.easeOut,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _revealed && (isRight || isPicked) ? Colors.transparent : c.line, width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: fg.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: Text('ABCD'[i], style: T.disp(15, color: fg)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(_q.options[i], style: T.body(16.5, w: FontWeight.w600, color: fg))),
        if (friendHere) ...[
          const SizedBox(width: 8),
          PopIn(enabled: context.motion, child: Avatar(initial: friendName[0], index: 4, size: 28, ring: c.surface)),
        ],
        if (_revealed && isRight) ...[
          const SizedBox(width: 8),
          const Icon(Icons.check_circle_rounded, color: Pastel.ink, semanticLabel: 'Correct answer'),
        ],
        if (_revealed && isPicked && !isRight) ...[
          const SizedBox(width: 8),
          const Icon(Icons.cancel_rounded, color: Pastel.ink, semanticLabel: 'Your answer, wrong'),
        ],
      ]),
    );
    if (_revealed && isRight && isPicked) tile = PopIn(enabled: context.motion, child: tile);
    if (_revealed && isPicked && !isRight) tile = Shake(trigger: _qi, enabled: context.motion, child: tile);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Pressable(
        // Always enabled so answers keep full colour after the reveal; _pick ignores late taps.
        onTap: () => _pick(i),
        scale: 0.97,
        semanticLabel: 'Answer ${'ABCD'[i]}: ${_q.options[i]}',
        child: tile,
      ),
    );
  }

  Widget _reveal(BuildContext context) {
    final c = context.c;
    final right = _picked == _q.answer;
    return FadeRise(
      key: ValueKey('reveal$_qi'),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(26)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Eve(mood: right ? EveMood.happy : EveMood.oops, size: 58, iris: c.iris, motion: context.motion),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  right ? 'Nice one!' : (_picked == -1 ? 'Out of time!' : 'Not quite.'),
                  style: T.disp(19, color: c.ink),
                ),
                const SizedBox(height: 4),
                Text(_q.why, style: T.body(15, color: c.ink)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Pressable(
              onTap: () => setState(() => _showSource = !_showSource),
              semanticLabel: 'Show me where',
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _showSource ? c.primary : c.surface2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.place_rounded, size: 17, color: _showSource ? c.onPrimary : c.ink),
                  const SizedBox(width: 6),
                  Text('Show me where', style: T.body(14, w: FontWeight.w700, color: _showSource ? c.onPrimary : c.ink)),
                ]),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => showToast(context, 'Thanks! Eve will check this question.'),
              icon: Icon(Icons.flag_outlined, size: 17, color: c.muted),
              label: Text('Report', style: T.body(14, w: FontWeight.w600, color: c.muted)),
            ),
          ]),
          AnimatedSize(
            duration: Duration(milliseconds: context.motion ? 300 : 0),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_showSource
                ? const SizedBox(width: double.infinity)
                : Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Pastel.lime.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_q.source.toUpperCase(), style: mono(color: Pastel.ink)),
                      const SizedBox(height: 6),
                      Text('“${_q.quote}”', style: T.body(15, w: FontWeight.w600, color: Pastel.ink)),
                    ]),
                  ),
          ),
        ]),
      ),
    );
  }
}
