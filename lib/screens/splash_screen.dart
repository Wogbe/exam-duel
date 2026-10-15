import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/deep_link.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/eve/eve.dart';
import 'fact_screen.dart';
import 'home_screen.dart';
import 'join_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1300), _go);
  }

  void _go() {
    if (!mounted) return;
    final store = ref.read(playerStoreProvider);
    // Opened from a friend's link: straight to the room, Home underneath.
    final code = store.onboarded ? takeLinkCode() : null;
    if (code != null) {
      Navigator.of(context).pushReplacement(softRoute(const HomeScreen()));
      Navigator.of(context).push(softRoute(JoinScreen(initialCode: code)));
      return;
    }
    final Widget next = !store.onboarded
        ? const OnboardingScreen()
        : store.factSeenToday
            ? const HomeScreen()
            : const FactScreen(firstOpen: true);
    Navigator.of(context).pushReplacement(softRoute(next));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    return Scaffold(
      backgroundColor: c.acc,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          PopIn(
            enabled: !store.reduceMotion,
            child: Eve(size: 200, iris: c.iris, mood: EveMood.happy, outfit: store.outfit, motion: !store.reduceMotion, bob: true),
          ),
          const SizedBox(height: 24),
          PopIn(
            delay: const Duration(milliseconds: 250),
            enabled: !store.reduceMotion,
            child: Text('exam duel', style: T.disp(44, color: Pastel.ink)),
          ),
          const SizedBox(height: 8),
          Text('Trivia with friends, hosted by Eve', style: T.body(15, color: Pastel.ink)),
        ]),
      ),
    );
  }
}
