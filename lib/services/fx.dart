import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The game's sound effects. Files live in `assets/sounds/<name>.wav`.
enum Sfx { tap, tick, correct, wrong, pop, coin, whoosh, streak, win, lose, badge, go }

/// Sound effects and haptics in one place.
///
/// Nothing plays until [init] runs (only `main()` calls it), so widget tests
/// stay silent. Every call is fire-and-forget and never throws: a missing
/// audio device must never break a game.
class Fx {
  Fx._();

  static bool _ready = false;
  static bool _sound = true;
  static bool _haptics = true;
  static final Map<Sfx, AudioPlayer> _players = {};

  static bool get haptics => _haptics;
  static bool get sound => _sound;

  static const _iosCategory = AVAudioSessionCategory.ambient;
  static const _androidFocus = AndroidAudioFocus.none;

  static const _volume = {
    Sfx.tap: 0.25,
    Sfx.tick: 0.55,
    Sfx.correct: 0.8,
    Sfx.wrong: 0.6,
    Sfx.pop: 0.6,
    Sfx.coin: 0.7,
    Sfx.whoosh: 0.5,
    Sfx.streak: 0.8,
    Sfx.win: 0.85,
    Sfx.lose: 0.6,
    Sfx.badge: 0.85,
    Sfx.go: 0.7,
  };

  /// Turns effects on. Sounds mix with the user's music instead of pausing it,
  /// and respect the iPhone silent switch.
  static Future<void> init({required bool sound, required bool haptics}) async {
    _ready = true;
    update(sound: sound, haptics: haptics);
    try {
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          audioFocus: _androidFocus,
          usageType: AndroidUsageType.game,
          contentType: AndroidContentType.sonification,
        ),
        iOS: AudioContextIOS(category: _iosCategory),
      ));
    } catch (_) {
      // Older devices or browsers: default context is fine.
    }
  }

  static void update({required bool sound, required bool haptics}) {
    _sound = sound;
    _haptics = haptics;
  }

  /// Plays a sound if sounds are on.
  static void play(Sfx s) {
    if (!_ready || !_sound) return;
    unawaited(_play(s));
  }

  static Future<void> _play(Sfx s) async {
    try {
      var p = _players[s];
      if (p == null) {
        p = AudioPlayer(playerId: 'sfx_${s.name}');
        _players[s] = p;
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          await p.setPlayerMode(PlayerMode.lowLatency);
        }
      }
      await p.stop();
      await p.play(AssetSource('sounds/${s.name}.wav'), volume: _volume[s] ?? 0.7);
    } catch (_) {
      // Ignore: a sound is never worth an error.
    }
  }

  /// A haptic pulse if haptics are on.
  static void buzz({bool heavy = false}) {
    if (!_haptics) return;
    heavy ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
  }

  // ---- common moments ----
  static void correct() {
    play(Sfx.correct);
    buzz(heavy: true);
  }

  static void wrong() {
    play(Sfx.wrong);
    if (_haptics) HapticFeedback.heavyImpact();
  }

  static void countdown() {
    play(Sfx.tick);
    buzz();
  }

  static void reward() {
    play(Sfx.coin);
    buzz();
  }

  static void celebrate({bool won = true}) {
    play(won ? Sfx.win : Sfx.lose);
    buzz(heavy: true);
  }
}
