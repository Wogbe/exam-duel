import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Width at which screens switch from the phone layout to the web/desktop layout.
const kWideBreakpoint = 900.0;

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= kWideBreakpoint;

/// Centres [child] and caps its width, so forms and single-column screens
/// read well on a big browser window. On phones it does nothing.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 640});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// Keys 1–4 and A–D pick answers 0–3 (desktop/web).
class AnswerKeys extends StatelessWidget {
  const AnswerKeys({super.key, required this.onPick, required this.child});
  final void Function(int index)? onPick;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pick = onPick;
    if (pick == null) return child;
    const digits = [LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4];
    const letters = [LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyD];
    return CallbackShortcuts(
      bindings: {
        for (var i = 0; i < 4; i++) SingleActivator(digits[i]): () => pick(i),
        for (var i = 0; i < 4; i++) SingleActivator(letters[i]): () => pick(i),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}

/// SafeArea + centred, width-capped content. Drop-in for `SafeArea(child: …)`.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 640});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => SafeArea(child: ContentWidth(maxWidth: maxWidth, child: child));
}
