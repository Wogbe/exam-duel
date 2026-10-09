import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/player_store.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import '../widgets/eve/eve.dart';
import 'home_screen.dart';
import 'streak_screen.dart';

/// Fact of the Day: tap the card to flip it. Reading it keeps the streak.
class FactScreen extends ConsumerStatefulWidget {
  const FactScreen({super.key, this.firstOpen = false});
  final bool firstOpen;

  @override
  ConsumerState<FactScreen> createState() => _FactScreenState();
}

class _FactScreenState extends ConsumerState<FactScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  bool _flipped = false;
  String? _reaction;

  @override
  void initState() {
    super.initState();
    if (!widget.firstOpen) {
      _flipped = true;
      _flip.value = 1;
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _doFlip() {
    if (_flipped) return;
    final store = ref.read(playerStoreProvider);
    tick(store.haptics);
    setState(() => _flipped = true);
    if (store.reduceMotion) {
      _flip.value = 1;
    } else {
      _flip.forward();
    }
  }

  Future<void> _continue() async {
    final store = ref.read(playerStoreProvider);
    await store.markFactSeen();
    final event = await store.markActive();
    if (!mounted) return;
    if (!widget.firstOpen) {
      Navigator.of(context).pop();
      return;
    }
    final Widget next = switch (event) {
      StreakEvent.started || StreakEvent.extended || StreakEvent.savedByFreeze || StreakEvent.reset =>
        StreakScreen(event: event),
      StreakEvent.none => const HomeScreen(),
    };
    Navigator.of(context).pushReplacement(softRoute(next));
  }

  void _share(String text) {
    final msg = Uri.encodeComponent('Did you know? $text\n\n— Fact of the Day from Eve, Exam Duel');
    launchUrl(Uri.parse('https://wa.me/?text=$msg'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final fact = ref.watch(localBankProvider).factFor(DateTime.now());
    final motion = !store.reduceMotion;
    final mood = !_flipped
        ? EveMood.idle
        : _reaction == 'blown'
            ? EveMood.cheering
            : _reaction == 'knew'
                ? EveMood.proud
                : EveMood.surprised;

    return Scaffold(
      body: PageBody(maxWidth: 680,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              if (!widget.firstOpen)
                CircleIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
              const Spacer(),
              Text('FACT OF THE DAY', style: T.micro(color: c.muted)),
              const Spacer(),
              if (!widget.firstOpen) const SizedBox(width: 48),
            ]),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Bubble(_flipped ? (_reaction == null ? 'Wait… you HAVE to see this.' : 'Told you! Share it?') : 'Tap the card. Go on.'),
                ),
              ),
              Eve(size: 120, iris: c.iris, mood: mood, outfit: store.outfit, motion: motion, sparkle: _reaction == 'blown'),
            ]),
            const SizedBox(height: 8),
            Expanded(
              child: GestureDetector(
                onTap: _doFlip,
                child: AnimatedBuilder(
                  animation: _flip,
                  builder: (_, __) {
                    final t = Curves.easeOutBack.transform(_flip.value).clamp(0.0, 1.2);
                    final angle = t * math.pi;
                    final showBack = angle > math.pi / 2;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(angle),
                      child: showBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _back(c, fact.text, fact.category),
                            )
                          : _front(c),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: _flipped ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_flipped,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    _react(c, 'knew', 'Knew it', Icons.check_rounded, Pastel.mint),
                    const SizedBox(width: 10),
                    _react(c, 'blown', 'Mind blown', Icons.auto_awesome_rounded, Pastel.peach),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    CircleIconButton(icon: Icons.share_rounded, label: 'Share on WhatsApp', onTap: () => _share(fact.text)),
                    const SizedBox(width: 10),
                    Expanded(child: GoButton(label: widget.firstOpen ? 'Keep my streak' : 'Done', onTap: _continue)),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _front(AppColors c) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: Pastel.lav, borderRadius: BorderRadius.circular(32)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Tag('Did you know?'),
          const Spacer(),
          Text('Today’s fact is\nwaiting.', style: T.disp(40, color: Pastel.ink)),
          const SizedBox(height: 12),
          Row(children: [
            Text('Tap to reveal', style: T.body(16, w: FontWeight.w600, color: Pastel.ink)),
            const SizedBox(width: 6),
            const Icon(Icons.touch_app_rounded, color: Pastel.ink, size: 20),
          ]),
        ]),
      );

  Widget _back(AppColors c, String text, String category) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(32)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Tag(category[0].toUpperCase() + category.substring(1), color: c.accSoft, dark: true),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(child: Text(text, style: T.disp(30, color: c.ink, w: FontWeight.w600).copyWith(height: 1.15))),
          ),
        ]),
      );

  Widget _react(AppColors c, String id, String label, IconData icon, Color bg) => Expanded(
        child: Pressable(
          onTap: () {
            tick(ref.read(playerStoreProvider).haptics);
            setState(() => _reaction = id);
          },
          semanticLabel: label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 64,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _reaction == id ? c.ink : Colors.transparent, width: 2.5),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: Pastel.ink, size: 20),
              const SizedBox(width: 8),
              Text(label, style: T.disp(17, color: Pastel.ink)),
            ]),
          ),
        ),
      );
}
