import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Light haptic tick, respecting the user's setting.
void tick(bool enabled, {bool heavy = false}) {
  if (!enabled) return;
  heavy ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
}

/// Springy press: shrinks on touch, bounces back with overshoot.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.94, this.semanticLabel});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          // Mouse hover lifts slightly; touch press squashes.
          scale: _down ? widget.scale : (_hover && enabled ? 1.02 : 1),
          duration: Duration(milliseconds: _down ? 80 : (_hover ? 200 : 520)),
          curve: _down ? Curves.easeOut : (_hover ? Curves.easeOutBack : Curves.elasticOut),
          child: Opacity(opacity: enabled ? 1 : 0.4, child: widget.child),
        ),
      ),
      ),
    );
  }
}

/// Black pill button with the accent "go" circle, as in the design.
class GoButton extends StatelessWidget {
  const GoButton({super.key, required this.label, this.onTap, this.busy = false, this.icon = Icons.arrow_forward_rounded});
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: busy ? null : onTap,
      semanticLabel: label,
      child: Container(
        height: 58,
        padding: const EdgeInsets.only(left: 26, right: 7),
        decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            Expanded(child: Text(label, style: T.disp(18, color: c.onPrimary))),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: c.acc, shape: BoxShape.circle),
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Pastel.ink),
                    )
                  : Transform.rotate(angle: -math.pi / 4, child: Icon(icon, color: Pastel.ink, size: 22)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Outlined secondary button.
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, this.onTap, this.icon});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 58,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.line, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 20, color: c.ink), const SizedBox(width: 8)],
            Text(label, style: T.disp(17, color: c.ink)),
          ],
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.icon, required this.label, this.onTap, this.fill});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: onTap,
      scale: 0.88,
      semanticLabel: label,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: fill ?? c.surface,
          shape: BoxShape.circle,
          border: fill == null ? Border.all(color: c.line, width: 1.5) : null,
        ),
        child: Icon(icon, size: 22, color: fill == null ? c.ink : Pastel.ink),
      ),
    );
  }
}

/// Small rounded label.
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.dark = false, this.color});
  final String text;
  final bool dark;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color ?? Pastel.ink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text, style: T.body(12, w: FontWeight.w600, color: dark ? context.c.ink : Pastel.ink)),
      );
}

/// Pill with an icon and a value (streak, coins).
class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.icon, required this.value, this.iconColor, this.label});
  final IconData icon;
  final String value;
  final Color? iconColor;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      label: label,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: iconColor ?? c.ink),
          const SizedBox(width: 6),
          Text(value, style: T.disp(16, color: c.ink)),
        ]),
      ),
    );
  }
}

/// Speech bubble for Eve's lines.
class Bubble extends StatelessWidget {
  const Bubble(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, a) => ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: a, child: child),
      ),
      child: Container(
        key: ValueKey(text),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(18)),
        child: Text(text, style: T.body(14, w: FontWeight.w600, color: c.onPrimary, height: 1.25)),
      ),
    );
  }
}

/// Player avatar: pastel circle with an initial.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.initial, required this.index, this.size = 40, this.ring});
  final String initial;
  final int index;
  final double size;
  final Color? ring;

  static Color colorFor(int i) => Pastel.all[i % Pastel.all.length];

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorFor(index),
          shape: BoxShape.circle,
          border: ring == null ? null : Border.all(color: ring!, width: 2.5),
        ),
        child: Text(initial, style: T.disp(size * 0.42, color: Pastel.ink)),
      );
}

/// Progress bar; `striped` paints the game's pastel colour stripe.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.striped = false, this.height = 8, this.color, this.track});
  final double value;
  final bool striped;
  final double height;
  final Color? color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: height,
        child: Stack(fit: StackFit.expand, children: [
          ColoredBox(color: track ?? c.ink.withValues(alpha: 0.1)),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: striped
                ? CustomPaint(painter: _StripePainter(), size: Size.infinite)
                : DecoratedBox(
                    decoration: BoxDecoration(color: color ?? c.ink, borderRadius: BorderRadius.circular(99)),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const band = 12.0;
    var x = 0.0;
    var i = 0;
    while (x < size.width) {
      canvas.drawRect(Rect.fromLTWH(x, 0, band, size.height), Paint()..color = Pastel.stripe[i % Pastel.stripe.length]);
      x += band;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Countdown ring around a number.
class TimerRing extends StatelessWidget {
  const TimerRing({super.key, required this.fraction, required this.seconds, this.size = 64});
  final double fraction;
  final int seconds;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final warn = fraction < 0.3;
    return Semantics(
      label: '$seconds seconds left',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(fraction, c.line, warn ? Pastel.coral : c.ink),
          ),
          AnimatedScale(
            scale: warn ? 1.12 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: Text('$seconds', style: T.disp(size * 0.36, color: warn ? Pastel.coral : c.ink)),
          ),
        ]),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.f, this.track, this.fg);
  final double f;
  final Color track, fg;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 4;
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      2 * math.pi * f,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.f != f || old.fg != fg;
}

/// Numbers that count up (XP, coins, scores).
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.style, this.prefix = '', this.duration = const Duration(milliseconds: 900)});
  final int value;
  final TextStyle style;
  final String prefix;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Text('$prefix${v.round()}', style: style),
      );
}

/// Pops a child in with a springy scale + rise, after an optional delay.
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero, this.enabled = true});
  final Widget child;
  final Duration delay;
  final bool enabled;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _c.value = 1;
    } else {
      Future.delayed(widget.delay, () {
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
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = Curves.easeOutBack.transform(_c.value);
          return Opacity(
            opacity: _c.value.clamp(0.0, 1.0),
            child: Transform.translate(offset: Offset(0, 30 * (1 - t)), child: Transform.scale(scale: 0.6 + 0.4 * t, child: child)),
          );
        },
        child: widget.child,
      );
}

/// Shake animation for wrong answers. Change [trigger] to replay.
class Shake extends StatelessWidget {
  const Shake({super.key, required this.trigger, required this.child, this.enabled = true});
  final Object trigger;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (_, t, c) => Transform.translate(offset: Offset(math.sin(t * math.pi * 6) * 8 * (1 - t), 0), child: c),
      child: child,
    );
  }
}

/// Confetti burst, drawn with a painter (no extra packages).
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.count = 70});
  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();
  late final List<_Bit> _bits;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _bits = List.generate(widget.count, (i) {
      final angle = -math.pi / 2 + (r.nextDouble() - 0.5) * 2.2;
      final speed = 380 + r.nextDouble() * 520;
      return _Bit(
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        spin: (r.nextDouble() - 0.5) * 14,
        color: [...Pastel.all, Pastel.coin, Pastel.ink][i % (Pastel.all.length + 2)],
        w: 6 + r.nextDouble() * 6,
        h: 10 + r.nextDouble() * 8,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_bits, _c.value * 2.6), size: Size.infinite),
        ),
      );
}

class _Bit {
  final double vx, vy, spin, w, h;
  final Color color;
  _Bit({required this.vx, required this.vy, required this.spin, required this.color, required this.w, required this.h});
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.bits, this.t);
  final List<_Bit> bits;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.45);
    final fade = (1 - (t - 1.8).clamp(0.0, 0.8) / 0.8);
    for (final b in bits) {
      final x = origin.dx + b.vx * t * 0.8;
      final y = origin.dy + b.vy * t + 0.5 * 900 * t * t;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(b.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: b.w, height: b.h), const Radius.circular(2)),
        Paint()..color = b.color.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Floating "+120" that rises and fades.
class FloatUp extends StatelessWidget {
  const FloatUp({super.key, required this.text, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: ValueKey(text),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (_, t, child) => Opacity(
          opacity: (1 - t).clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, -50 * t), child: child),
        ),
        child: Text(text, style: T.disp(28, color: color ?? context.c.ink)),
      );
}

/// Snackbar-style toast in the design's dark pill.
void showToast(BuildContext context, String message) {
  final c = context.c;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, textAlign: TextAlign.center, style: T.body(15, w: FontWeight.w600, color: c.onPrimary)),
      backgroundColor: c.primary,
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      elevation: 0,
      duration: const Duration(milliseconds: 2400),
    ));
}

/// Page transition: fade + slight rise, like `.screen` in the design.
Route<T> softRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) {
        final curved = CurvedAnimation(parent: a, curve: const Cubic(.2, .8, .2, 1));
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );

/// Fills the screen like a Column with Spacers, but scrolls on short
/// screens instead of overflowing. [child] is usually a Column.
class FillScroll extends StatelessWidget {
  const FillScroll({super.key, required this.child, this.padding = EdgeInsets.zero});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: (box.maxHeight - padding.vertical).clamp(0.0, double.infinity)),
            child: IntrinsicHeight(child: child),
          ),
        ),
      );
}
