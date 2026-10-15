import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'eve/eve.dart';

/// The picture friends see when you share the fact of the day.
///
/// Same fixed 4:5 shape as [ShareScoreCard] (360x450 logical, 1080x1350 at
/// pixelRatio 3), so a shared fact and a shared score look like a pair. It is
/// laid out off-screen and captured, so the phone it was read on makes no
/// difference.
class ShareFactCard extends StatelessWidget {
  const ShareFactCard({
    super.key,
    required this.fact,
    required this.category,
    required this.label,
    required this.outfit,
    required this.iris,
    required this.accent,
  });

  static const double width = 360;
  static const double height = 450;

  final String fact;

  /// The fact's own category, e.g. 'nature' or 'bible'.
  final String category;

  /// 'FACT OF THE DAY' or 'BONUS FACT'.
  final String label;

  final String outfit;
  final Color iris;
  final Color accent;

  /// Long facts get smaller type rather than an ellipsis: every fact fits whole.
  double get _size {
    final n = fact.length;
    if (n <= 70) return 32;
    if (n <= 110) return 28;
    if (n <= 160) return 24;
    if (n <= 220) return 21;
    return 18;
  }

  static const _pastels = [Pastel.lime, Pastel.lav, Pastel.sky, Pastel.peach, Pastel.pink, Pastel.mint, Pastel.aqua];

  /// A steady colour per category, so Nature is always the same green.
  Color get _tag {
    var h = 0;
    for (final u in category.toLowerCase().codeUnits) {
      h = (h * 31 + u) & 0xffff;
    }
    return _pastels[h % _pastels.length];
  }

  @override
  Widget build(BuildContext context) {
    final title = category.isEmpty ? 'Did you know?' : category[0].toUpperCase() + category.substring(1);
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        // The light paper, fixed, so the card looks the same in dark mode.
        color: const Color(0xFFF4F2EC),
        child: Stack(children: [
          Positioned(
            left: -90,
            bottom: -110,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.5), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/icon/icon-512.png', width: 28, height: 28, excludeFromSemantics: true),
                ),
                const SizedBox(width: 8),
                Text('exam duel', style: T.disp(18, color: Pastel.ink)),
                const Spacer(),
                Text(label, style: T.micro(color: Pastel.ink)),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: _tag, borderRadius: BorderRadius.circular(999)),
                child: Text(title, style: T.body(13, w: FontWeight.w800, color: Pastel.ink)),
              ),
              const SizedBox(height: 16),
              Expanded(
                // Tiered sizing handles almost every fact; FittedBox catches
                // the rest, so a long one shrinks instead of being cut off.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width - 52,
                    child: Text(fact, style: T.disp(_size, color: Pastel.ink).copyWith(height: 1.22)),
                  ),
                ),
              ),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('A fact a day from Eve the owl', style: T.body(13, w: FontWeight.w700, color: Pastel.ink)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(color: Pastel.ink, borderRadius: BorderRadius.circular(999)),
                      child: Text('wogbe.github.io/exam-duel',
                          style: T.body(12, w: FontWeight.w800, color: const Color(0xFFF4F2EC))),
                    ),
                  ]),
                ),
                const SizedBox(width: 10),
                Eve(size: 104, iris: iris, mood: EveMood.surprised, outfit: outfit, motion: false),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
