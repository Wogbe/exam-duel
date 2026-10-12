import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/mastery.dart';
import 'common.dart';
import 'study_widgets.dart';
import 'view_settings.dart';

/// One topic on the learning map. Gold tiles shimmer; the hinted tile pulses.
class MasteryTile extends StatelessWidget {
  const MasteryTile({super.key, required this.name, required this.emoji, required this.mastery, this.hint = false, this.onTap});
  final String name, emoji;
  final Mastery mastery;
  final bool hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final ink = mastery.ink(c);
    Widget tile = Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: mastery.fill(c),
        borderRadius: BorderRadius.circular(20),
        border: mastery == Mastery.unseen ? Border.all(color: c.line, width: 1.5) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const Spacer(),
        LayoutBuilder(
          builder: (context, box) => Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _fitWords(name, T.disp(14.5, color: ink, w: FontWeight.w700).copyWith(height: 1.1), box.maxWidth, context),
          ),
        ),
        const SizedBox(height: 7),
        Row(children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < mastery.pips ? ink : ink.withValues(alpha: 0.18),
              ),
            ),
        ]),
      ]),
    );
    if (mastery == Mastery.ready) tile = _Shimmer(child: tile);
    if (hint) tile = _HintRing(child: tile);
    return Pressable(
      onTap: onTap,
      semanticLabel: '$name, ${mastery.label}',
      child: tile,
    );
  }
}

/// Shrinks [style] until the longest word fits on one line, so names never break mid-word.
TextStyle _fitWords(String text, TextStyle style, double width, BuildContext context) {
  final scaler = MediaQuery.textScalerOf(context);
  var s = style;
  for (final word in text.split(' ')) {
    while ((s.fontSize ?? 14) > 10) {
      final tp = TextPainter(text: TextSpan(text: word, style: s), textDirection: TextDirection.ltr, textScaler: scaler, maxLines: 1)
        ..layout();
      if (tp.width <= width) break;
      s = s.copyWith(fontSize: (s.fontSize ?? 14) - 0.5);
    }
  }
  return s;
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!context.motion) return child;
    return Ambient(
      period: const Duration(milliseconds: 2600),
      builder: (_, t) => Stack(children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-3 + 6 * t, -1),
                    end: Alignment(-1.6 + 6 * t, 1),
                    colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _HintRing extends StatelessWidget {
  const _HintRing({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Ambient(
        period: const Duration(milliseconds: 1800),
        builder: (context, t) {
          final p = context.motion ? math.sin(t * math.pi) : 0.6;
          return Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: context.c.ink.withValues(alpha: 0.25 + 0.6 * p), width: 2),
            ),
            child: child,
          );
        },
      );
}

