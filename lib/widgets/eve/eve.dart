import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_drawing/path_drawing.dart';

/// Eve's moods, matching the character sheet.
enum EveMood { idle, happy, cheering, thinking, surprised, sleepy, sad, fire, proud, oops }

enum _Blink { normal, double, sleepy }

/// Pose parameters. Every mood is a set of these; moods blend smoothly.
class _Pose {
  final double lid, lidRot, low, eye, pr, wl, wr, tilt, beak, blush, stars, flame, tear, z, tuft, glow, lx, ly;
  final _Blink blink;
  const _Pose({
    this.lid = 0,
    this.lidRot = 0,
    this.low = 47,
    this.eye = 1,
    this.pr = 10,
    this.wl = 0,
    this.wr = 0,
    this.tilt = 0,
    this.beak = 0,
    this.blush = 0.35,
    this.stars = 0,
    this.flame = 0,
    this.tear = 0,
    this.z = 0,
    this.tuft = 0,
    this.glow = 0,
    this.lx = 0,
    this.ly = 0,
    this.blink = _Blink.normal,
  });

  static _Pose of(EveMood m) => switch (m) {
        EveMood.idle => const _Pose(),
        EveMood.happy => const _Pose(low: 37, pr: 11, wl: 18, wr: -18, tilt: -3, blush: 0.75, tuft: 4),
        EveMood.cheering => const _Pose(low: 40, eye: 1.04, pr: 11, wl: 120, wr: -120, beak: 1, blush: 0.75, stars: 1, tuft: 10),
        EveMood.thinking => const _Pose(lid: 9, eye: 0.96, pr: 9, wr: 80, tilt: -9, lx: -0.6, ly: -0.75),
        EveMood.surprised => const _Pose(low: 50, eye: 1.13, pr: 6.5, wl: 30, wr: -30, beak: 1, tuft: 14, blush: 0.2),
        EveMood.sleepy => const _Pose(lid: 31, low: 44, tilt: 7, z: 1, tuft: -22, ly: 0.4, blink: _Blink.sleepy, blush: 0.2),
        EveMood.sad => const _Pose(lid: 15, lidRot: -17, tear: 1, tuft: -26, tilt: 5, ly: 0.55, wl: -6, wr: 6, blush: 0),
        EveMood.fire => const _Pose(lid: 4, low: 41, eye: 1.02, pr: 9, wl: 65, wr: -65, flame: 1, glow: 1, tuft: 12, blush: 0.5),
        EveMood.proud => const _Pose(lid: 12, low: 35, wl: 28, wr: -28, tilt: -5, blush: 0.6, tuft: 8, ly: -0.2),
        EveMood.oops => const _Pose(lid: 3, pr: 9, tilt: 11, lx: 0.3, ly: -0.2, blink: _Blink.double, blush: 0.2),
      };

  static _Pose lerp(_Pose a, _Pose b, double t) {
    double l(double x, double y) => x + (y - x) * t;
    return _Pose(
      lid: l(a.lid, b.lid),
      lidRot: l(a.lidRot, b.lidRot),
      low: l(a.low, b.low),
      eye: l(a.eye, b.eye),
      pr: l(a.pr, b.pr),
      wl: l(a.wl, b.wl),
      wr: l(a.wr, b.wr),
      tilt: l(a.tilt, b.tilt),
      beak: l(a.beak, b.beak),
      blush: l(a.blush, b.blush),
      stars: l(a.stars, b.stars),
      flame: l(a.flame, b.flame),
      tear: l(a.tear, b.tear),
      z: l(a.z, b.z),
      tuft: l(a.tuft, b.tuft),
      glow: l(a.glow, b.glow),
      lx: l(a.lx, b.lx),
      ly: l(a.ly, b.ly),
      blink: t < 0.5 ? a.blink : b.blink,
    );
  }
}

/// Eve the owl. Animated: she blinks, breathes, follows [lookX]/[lookY]
/// and springs between moods. Pass `motion: false` for Reduce motion.
class Eve extends StatefulWidget {
  const Eve({
    super.key,
    this.mood = EveMood.idle,
    this.iris = const Color(0xFF13A3A6),
    this.size = 200,
    this.lookX = 0,
    this.lookY = 0,
    this.outfit = 'none',
    this.sparkle = false,
    this.glow = false,
    this.motion = true,
    this.bob = false,
  });

  final EveMood mood;
  final Color iris;
  final double size;
  final double lookX, lookY;
  final String outfit;
  final bool sparkle, glow, motion, bob;

  @override
  State<Eve> createState() => _EveState();
}

class _EveState extends State<Eve> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _elapsed = Duration.zero;
  Duration _morphStart = Duration.zero;
  _Pose _from = const _Pose();
  _Pose _to = const _Pose();
  double _lookX = 0, _lookY = 0;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _from = _to = _Pose.of(widget.mood);
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration e) {
    final dt = (e - _last).inMicroseconds / 1e6;
    _last = e;
    // Ease the gaze towards the target (feels like real eyes, not a snap).
    final k = 1 - math.exp(-dt * 14);
    _lookX += (widget.lookX - _lookX) * k;
    _lookY += (widget.lookY - _lookY) * k;
    setState(() => _elapsed = e);
  }

  @override
  void didUpdateWidget(Eve old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _from = _currentPose();
      _to = _Pose.of(widget.mood);
      _morphStart = _elapsed;
    }
  }

  _Pose _currentPose() {
    final t = ((_elapsed - _morphStart).inMilliseconds / 320).clamp(0.0, 1.0);
    // Overshooting ease, like the CSS cubic-bezier(.34,1.56,.64,1).
    return _Pose.lerp(_from, _to, Curves.easeOutBack.transform(t));
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secs = _elapsed.inMicroseconds / 1e6;
    final bob = widget.bob && widget.motion ? math.sin(secs * 2 * math.pi / 3.6) * -4 : 0.0;
    return Semantics(
      label: 'Eve the owl, ${widget.mood.name}',
      image: true,
      child: Transform.translate(
        offset: Offset(0, bob),
        child: CustomPaint(
          size: Size(widget.size, widget.size * 1.05),
          painter: _EvePainter(
            pose: _currentPose(),
            time: secs,
            iris: widget.iris,
            lookX: _lookX,
            lookY: _lookY,
            outfit: widget.outfit,
            sparkle: widget.sparkle,
            glow: widget.glow,
            motion: widget.motion,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter: a direct port of Eve's SVG (viewBox 200 × 210).
// ---------------------------------------------------------------------------

final Map<String, Path> _pathCache = {};
Path _p(String d) => _pathCache.putIfAbsent(d, () => parseSvgPathData(d));

const _caramel = Color(0xFFC98A4B);
const _wing = Color(0xFFA86A33);
const _cream = Color(0xFFF6E7C9);
const _face = Color(0xFF5A3826);
const _lidC = Color(0xFF6E4631);
const _gold = Color(0xFFF2B705);
const _green = Color(0xFF1F8A4C);
const _red = Color(0xFFC8452D);
const _night = Color(0xFF1E1B2E);
const _ink = Color(0xFF2A2238);

class _EvePainter extends CustomPainter {
  _EvePainter({
    required this.pose,
    required this.time,
    required this.iris,
    required this.lookX,
    required this.lookY,
    required this.outfit,
    required this.sparkle,
    required this.glow,
    required this.motion,
  });

  final _Pose pose;
  final double time;
  final Color iris;
  final double lookX, lookY;
  final String outfit;
  final bool sparkle, glow, motion;

  Paint _fill(Color c, [double opacity = 1]) => Paint()
    ..color = c.withValues(alpha: c.a * opacity.clamp(0.0, 1.0))
    ..isAntiAlias = true;

  Paint _stroke(Color c, double w, [double opacity = 1]) => Paint()
    ..color = c.withValues(alpha: c.a * opacity.clamp(0.0, 1.0))
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _rotateAround(Canvas c, double deg, double x, double y) {
    c.translate(x, y);
    c.rotate(deg * math.pi / 180);
    c.translate(-x, -y);
  }

  void _ellipse(Canvas c, double cx, double cy, double rx, double ry, Paint p) =>
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2), p);

  /// Keyframe helper: piecewise-linear over (time, value) pairs in a cycle.
  double _keys(double cycle, List<double> times, List<double> values) {
    final t = (time % cycle) / cycle;
    for (var i = 1; i < times.length; i++) {
      if (t <= times[i]) {
        final span = times[i] - times[i - 1];
        final f = span == 0 ? 1.0 : (t - times[i - 1]) / span;
        return values[i - 1] + (values[i] - values[i - 1]) * f;
      }
    }
    return values.last;
  }

  double get _blink {
    if (!motion) return 0;
    return switch (pose.blink) {
      _Blink.normal => _keys(4.6, [0, .94, .97, 1], [0, 0, 1, 0]),
      _Blink.double => _keys(1.6, [0, .07, .14, .21, .28, 1], [0, 1, 0, 1, 0, 0]),
      _Blink.sleepy => _keys(3.4, [0, .7, .8, .9, 1], [0, 0, 1, 1, 0]),
    };
  }

  double get _flicker => motion ? _keys(0.7, [0, .5, 1], [1, .82, 1]) : 1;

  double get _glowAmount {
    final on = glow || pose.glow > 0.5;
    if (!on) return 0;
    return motion ? _keys(1.1, [0, .5, 1], [.15, .95, .15]) : 0.8;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200);
    _rotateAround(canvas, pose.tilt, 100, 150);

    _flame(canvas);
    _ellipse(canvas, 82, 200, 13, 6, _fill(const Color(0xFFE0962A)));
    _ellipse(canvas, 118, 200, 13, 6, _fill(const Color(0xFFE0962A)));
    _tuft(canvas, left: true);
    _tuft(canvas, left: false);

    // Body, head highlight, belly and the Nea Onnim mark.
    _ellipse(canvas, 100, 124, 78, 76, _fill(_caramel));
    _ellipse(canvas, 100, 66, 44, 14, _fill(const Color(0xFFDBA165), 0.6));
    _ellipse(canvas, 100, 162, 50, 38, _fill(_cream));
    canvas.drawPath(_p('M76 178 q5 5 10 0 M114 178 q5 5 10 0 M93 189 q7 5 14 0 M84 166 q4 4 8 0 M108 166 q4 4 8 0'),
        _stroke(const Color(0xFFE3C99A), 2.4));
    canvas.drawPath(
        _p('M100 147 V173 M100 153 C 90 146, 81 152, 85 160 C 88 166, 96 165, 96 159 M100 153 C 110 146, 119 152, 115 160 C 112 166, 104 165, 104 159'),
        _stroke(const Color(0xFF9A6634), 3));

    if (outfit == 'jersey') _jersey(canvas);
    if (outfit == 'tie') _tie(canvas);

    canvas.drawPath(
        _p('M100 72 C 76 50, 28 52, 28 94 C 28 130, 66 140, 100 128 C 134 140, 172 130, 172 94 C 172 52, 124 50, 100 72 Z'),
        _fill(_face));
    _ellipse(canvas, 44, 124, 10, 5.5, _fill(const Color(0xFFF2907E), pose.blush));
    _ellipse(canvas, 156, 124, 10, 5.5, _fill(const Color(0xFFF2907E), pose.blush));

    _eye(canvas, 70, right: false);
    _eye(canvas, 130, right: true);

    canvas.drawPath(_p('M91 105 Q100 98 109 105 L100 123 Z'), _fill(const Color(0xFFEBAA2A)));
    canvas.drawPath(_p('M95 104 Q100 101 104 104 L100 110 Z'), _fill(const Color(0xFFF7CF6B)));
    if (pose.beak > 0.01) {
      canvas.drawPath(_p('M93 116 Q100 134 107 116 L100 121 Z'), _fill(const Color(0xFFC4851A), pose.beak));
      canvas.drawPath(_p('M96 118 Q100 127 104 118 L100 121 Z'), _fill(const Color(0xFF8A2E1E), pose.beak));
    }

    if (outfit == 'glasses') {
      final s = _stroke(_ink, 4.5);
      canvas.drawCircle(const Offset(70, 94), 34, s);
      canvas.drawCircle(const Offset(130, 94), 34, s);
      canvas.drawPath(_p('M95 86 Q100 81 105 86 M36 90 L24 84 M164 90 L176 84'), s);
    }

    _wingDraw(canvas, left: true);
    _wingDraw(canvas, left: false);

    if (outfit == 'scarf') _scarf(canvas);
    if (outfit == 'headphones') _headphones(canvas);
    if (outfit == 'cap') _cap(canvas);

    if (pose.tear > 0.01) {
      canvas.drawPath(_p('M52 124 C 47 132, 45 137, 52 139 C 59 137, 57 132, 52 124 Z'), _fill(const Color(0xFF8CCBF0), pose.tear));
    }
    if (pose.z > 0.01) {
      _text(canvas, 'z', 160, 44, 20, pose.z);
      _text(canvas, 'Z', 174, 24, 28, pose.z);
    }
    canvas.restore();
  }

  void _flame(Canvas c) {
    final o = pose.flame * _flicker;
    if (o < 0.01) return;
    final orange = _fill(const Color(0xFFFF7A2F), o);
    final yellow = _fill(const Color(0xFFFFC53D), o);
    for (final d in [
      'M30 124 C 4 92, 24 60, 18 26 C 44 48, 52 72, 48 100 Z',
      'M170 124 C 196 92, 176 60, 182 26 C 156 48, 148 72, 152 100 Z',
      'M100 56 C 78 42, 86 14, 102 0 C 104 18, 126 28, 116 54 Z',
    ]) {
      c.drawPath(_p(d), orange);
    }
    for (final d in [
      'M34 112 C 20 92, 30 72, 28 52 C 42 66, 46 82, 44 100 Z',
      'M166 112 C 180 92, 170 72, 172 52 C 158 66, 154 82, 156 100 Z',
      'M101 52 C 90 42, 94 26, 102 16 C 104 28, 114 34, 110 50 Z',
    ]) {
      c.drawPath(_p(d), yellow);
    }
  }

  void _tuft(Canvas c, {required bool left}) {
    c.save();
    if (left) {
      _rotateAround(c, pose.tuft, 56, 64);
      c.drawPath(_p('M40 76 Q34 40 22 22 Q58 34 74 58 Z'), _fill(_wing));
      c.drawPath(_p('M44 66 Q40 46 32 34'), _stroke(_caramel, 3));
    } else {
      _rotateAround(c, -pose.tuft, 144, 64);
      c.drawPath(_p('M160 76 Q166 40 178 22 Q142 34 126 58 Z'), _fill(_wing));
      c.drawPath(_p('M156 66 Q160 46 168 34'), _stroke(_caramel, 3));
    }
    c.restore();
  }

  void _eye(Canvas c, double cx, {required bool right}) {
    c.save();
    c.translate(cx, 94);
    c.scale(pose.eye);

    final lash = right
        ? 'M13.1 28.1 L16.1 34.4 M21.9 21.9 L26.9 26.9 M28.1 13.1 L34.4 16.1'
        : 'M-13.1 28.1 L-16.1 34.4 M-21.9 21.9 L-26.9 26.9 M-28.1 13.1 L-34.4 16.1';
    c.drawPath(_p(lash), _stroke(_cream, 3));
    c.drawCircle(Offset.zero, 30.5, _fill(const Color(0xFF3E2618)));
    c.drawCircle(Offset.zero, 28, _fill(const Color(0xFFFFFDF7)));

    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 28)));

    // Pupil group follows the gaze.
    final lx = (pose.lx + lookX).clamp(-1.0, 1.0);
    final ly = (pose.ly + lookY).clamp(-1.0, 1.0);
    c.save();
    c.translate(lx * 7, ly * 7);
    final g = _glowAmount;
    if (g > 0) c.drawCircle(Offset.zero, 24, _stroke(iris, 5, g));
    c.drawCircle(Offset.zero, 19, _fill(iris));
    c.drawCircle(Offset.zero, 19, _stroke(Colors.black, 3, 0.2));
    c.drawCircle(Offset.zero, pose.pr, _fill(const Color(0xFF160E1C)));
    final stars = sparkle ? 1.0 : pose.stars;
    final hl = 1 - stars;
    if (hl > 0.01) {
      c.drawCircle(const Offset(-7, -8), 6, _fill(Colors.white, hl));
      c.drawCircle(const Offset(6, 6), 2.8, _fill(Colors.white, hl));
    }
    if (stars > 0.01) {
      const star = 'M0 -10 L2.4 -2.4 L10 0 L2.4 2.4 L0 10 L-2.4 2.4 L-10 0 L-2.4 -2.4 Z';
      c.save();
      c.translate(-6, -7);
      c.drawPath(_p(star), _fill(const Color(0xFFFFF6C4), stars));
      c.restore();
      c.save();
      c.translate(7, 7);
      c.scale(0.5);
      c.drawPath(_p(star), _fill(Colors.white, stars));
      c.restore();
    }
    c.restore();

    // Upper lid (mood), lower lid, then the blink sweeping down.
    if (pose.lid > 0.05) {
      c.save();
      c.rotate((right ? -pose.lidRot : pose.lidRot) * math.pi / 180);
      c.drawRect(Rect.fromLTWH(-34, -32, 68, pose.lid + 4), _fill(_lidC));
      c.restore();
    }
    _ellipse(c, 0, pose.low, 36, 20, _fill(_lidC));
    final b = _blink;
    if (b > 0.001) c.drawRect(Rect.fromLTWH(-34, -30, 68, 62 * b), _fill(_lidC));

    c.restore(); // clip
    c.restore(); // translate/scale
  }

  void _wingDraw(Canvas c, {required bool left}) {
    c.save();
    final path = left
        ? _p('M34 112 C 14 132, 16 172, 44 188 C 48 164, 50 136, 46 116 Z')
        : _p('M166 112 C 186 132, 184 172, 156 188 C 152 164, 150 136, 154 116 Z');
    if (left) {
      _rotateAround(c, pose.wl, 40, 116);
    } else {
      _rotateAround(c, pose.wr, 160, 116);
    }
    c.drawPath(path, _fill(_wing));
    c.clipPath(path);
    final x = left ? 8.0 : 142.0;
    c.drawRect(Rect.fromLTWH(x, 164, 50, 6), _fill(_gold));
    c.drawRect(Rect.fromLTWH(x, 170, 50, 3), _fill(_green));
    c.drawRect(Rect.fromLTWH(x, 173, 50, 5), _fill(_gold));
    c.drawRect(Rect.fromLTWH(x, 178, 50, 3), _fill(_red));
    c.drawRect(Rect.fromLTWH(x, 181, 50, 12), _fill(_gold));
    c.drawRect(Rect.fromLTWH(left ? 24 : 172, 164, 4, 30), _fill(_night));
    c.drawRect(Rect.fromLTWH(left ? 36 : 160, 164, 4, 30), _fill(_green));
    c.restore();
  }

  void _jersey(Canvas c) {
    c.drawPath(_p('M28 140 Q100 170 172 140 L178 180 Q100 218 22 180 Z'), _fill(_green));
    c.drawPath(_p('M30 152 Q100 182 170 152'), _stroke(_gold, 4));
    c.drawPath(_p('M84 152 L100 166 L116 152'), _stroke(Colors.white, 4));
    _text(c, '10', 100, 196, 24, 1, center: true, color: Colors.white);
  }

  void _tie(Canvas c) {
    c.drawPath(_p('M82 128 L100 146 L118 128 L114 122 L100 138 L86 122 Z'), _fill(Colors.white));
    c.drawPath(_p('M95 142 L105 142 L108 150 L104 184 L100 190 L96 184 L92 150 Z'), _fill(const Color(0xFF7A1F3D)));
    c.drawPath(_p('M93 160 L107 153 M93 172 L106 166'), _stroke(_gold, 2.5));
  }

  void _scarf(Canvas c) {
    c.drawPath(_p('M32 128 Q100 160 168 128 L170 142 Q100 174 30 142 Z'), _fill(_gold));
    c.drawPath(_p('M32 135 Q100 167 168 135'), _stroke(_green, 3));
    c.drawPath(_p('M44 128 L44 146 M66 136 L66 154 M134 136 L134 154 M156 128 L156 146'), _stroke(_red, 3));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(122, 146, 18, 40), const Radius.circular(4)), _fill(_gold));
    c.drawRect(const Rect.fromLTWH(122, 156, 18, 4), _fill(_green));
    c.drawRect(const Rect.fromLTWH(122, 166, 18, 4), _fill(_red));
    c.drawRect(const Rect.fromLTWH(129, 146, 3, 40), _fill(_night, 0.7));
  }

  void _headphones(Canvas c) {
    c.drawPath(_p('M30 98 C 28 30, 172 30, 170 98'), _stroke(_ink, 8));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(14, 80, 22, 38), const Radius.circular(10)), _fill(iris));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(164, 80, 22, 38), const Radius.circular(10)), _fill(iris));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, 88, 6, 22), const Radius.circular(3)), _fill(Colors.white, 0.5));
  }

  void _cap(Canvas c) {
    c.drawPath(_p('M72 54 L72 40 Q100 32 128 40 L128 54 Q100 62 72 54 Z'), _fill(const Color(0xFF232036)));
    c.drawPath(_p('M100 14 L152 32 L100 50 L48 32 Z'), _fill(const Color(0xFF2E2A45)));
    c.drawPath(_p('M100 32 L142 36 L142 60'), _stroke(_gold, 2.5));
    c.drawCircle(const Offset(142, 62), 4.5, _fill(_gold));
    c.drawCircle(const Offset(100, 32), 3, _fill(_gold));
  }

  void _text(Canvas c, String s, double x, double baseline, double size, double opacity,
      {bool center = false, Color color = const Color(0xFF7C8BB0)}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color.withValues(alpha: opacity.clamp(0.0, 1.0))),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? x - tp.width / 2 : x;
    final dy = baseline - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(c, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
