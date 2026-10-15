import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../services/share.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/eve/eve.dart';
import '../widgets/responsive.dart';

/// Version, credits and the licences the question bank depends on.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  /// Kept in step with `version:` in pubspec.yaml by hand.
  static const version = '0.2.4';

  Future<void> _open(BuildContext context, String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) showToast(context, 'Could not open $url');
    } catch (_) {
      if (context.mounted) showToast(context, 'Could not open $url');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    return Scaffold(
      body: PageBody(
        maxWidth: 680,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(children: [
              CircleIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: 12),
              Expanded(child: Text('About', style: T.disp(28, color: c.ink))),
            ]),
            const SizedBox(height: 20),
            Center(
              child: Eve(
                size: 150,
                iris: c.iris,
                mood: EveMood.happy,
                outfit: store.outfit,
                motion: !store.reduceMotion,
                bob: true,
              ),
            ),
            const SizedBox(height: 14),
            Center(child: Text('exam duel', style: T.disp(34, color: c.ink))),
            const SizedBox(height: 4),
            Center(child: Text('Version $version', style: T.body(14, color: c.muted))),
            const SizedBox(height: 4),
            Center(
              child: Text(
                AppConfig.onlineEnabled ? 'Online rooms are on' : 'Offline mode: solo play and facts only',
                style: T.body(13, color: c.muted),
              ),
            ),
            const SizedBox(height: 26),
            _card(c, 'MADE BY', [
              _line(c, 'Built by McTech. Eve the owl is drawn in code, not an image.'),
            ]),
            const SizedBox(height: 12),
            _card(c, 'QUESTIONS', [
              _line(c, 'Hand-checked questions, plus questions from the Open Trivia Database.'),
              _line(c, 'Open Trivia DB content is shared under CC BY-SA 4.0.'),
              const SizedBox(height: 10),
              GhostButton(
                label: 'opentdb.com',
                icon: Icons.open_in_new_rounded,
                onTap: () => _open(context, 'https://opentdb.com'),
              ),
            ]),
            const SizedBox(height: 12),
            _card(c, 'SHARE THE APP', [
              _line(c, 'Anyone can play in a browser, no account needed.'),
              const SizedBox(height: 10),
              GoButton(
                label: 'Share Exam Duel',
                icon: Icons.ios_share_rounded,
                onTap: () => shareText(context, 'Come play Exam Duel with me. Trivia with friends, free: $appLink'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _card(AppColors c, String title, List<Widget> children) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(26)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: T.micro(color: c.muted)),
          const SizedBox(height: 10),
          ...children,
        ]),
      );

  Widget _line(AppColors c, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: T.body(14, color: c.ink, height: 1.35)),
      );
}
