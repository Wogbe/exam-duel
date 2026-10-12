import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import 'duel_screen.dart';
import 'proto_data.dart';
import 'proto_kit.dart';

/// A tapped tile grown into a full screen: mastery, source and the duel button.
class TopicScreen extends StatelessWidget {
  const TopicScreen({super.key, required this.set, int? index}) : index = index ?? -1;
  final StudySet set;
  final int index;

  int get _i => index < 0 ? set.duelTopic : index;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = set.topics[_i];
    final mastery = progress.mastery(set, _i);
    final pct = const [0, 35, 70, 100][mastery.index];
    final hasDuel = _i == set.duelTopic;
    final q = set.questions.first;

    return Scaffold(
      body: PageBody(
        maxWidth: 520,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(children: [
              CircleIconButton(icon: Icons.close_rounded, label: 'Close', onTap: () => Navigator.of(context).maybePop()),
              const Spacer(),
              Text(set.title.toUpperCase(), style: mono(color: c.muted)),
            ]),
            const SizedBox(height: 14),
            Hero(
              tag: 'tile-${set.id}-$_i',
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  height: 200,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: mastery.fill(c),
                    borderRadius: BorderRadius.circular(30),
                    border: mastery == Mastery.unseen ? Border.all(color: c.line, width: 1.5) : null,
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 44)),
                      const Spacer(),
                      ProtoPill(mastery.label, bg: Colors.white.withValues(alpha: 0.75)),
                    ]),
                    const Spacer(),
                    Text(t.name, style: T.disp(36, color: mastery.ink(c))),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeRise(
              delay: const Duration(milliseconds: 260),
              child: Row(children: [
                Expanded(child: _Stat(label: 'Mastery', child: _Ring(pct: pct))),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    label: 'Last try',
                    child: Text(mastery == Mastery.unseen ? '–' : '${mastery.pips - 1}/3', style: T.num(40, color: c.ink)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _Stat(label: 'Questions', child: Text('10', style: T.num(40, color: c.ink)))),
              ]),
            ),
            const SizedBox(height: 14),
            FadeRise(
              delay: const Duration(milliseconds: 360),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.place_rounded, size: 16, color: c.muted),
                    const SizedBox(width: 6),
                    Text(q.source.toUpperCase(), style: mono(color: c.muted)),
                  ]),
                  const SizedBox(height: 8),
                  Text('“${q.quote}”', style: T.body(15.5, color: c.ink)),
                ]),
              ),
            ),
            const SizedBox(height: 22),
            FadeRise(
              delay: const Duration(milliseconds: 460),
              child: Column(children: [
                MorphButton(
                  label: 'Challenge a friend',
                  doneLabel: '$friendName joined!',
                  icon: Icons.bolt_rounded,
                  onDone: () => Navigator.of(context).pushReplacement(softRoute(DuelScreen(set: set, topic: _i))),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: GhostButton(
                    label: 'Practise solo',
                    onTap: () => Navigator.of(context).pushReplacement(softRoute(DuelScreen(set: set, topic: _i, solo: true))),
                  ),
                ),
                if (!hasDuel) ...[
                  const SizedBox(height: 10),
                  Text('Preview uses the ${set.focus.name} questions for every tile.', style: T.body(13, color: c.muted)),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        height: 120,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.c.surface, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: mono(color: context.c.muted)),
          const Spacer(),
          child,
        ]),
      );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.pct});
  final int pct;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: context.motion ? 0 : pct / 100, end: pct / 100),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Semantics(
        label: '$pct percent mastered',
        child: SizedBox(
          width: 54,
          height: 54,
          child: CustomPaint(
            painter: _RingPainter(v, c.line, c.ink),
            child: Center(child: Text('${(v * 100).round()}', style: T.disp(17, color: c.ink))),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.track, this.fill);
  final double v;
  final Color track, fill;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(4);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, 2 * math.pi, false, p..color = track);
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi * v, false, p..color = fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v;
}
