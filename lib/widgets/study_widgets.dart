import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';
import 'view_settings.dart';

// Small widgets shared by the Snap → Map → Duel screens.

// ── Motion helpers ─────────────────────────────────────────────────────────

/// Fades and rises a child in after [delay]. With [blur], it also comes into focus.
class FadeRise extends StatefulWidget {
  const FadeRise({super.key, required this.child, this.delay = Duration.zero, this.blur = false, this.distance = 18});
  final Widget child;
  final Duration delay;
  final bool blur;
  final double distance;

  @override
  State<FadeRise> createState() => _FadeRiseState();
}

class _FadeRiseState extends State<FadeRise> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!context.motion) {
      _c.value = 1;
      return;
    }
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) {
          final t = Curves.easeOutCubic.transform(_c.value);
          Widget w = Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, widget.distance * (1 - t)), child: child),
          );
          if (widget.blur && t < 1) {
            final s = 8 * (1 - t);
            w = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: s, sigmaY: s), child: w);
          }
          return w;
        },
      );
}

/// A looping 0→1 clock for ambient motion. Stands still when motion is off.
class Ambient extends StatefulWidget {
  const Ambient({super.key, required this.builder, this.period = const Duration(seconds: 12)});
  final Widget Function(BuildContext context, double t) builder;
  final Duration period;

  @override
  State<Ambient> createState() => _AmbientState();
}

class _AmbientState extends State<Ambient> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.motion) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (context, _) => widget.builder(context, _c.value));
}

// ── Gradient blob (hero card background) ───────────────────────────────────

/// Soft drifting colour blob, like glide's score card. Cheap: three radial gradients.
class GradientBlob extends StatelessWidget {
  const GradientBlob({super.key, required this.colors, this.radius = 28, this.child});
  final List<Color> colors;
  final double radius;
  final Widget? child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Ambient(
            period: const Duration(seconds: 14),
            builder: (_, t) => CustomPaint(painter: _BlobPainter(colors, t), child: child),
          ),
        ),
      );
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.colors, this.t);
  final List<Color> colors;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..color = colors.first);
    final a = t * 2 * math.pi;
    final spots = [
      (Offset(0.25 + 0.12 * math.sin(a), 0.3 + 0.1 * math.cos(a)), colors[1 % colors.length], 0.75),
      (Offset(0.78 + 0.1 * math.cos(a * 1.3), 0.35 + 0.14 * math.sin(a)), colors[2 % colors.length], 0.7),
      (Offset(0.5 + 0.15 * math.sin(a * 0.7 + 1), 0.85 + 0.08 * math.cos(a)), colors[3 % colors.length], 0.8),
    ];
    for (final (pos, col, rad) in spots) {
      final center = Offset(pos.dx * size.width, pos.dy * size.height);
      final radius = rad * size.longestSide;
      canvas.drawRect(
        r,
        Paint()
          ..shader = RadialGradient(colors: [col, col.withValues(alpha: 0)]).createShader(
            Rect.fromCircle(center: center, radius: radius),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t || old.colors != colors;
}

// ── Dot-matrix number ──────────────────────────────────────────────────────

const _glyphs = <String, List<String>>{
  '0': [' ### ', '#   #', '#  ##', '# # #', '##  #', '#   #', ' ### '],
  '1': ['  #  ', ' ##  ', '  #  ', '  #  ', '  #  ', '  #  ', ' ### '],
  '2': [' ### ', '#   #', '    #', '   # ', '  #  ', ' #   ', '#####'],
  '3': ['#####', '   # ', '  #  ', '   # ', '    #', '#   #', ' ### '],
  '4': ['   # ', '  ## ', ' # # ', '#  # ', '#####', '   # ', '   # '],
  '5': ['#####', '#    ', '#### ', '    #', '    #', '#   #', ' ### '],
  '6': ['  ## ', ' #   ', '#    ', '#### ', '#   #', '#   #', ' ### '],
  '7': ['#####', '    #', '   # ', '  #  ', ' #   ', ' #   ', ' #   '],
  '8': [' ### ', '#   #', '#   #', ' ### ', '#   #', '#   #', ' ### '],
  '9': [' ### ', '#   #', '#   #', ' ####', '    #', '   # ', ' ##  '],
  '%': ['##   ', '##  #', '   # ', '  #  ', ' #   ', '#  ##', '   ##'],
};

/// Big LED-style number that counts up and lights its dots as it lands.
class DotNumber extends StatelessWidget {
  const DotNumber({super.key, required this.value, this.suffix = '%', this.dot = 8, this.color = Pastel.ink, this.semanticLabel});
  final int value;
  final String suffix;
  final double dot;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    final text = '$value$suffix';
    final width = text.length * 7 * dot - 2 * dot;
    return Semantics(
      label: semanticLabel ?? text,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: motion ? 0 : value.toDouble(), end: value.toDouble()),
          duration: Duration(milliseconds: motion ? 1300 : 0),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => CustomPaint(
            size: Size(width, 7 * dot),
            painter: _DotPainter('${v.round()}$suffix'.padLeft(text.length), dot, color, value == 0 ? 1 : v / value),
          ),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  _DotPainter(this.text, this.dot, this.color, this.progress);
  final String text;
  final double dot;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Lit dots brighten as the count lands.
    final on = Paint()..color = color.withValues(alpha: 0.55 + 0.45 * progress);
    final off = Paint()..color = color.withValues(alpha: 0.07);
    final r = dot * 0.4;
    for (var i = 0; i < text.length; i++) {
      final rows = _glyphs[text[i]];
      for (var y = 0; y < 7; y++) {
        for (var x = 0; x < 5; x++) {
          final c = Offset((i * 7 + x) * dot + dot / 2, y * dot + dot / 2);
          final lit = rows != null && rows[y][x] == '#';
          canvas.drawCircle(c, lit ? r : r * 0.55, lit ? on : off);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter old) => old.text != text || old.progress != progress || old.color != color;
}

/// Thin ruler with a marker, under the hero number.
class Ruler extends StatelessWidget {
  const Ruler({super.key, required this.value, this.color = Pastel.ink});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: context.motion ? 0 : value, end: value),
        duration: const Duration(milliseconds: 1300),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => CustomPaint(size: const Size(double.infinity, 22), painter: _RulerPainter(v, color)),
      );
}

class _RulerPainter extends CustomPainter {
  _RulerPainter(this.v, this.color);
  final double v;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 48;
    final p = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    for (var i = 0; i <= n; i++) {
      final x = size.width * i / n;
      final h = i % 6 == 0 ? 12.0 : 6.0;
      canvas.drawLine(Offset(x, size.height - h), Offset(x, size.height), p);
    }
    final mx = size.width * v.clamp(0.0, 1.0);
    canvas.drawLine(
      Offset(mx, 0),
      Offset(mx, size.height),
      Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RulerPainter old) => old.v != v;
}

// ── Pills ──────────────────────────────────────────────────────────────────

/// Small caps pill: lime for wins and streaks, white with a pulsing dot for live.
class CapsPill extends StatelessWidget {
  const CapsPill(this.text, {super.key, this.bg = Pastel.lime, this.fg = Pastel.ink, this.liveDot = false, this.icon});
  final String text;
  final Color bg, fg;
  final bool liveDot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (liveDot) ...[const _PulseDot(), const SizedBox(width: 7)],
          if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 5)],
          Text(text.toUpperCase(), style: mono(size: 11.5, color: fg, w: FontWeight.w700)),
        ]),
      );
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) => Ambient(
        period: const Duration(milliseconds: 1400),
        builder: (_, t) {
          final pulse = context.motion ? math.sin(t * math.pi) : 0.0;
          return SizedBox(
            width: 10,
            height: 10,
            child: Stack(alignment: Alignment.center, children: [
              Container(
                width: 8 + 6 * pulse,
                height: 8 + 6 * pulse,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Pastel.live.withValues(alpha: 0.3 * (1 - pulse))),
              ),
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Pastel.live)),
            ]),
          );
        },
      );
}


// ── Skeleton shimmer ───────────────────────────────────────────────────────

/// Grey placeholder with a light sweep, shown while Eve builds something.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.radius = 20});
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Ambient(
      period: const Duration(milliseconds: 1300),
      builder: (context, t) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment(-2.5 + 4 * t, 0),
            end: Alignment(-0.5 + 4 * t, 0),
            colors: [c.ink.withValues(alpha: 0.08), c.ink.withValues(alpha: 0.02), c.ink.withValues(alpha: 0.08)],
          ),
        ),
      ),
    );
  }
}

// ── Floating nav ───────────────────────────────────────────────────────────

/// Floating pill nav with a sliding highlight. The middle button is Snap.
class FloatingNav extends StatelessWidget {
  const FloatingNav({super.key, required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.grid_view_rounded, 'Map'),
    (Icons.bolt_rounded, 'Duels'),
    (Icons.add_rounded, 'Snap'),
    (Icons.person_rounded, 'Me'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 64,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.nav,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth / _items.length;
        return Stack(children: [
          AnimatedPositioned(
            duration: Duration(milliseconds: context.motion ? 420 : 0),
            curve: Curves.easeOutBack,
            left: index * w,
            width: w,
            top: 0,
            bottom: 0,
            child:
                Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999))),
          ),
          Row(children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: Pressable(
                  onTap: () => onTap(i),
                  semanticLabel: _items[i].$2,
                  child: SizedBox.expand(
                    child: Center(
                      child: i == 2
                          ? Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: c.acc, shape: BoxShape.circle),
                              child: const Icon(Icons.add_rounded, color: Pastel.ink, size: 26),
                            )
                          : Icon(_items[i].$1, color: i == index ? Colors.white : c.navFg, size: 24),
                    ),
                  ),
                ),
              ),
          ]),
        ]);
      }),
    );
  }
}

// ── Morphing button ────────────────────────────────────────────────────────

/// Primary button that shrinks to a spinner, turns into a tick, then calls [onDone].
class MorphButton extends StatefulWidget {
  const MorphButton({super.key, required this.label, required this.doneLabel, required this.onDone, this.icon = Icons.send_rounded});
  final String label, doneLabel;
  final IconData icon;
  final VoidCallback onDone;

  @override
  State<MorphButton> createState() => _MorphButtonState();
}

class _MorphButtonState extends State<MorphButton> {
  int _stage = 0; // 0 idle, 1 working, 2 done

  Future<void> _go() async {
    if (_stage != 0) return;
    final motion = context.motion;
    setState(() => _stage = 1);
    await Future.delayed(Duration(milliseconds: motion ? 1100 : 300));
    if (!mounted) return;
    setState(() => _stage = 2);
    await Future.delayed(Duration(milliseconds: motion ? 900 : 300));
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final d = Duration(milliseconds: context.motion ? 380 : 0);
    return LayoutBuilder(builder: (context, box) {
      final full = box.maxWidth;
      final width = switch (_stage) { 1 => 58.0, _ => full };
      return Center(
        child: Pressable(
          onTap: _stage == 0 ? _go : null,
          semanticLabel: widget.label,
          child: AnimatedContainer(
            duration: d,
            curve: Curves.easeInOutCubic,
            width: width,
            height: 58,
            decoration: BoxDecoration(
              color: _stage == 2 ? Pastel.right : c.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: AnimatedSwitcher(
              duration: d,
              transitionBuilder: (child, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: child),
              child: switch (_stage) {
                0 => Row(
                    key: const ValueKey(0),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, color: c.onPrimary, size: 20),
                      const SizedBox(width: 10),
                      Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis, style: T.disp(18, color: c.onPrimary))),
                    ],
                  ),
                1 => SizedBox(
                    key: const ValueKey(1),
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.6, color: c.onPrimary),
                  ),
                _ => Row(
                    key: const ValueKey(2),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, color: Pastel.ink, size: 24),
                      const SizedBox(width: 8),
                      Text(widget.doneLabel, style: T.disp(18, color: Pastel.ink)),
                    ],
                  ),
              },
            ),
          ),
        ),
      );
    });
  }
}

// ── Sunburst ───────────────────────────────────────────────────────────────

/// Slowly turning rays behind a celebration.
class Sunburst extends StatelessWidget {
  const Sunburst({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Ambient(
          period: const Duration(seconds: 30),
          builder: (_, t) => CustomPaint(painter: _RayPainter(color, t * 2 * math.pi), size: Size.infinite),
        ),
      );
}

class _RayPainter extends CustomPainter {
  _RayPainter(this.color, this.angle);
  final Color color;
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.longestSide;
    const rays = 18;
    final shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r * 0.6));
    final p = Paint()..shader = shader;
    for (var i = 0; i < rays; i++) {
      final a = angle + i * 2 * math.pi / rays;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + r * math.cos(a - 0.07), c.dy + r * math.sin(a - 0.07))
        ..lineTo(c.dx + r * math.cos(a + 0.07), c.dy + r * math.sin(a + 0.07))
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_RayPainter old) => old.angle != angle;
}

// ── Typewriter ─────────────────────────────────────────────────────────────

/// Types each line, pauses, deletes it and moves on. Shows the first line still when motion is off.
class Typewriter extends StatefulWidget {
  const Typewriter({super.key, required this.lines, required this.style, this.loop = true});
  final List<String> lines;
  final TextStyle style;
  final bool loop;

  @override
  State<Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<Typewriter> {
  String _shown = '';
  bool _alive = true;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!context.motion) {
      _shown = widget.lines.first;
    } else {
      _run();
    }
  }

  Future<void> _run() async {
    var i = 0;
    while (_alive) {
      final line = widget.lines[i % widget.lines.length];
      for (var n = 1; n <= line.length && _alive; n++) {
        await Future.delayed(const Duration(milliseconds: 55));
        if (_alive) setState(() => _shown = line.substring(0, n));
      }
      if (!widget.loop) return;
      await Future.delayed(const Duration(milliseconds: 1500));
      for (var n = line.length; n >= 0 && _alive; n--) {
        await Future.delayed(const Duration(milliseconds: 22));
        if (_alive) setState(() => _shown = line.substring(0, n));
      }
      i++;
    }
  }

  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finished = !widget.loop && _shown == widget.lines.first;
    return Text(finished ? _shown : '$_shown▍', style: widget.style, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

