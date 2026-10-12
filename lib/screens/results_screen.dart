import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/duel_result.dart';
import '../data/sample_sets.dart';
import '../data/study_set.dart';
import '../state/progress.dart';
import '../theme/app_theme.dart';
import '../theme/mastery.dart';
import '../widgets/common.dart';
import '../widgets/eve/eve.dart';
import '../widgets/responsive.dart';
import '../widgets/study_widgets.dart';
import '../widgets/view_settings.dart';
import 'duel_screen.dart';
import 'map_screen.dart';

/// Step 4: the celebration and what changed on your map.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.set, required this.result, this.topic});
  final StudySet set;

  /// Topic that was practised; defaults to the one Eve suggests.
  final int? topic;
  final DuelResult result;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _burst = 0;
  late final int _topic;
  late final Mastery _from, _to;

  @override
  void initState() {
    super.initState();
    _topic = widget.topic ?? widget.set.duelTopic;
    _from = progress.mastery(widget.set, _topic);
    // Two right answers earn a level on the map, once per results screen.
    // Applied after this frame: the map behind us listens and must not rebuild mid-build.
    final up = r.rightCount >= 2 && _from != Mastery.ready;
    _to = up ? Mastery.values[_from.index + 1] : _from;
    if (up) WidgetsBinding.instance.addPostFrameCallback((_) => progress.levelUp(widget.set, _topic));
  }

  DuelResult get r => widget.result;

  String get _headline {
    if (r.solo) return 'Nice practice!';
    if (r.won) return 'You beat $friendName!';
    if (r.lost) return '$friendName wins this one';
    return "It's a draw!";
  }

  EveMood get _mood => r.won ? EveMood.cheering : (r.lost ? EveMood.oops : EveMood.proud);

  bool get _celebrate => r.won || r.solo && r.rightCount >= 2;

  void _share() {
    final tiles = [for (var i = 0; i < widget.set.topics.length && i < 8; i++) progress.mastery(widget.set, i).emoji].join();
    showToast(context, 'Exam Duel · ${widget.set.title} $tiles ${progress.readiness(widget.set)}%');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final motion = context.motion;
    final avg = r.seconds.isEmpty ? 0.0 : r.seconds.reduce((a, b) => a + b) / r.seconds.length;
    final focus = widget.set.topics[_topic];

    return Scaffold(
      body: Stack(children: [
        if (_celebrate)
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            height: 520,
            child: IgnorePointer(child: Opacity(opacity: 0.55, child: Sunburst(color: Pastel.lime))),
          ),
        PageBody(
          maxWidth: 520,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(children: [
                CircleIconButton(icon: Icons.close_rounded, label: 'Close', onTap: () => Navigator.of(context).maybePop()),
                const Spacer(),
                if (!r.solo) const CapsPill('$sampleStreak-day streak', icon: Icons.local_fire_department_rounded),
              ]),
              const SizedBox(height: 8),
              Center(
                child: Pressable(
                  onTap: _celebrate ? () => setState(() => _burst++) : null,
                  semanticLabel: 'Eve. Tap for confetti',
                  child: PopIn(enabled: motion, child: Eve(mood: _mood, size: 150, iris: c.iris, sparkle: r.won, motion: motion)),
                ),
              ),
              const SizedBox(height: 6),
              FadeRise(
                delay: const Duration(milliseconds: 250),
                blur: true,
                child: Text(_headline, textAlign: TextAlign.center, style: T.disp(34, color: c.ink)),
              ),
              const SizedBox(height: 8),
              FadeRise(
                delay: const Duration(milliseconds: 380),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CountUp(value: r.myTotal, style: T.disp(22, color: c.ink)),
                  if (!r.solo) ...[
                    Text('  vs  ', style: T.body(16, color: c.muted)),
                    CountUp(value: r.friendTotal, style: T.disp(22, color: c.muted)),
                  ] else
                    Text('  points', style: T.body(16, color: c.muted)),
                ]),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  _StatTile(Pastel.lav, 'Accuracy', '${(100 * r.rightCount / r.correct.length).round()}%', 500, motion),
                  _StatTile(Pastel.sky, 'Avg time', '${avg.toStringAsFixed(1)}s', 580, motion),
                  _StatTile(Pastel.peach, 'Streak', '$sampleStreak days', 660, motion),
                  _StatTile(Pastel.lime, 'XP earned', '+${10 * r.rightCount + 10}', 740, motion),
                ],
              ),
              const SizedBox(height: 12),
              FadeRise(delay: const Duration(milliseconds: 820), child: _DotChart(result: r)),
              const SizedBox(height: 12),
              FadeRise(
                delay: const Duration(milliseconds: 950),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24)),
                  child: Row(children: [
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: _FlipTile(
                        emoji: focus.emoji,
                        from: _from,
                        to: _to,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('YOUR MAP', style: mono(color: c.muted)),
                        const SizedBox(height: 4),
                        Text(
                          _to != _from
                              ? '${focus.name} moved up: ${_from.label} → ${_to.label}'
                              : (_from == Mastery.ready
                                  ? '${focus.name} is Ready. Nice upkeep!'
                                  : '${focus.name} is still ${_from.label}. Eve will bring it back tomorrow.'),
                          style: T.body(15.5, w: FontWeight.w700, color: c.ink),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 22),
              FadeRise(
                delay: Duration(milliseconds: motion ? 1700 : 0),
                child: Column(children: [
                  GoButton(
                    label: r.solo ? 'Go again' : 'Rematch',
                    onTap: () => Navigator.of(context).pushReplacement(softRoute(DuelScreen(set: widget.set, topic: _topic, solo: r.solo))),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: GhostButton(
                        label: 'Back to map',
                        onTap: () => Navigator.of(context).pushReplacement(softRoute(MapScreen(set: widget.set))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleIconButton(icon: Icons.ios_share_rounded, label: 'Share', fill: Pastel.lime, onTap: _share),
                  ]),
                ]),
              ),
            ],
          ),
        ),
        if (_celebrate && motion) Positioned.fill(child: ConfettiBurst(key: ValueKey(_burst))),
        if (_celebrate)
          Positioned(
            top: 150,
            right: 28,
            child: IgnorePointer(
              child: FadeRise(
                delay: const Duration(milliseconds: 1200),
                child: Transform.rotate(
                  angle: 0.18,
                  child: CapsPill('+${10 * r.rightCount + 10} XP', bg: Pastel.lime),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.colour, this.label, this.value, this.delayMs, this.motion);
  final Color colour;
  final String label, value;
  final int delayMs;
  final bool motion;

  @override
  Widget build(BuildContext context) => PopIn(
        enabled: motion,
        delay: Duration(milliseconds: delayMs),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: mono(color: Pastel.ink)),
            const Spacer(),
            Text(value, style: T.disp(30, color: Pastel.ink)),
          ]),
        ),
      );
}

/// One column of dots per question: taller = more points. The best one sits on a lime highlight.
class _DotChart extends StatelessWidget {
  const _DotChart({required this.result});
  final DuelResult result;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final best = result.mine.isEmpty ? -1 : result.mine.indexOf(result.mine.reduce(math.max));
    final summary = 'Points per question: ${[for (var i = 0; i < result.mine.length; i++) 'Q${i + 1} ${result.mine[i]}'].join(', ')}';
    return Semantics(
      label: summary,
      excludeSemantics: true,
      child: Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('POINTS PER QUESTION', style: mono(color: c.muted)),
          const Spacer(),
          if (best >= 0 && result.mine[best] > 0) CapsPill('Best · Q${best + 1}'),
        ]),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: context.motion ? 0 : 1, end: 1),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (_, t, __) => SizedBox(
            height: 96,
            child: CustomPaint(
              size: Size.infinite,
              painter: _DotChartPainter(result.mine, result.correct, best, t, c.ink, c.line),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          for (var i = 0; i < result.mine.length; i++)
            Expanded(child: Text('Q${i + 1}', textAlign: TextAlign.center, style: mono(color: c.muted))),
        ]),
      ]),
    ),
    );
  }
}

class _DotChartPainter extends CustomPainter {
  _DotChartPainter(this.points, this.correct, this.best, this.t, this.ink, this.line);
  final List<int> points;
  final List<bool> correct;
  final int best;
  final double t;
  final Color ink, line;

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 10;
    const cols = 5;
    final colW = size.width / points.length;
    final step = size.height / rows;
    final r = step * 0.3;
    for (var q = 0; q < points.length; q++) {
      final lit = (points[q] / 1000 * rows * t).round();
      if (q == best && points[q] > 0) {
        final w = cols * step + step * 0.6;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(q * colW + colW / 2, size.height / 2), width: w, height: size.height + 6),
              const Radius.circular(12)),
          Paint()..color = Pastel.lime.withValues(alpha: 0.7),
        );
      }
      final colour = correct[q] ? ink : Pastel.wrong;
      for (var x = 0; x < cols; x++) {
        final cx = q * colW + colW / 2 + (x - (cols - 1) / 2) * step;
        for (var y = 0; y < rows; y++) {
          final on = y < lit;
          canvas.drawCircle(
            Offset(cx, size.height - step / 2 - y * step),
            r,
            Paint()..color = on ? colour : line,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_DotChartPainter old) => old.t != t;
}

/// The duel's topic tile flipping over to its new colour.
class _FlipTile extends StatefulWidget {
  const _FlipTile({required this.emoji, required this.from, required this.to});
  final String emoji;
  final Mastery from, to;

  @override
  State<_FlipTile> createState() => _FlipTileState();
}

class _FlipTileState extends State<_FlipTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.from == widget.to) return;
    if (!context.motion) {
      _c.value = 1;
    } else {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeInOutBack.transform(_c.value).clamp(0.0, 1.0);
        final angle = t * math.pi;
        final m = angle < math.pi / 2 ? widget.from : widget.to;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(angle < math.pi / 2 ? angle : angle - math.pi),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(color: m.fill(c), borderRadius: BorderRadius.circular(20)),
            child: Text(widget.emoji, style: const TextStyle(fontSize: 32)),
          ),
        );
      },
    );
  }
}
