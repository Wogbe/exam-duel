import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/eve/eve.dart';
import '../widgets/responsive.dart';
import 'proto_data.dart';
import 'proto_kit.dart';
import 'snap_screen.dart';
import 'topic_screen.dart';

/// Step 2: the learning map. Tiles are topics, coloured by mastery.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key, required this.set, this.fresh = false});
  final StudySet set;

  /// True when arriving from the thinking sequence: tiles drop in.
  final bool fresh;

  void _openTopic(BuildContext context, int i) {
    tick(true);
    Navigator.of(context).push(_heroRoute(TopicScreen(set: set, index: i)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListenableBuilder(listenable: progress, builder: (context, _) => _page(context, c));
  }

  /// Eve's nudge. Only a button while there is something shaky to practise.
  Widget _eve(BuildContext context, int? suggested) {
    final row = Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Eve(mood: suggested == null ? EveMood.proud : EveMood.happy, size: 70, iris: context.c.iris, motion: context.motion),
      const SizedBox(width: 8),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Bubble(suggested == null
              ? 'Nothing is shaky. Tap any tile to keep it Ready.'
              : '${set.topics[suggested].name} is shaky. Challenge a friend on it? ⚔️'),
        ),
      ),
    ]);
    if (suggested == null) return row;
    return Pressable(
      onTap: () => _openTopic(context, suggested),
      semanticLabel: '${set.topics[suggested].name} is shaky. Challenge a friend on it.',
      child: row,
    );
  }

  Widget _page(BuildContext context, AppColors c) {
    final suggested = progress.suggest(set);
    final readiness = progress.readiness(set);
    return Scaffold(
      body: PageBody(
        maxWidth: 520,
        child: Stack(children: [
          ListView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 110 + MediaQuery.paddingOf(context).bottom),
            children: [
              Row(children: [
                CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Back',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('YOUR MAP', style: mono(color: c.muted)),
                    const SizedBox(height: 2),
                    Text(set.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.disp(26, color: c.ink)),
                  ]),
                ),
                const ProtoPill('$sampleStreak', icon: Icons.local_fire_department_rounded),
              ]),
              if (fresh && !progress.hasGains) ...[
                const SizedBox(height: 12),
                FadeRise(
                  child: Text(
                    'Sample: how your map looks after a week of practice.',
                    style: T.body(13, w: FontWeight.w600, color: c.muted),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FadeRise(
                delay: const Duration(milliseconds: 60),
                child: SizedBox(
                  height: 196,
                  child: GradientBlob(
                    colors: const [Pastel.sky, Pastel.lav, Pastel.peach, Pastel.mint],
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text('READY FOR YOUR TEST', style: mono(color: Pastel.ink)),
                          const Spacer(),
                          Text('${set.topics.length} TOPICS', style: mono(color: Pastel.ink)),
                        ]),
                        const Spacer(),
                        DotNumber(value: readiness, semanticLabel: '$readiness percent ready'),
                        const SizedBox(height: 8),
                        Text('+${progress.delta(set)} since yesterday', style: T.body(14, w: FontWeight.w700, color: Pastel.ink)),
                        const SizedBox(height: 4),
                        Ruler(value: readiness / 100),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeRise(delay: const Duration(milliseconds: 160), child: _eve(context, suggested)),
              const SizedBox(height: 14),
              Wrap(spacing: 12, runSpacing: 6, children: [
                for (final m in Mastery.values)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: m.fill(c),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: c.line),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(m.label, style: T.body(13, w: FontWeight.w600, color: c.muted)),
                  ]),
              ]),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.92,
                ),
                itemCount: set.topics.length,
                itemBuilder: (context, i) {
                  final t = set.topics[i];
                  return PopIn(
                    enabled: context.motion,
                    delay: Duration(milliseconds: (fresh ? 260 : 200) + 45 * i),
                    child: Hero(
                      tag: 'tile-${set.id}-$i',
                      child: Material(
                        type: MaterialType.transparency,
                        child: MasteryTile(
                          name: t.name,
                          emoji: t.emoji,
                          mastery: progress.mastery(set, i),
                          hint: i == suggested,
                          onTap: () => _openTopic(context, i),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: SafeArea(
              top: false,
              child: FloatingNav(
                index: 0,
                onTap: (i) {
                  if (i == 2) {
                    Navigator.of(context).push(softRoute(const SnapScreen()));
                  } else if (i != 0) {
                    showToast(context, 'Not in this preview yet');
                  }
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Route with a gentle fade so the Hero tile flight is the star.
Route<R> _heroRoute<R>(Widget page) => PageRouteBuilder<R>(
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
    );
