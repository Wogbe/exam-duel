import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/photo_picker.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import '../widgets/eve/eve.dart';
import 'fact_screen.dart';

/// Two steps: meet Eve, then pick a name, avatar colour and accent.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final _name = TextEditingController();
  int _avatar = 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final store = ref.read(playerStoreProvider);
    await store.setProfile(_name.text, _avatar);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(softRoute(const FactScreen(firstOpen: true)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final motion = !store.reduceMotion;
    return Scaffold(
      body: PageBody(maxWidth: 600,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              for (var i = 0; i < 2; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.only(right: i == 0 ? 6 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= _step ? c.ink : c.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
            ]),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: _step == 0 ? _welcome(c, store.outfit, motion) : _profile(c, motion),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _welcome(AppColors c, String outfit, bool motion) => FillScroll(
        key: const ValueKey(0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(child: Eve(size: 220, iris: c.iris, mood: EveMood.cheering, outfit: outfit, motion: motion, bob: true)),
          const SizedBox(height: 28),
          Text('Akwaaba!\nI’m Eve.', style: T.disp(52, color: c.ink)),
          const SizedBox(height: 14),
          Text(
            'Host trivia nights with your friends, keep a daily streak, and learn one wild fact every day.',
            style: T.body(17, color: c.muted),
          ),
          const Spacer(),
          GoButton(label: 'Let’s go', onTap: () => setState(() => _step = 1)),
        ],
      ),
      );

  Widget _profile(AppColors c, bool motion) {
    final store = ref.watch(playerStoreProvider);
    final name = _name.text.trim();
    return ListView(
      key: const ValueKey(1),
      padding: const EdgeInsets.only(top: 24),
      children: [
        Row(children: [
          Expanded(child: Text('What should\nfriends call you?', style: T.disp(34, color: c.ink))),
          Eve(size: 90, iris: c.iris, mood: name.isEmpty ? EveMood.thinking : EveMood.happy, motion: motion),
        ]),
        const SizedBox(height: 24),
        Text('NICKNAME', style: T.micro(color: c.muted)),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          style: T.body(17, color: c.ink),
          decoration: InputDecoration(
            hintText: 'e.g. Kofi',
            counterText: '',
            filled: true,
            fillColor: c.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c.line, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c.ink, width: 1.5)),
          ),
        ),
        const SizedBox(height: 24),
        Text('YOUR COLOUR', style: T.micro(color: c.muted)),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (var i = 0; i < Pastel.all.length; i++)
            Pressable(
              onTap: () => setState(() => _avatar = i),
              semanticLabel: 'Colour ${i + 1}${i == _avatar ? ', selected' : ''}',
              child: AnimatedScale(
                scale: i == _avatar ? 1.12 : 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Avatar(
                  initial: name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                  index: i,
                  size: 56,
                  ring: i == _avatar ? c.ink : null,
                  photo: i == _avatar ? store.photo : null,
                ),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        GhostButton(
          label: store.hasPhoto ? 'Change photo' : 'Add a photo (optional)',
          icon: Icons.add_a_photo_rounded,
          onTap: () => editPhoto(context, store),
        ),
        const SizedBox(height: 24),
        Text('EVE’S EYES', style: T.micro(color: c.muted)),
        const SizedBox(height: 12),
        Row(children: [
          for (final a in AccentChoice.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Pressable(
                  onTap: () => store.setAccent(a),
                  semanticLabel: '${a.name}${a.id == store.accent.id ? ', selected' : ''}',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: a.acc,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: a.id == store.accent.id ? c.ink : Colors.transparent, width: 2.5),
                    ),
                    child: Text(a.name, style: T.disp(17, color: Pastel.ink)),
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 36),
        GoButton(label: 'Start playing', onTap: name.isEmpty ? null : _finish),
      ],
    );
  }
}
