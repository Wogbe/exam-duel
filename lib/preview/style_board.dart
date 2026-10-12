import 'package:flutter/material.dart';

import '../screens/snap_screen.dart';
import '../theme/app_theme.dart';
import '../theme/mastery.dart';
import '../widgets/common.dart';
import '../widgets/eve/eve.dart';
import '../widgets/mastery_tile.dart';
import '../widgets/responsive.dart';
import '../widgets/study_widgets.dart';
import '../widgets/view_settings.dart';

/// One-page visual direction: colours, type, Eve, components and motion rules.
class StyleBoard extends StatelessWidget {
  const StyleBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final scope = ViewSettings.of(context);
    var i = 0;
    Duration d() => Duration(milliseconds: 80 * i++);

    return Scaffold(
      body: PageBody(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Row(children: [
              Expanded(child: Text('VISUAL DIRECTION · PREVIEW', style: mono(color: c.muted))),
              _Toggle(label: 'Dark', on: scope.dark, onTap: scope.toggleDark),
              const SizedBox(width: 8),
              _Toggle(label: 'Motion', on: scope.motionOn, onTap: scope.toggleMotion),
            ]),
            const SizedBox(height: 18),
            FadeRise(delay: d(), blur: true, child: Text('Exam Duel', style: T.disp(52, color: c.ink))),
            const SizedBox(height: 6),
            FadeRise(
              delay: d(),
              child: Text('Snap anything. See your map. Duel a friend.', style: T.body(17, color: c.muted)),
            ),
            const SizedBox(height: 22),
            FadeRise(delay: d(), child: const _HeroSample()),
            _Section('1 · Colour', delay: d(), children: [
              _Swatches(label: 'Base', colors: [(c.bg, 'Paper'), (c.surface, 'Card'), (c.ink, 'Ink')]),
              _Swatches(label: 'Pastels', colors: [for (final p in Pastel.all) (p, '')]),
              _Swatches(label: 'Mastery', colors: [for (final m in Mastery.values) (m.fill(c), m.label)]),
              _Swatches(label: 'Hot accent · live and urgent only', colors: [(Pastel.live, 'Live')]),
            ]),
            _Section('2 · Type', delay: d(), children: [
              Text('Turn anything into a duel', style: T.disp(30, color: c.ink)),
              const SizedBox(height: 4),
              Text('Urbanist · titles and numbers', style: mono(color: c.muted)),
              const SizedBox(height: 14),
              Text('Eve reads your notes, finds the topics and writes the questions.', style: T.body(16, color: c.ink)),
              const SizedBox(height: 4),
              Text('Figtree · everything you read', style: mono(color: c.muted)),
              const SizedBox(height: 14),
              Text('Q4 · CELL BIOLOGY · FROM YOUR NOTES', style: mono(size: 13, color: c.ink)),
              const SizedBox(height: 4),
              Text('DM Mono · small data labels', style: mono(color: c.muted)),
            ]),
            _Section('3 · Eve, your study buddy', delay: d(), children: [
              SizedBox(
                height: 118,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final (mood, label) in [
                      (EveMood.thinking, 'Thinking'),
                      (EveMood.happy, 'Right!'),
                      (EveMood.oops, 'Oops'),
                      (EveMood.cheering, 'You won'),
                      (EveMood.proud, 'Gold tile'),
                      (EveMood.fire, 'Streak'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Column(children: [
                          Eve(mood: mood, size: 84, iris: c.iris, motion: context.motion),
                          const SizedBox(height: 6),
                          Text(label, style: mono(color: c.muted)),
                        ]),
                      ),
                  ],
                ),
              ),
            ]),
            _Section('4 · Pieces', delay: d(), children: [
              Wrap(spacing: 8, runSpacing: 8, children: const [
                CapsPill('4-day streak', icon: Icons.local_fire_department_rounded),
                CapsPill('Live · Q4/10', bg: Colors.white, liveDot: true),
                CapsPill('New best · Mitosis'),
              ]),
              const SizedBox(height: 14),
              GoButton(label: 'Start duel', onTap: () {}),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: GhostButton(label: 'Practise solo', onTap: () {})),
                const SizedBox(width: 10),
                CircleIconButton(icon: Icons.ios_share_rounded, label: 'Share', fill: Pastel.lime, onTap: () {}),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                height: 112,
                child: Row(children: [
                  for (final (n, e, m) in [
                    ('Meiosis', '🔀', Mastery.unseen),
                    ('Mitosis', '🧬', Mastery.shaky),
                    ('DNA', '🧵', Mastery.solid),
                    ('Cells', '🔬', Mastery.ready),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: MasteryTile(name: n, emoji: e, mastery: m, onTap: () {}),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 14),
              FloatingNav(index: 0, onTap: (_) {}),
            ]),
            _Section('5 · Motion rules', delay: d(), children: [
              for (final rule in const [
                'Every tap answers back: a squish, a bounce, a buzz.',
                'AI waits feel like progress: Eve thinks, a checklist ticks, tiles shimmer into place.',
                'Things grow from where you tapped: a tile becomes the duel screen.',
                'Numbers count up, dots light up, bars grow.',
                'Big moments get a show: sunburst, Eve, confetti. Buttons wait until it ends.',
                'Motion off (or the phone\'s Reduce motion) swaps all of it for gentle fades.',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7, right: 10),
                      child: Container(width: 6, height: 6, decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle)),
                    ),
                    Expanded(child: Text(rule, style: T.body(15, color: c.ink))),
                  ]),
                ),
            ]),
            const SizedBox(height: 26),
            GoButton(label: 'Try the flow', onTap: () => Navigator.of(context).push(softRoute(const SnapScreen()))),
            const SizedBox(height: 12),
            Text(
              'Sample data only. AI, accounts and online duels come later.',
              textAlign: TextAlign.center,
              style: T.body(13, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSample extends StatelessWidget {
  const _HeroSample();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 200,
        child: GradientBlob(
          colors: const [Pastel.sky, Pastel.lav, Pastel.peach, Pastel.mint],
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SIGNATURE NUMBER', style: mono(color: Pastel.ink)),
              const Spacer(),
              const DotNumber(value: 62, semanticLabel: '62 percent ready'),
              const SizedBox(height: 8),
              Text('+5 since yesterday', style: T.body(14, w: FontWeight.w700, color: Pastel.ink)),
              const SizedBox(height: 6),
              const Ruler(value: 0.62),
            ]),
          ),
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.children, this.delay = Duration.zero});
  final String title;
  final List<Widget> children;
  final Duration delay;

  @override
  Widget build(BuildContext context) => FadeRise(
        delay: delay,
        child: Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: context.c.surface, borderRadius: BorderRadius.circular(26)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: T.disp(20, color: context.c.ink)),
            const SizedBox(height: 14),
            ...children,
          ]),
        ),
      );
}

class _Swatches extends StatelessWidget {
  const _Swatches({required this.label, required this.colors});
  final String label;
  final List<(Color, String)> colors;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: mono(color: c.muted)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (col, name) in colors)
            Column(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.line)),
              ),
              if (name.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(name, style: T.body(11.5, w: FontWeight.w600, color: c.muted)),
              ],
            ]),
        ]),
      ]),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label ${on ? 'on' : 'off'}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: on ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.line),
        ),
        child: Center(
          child: Text('$label ${on ? 'on' : 'off'}', style: T.body(13, w: FontWeight.w700, color: on ? c.onPrimary : c.ink)),
        ),
      ),
    );
  }
}
