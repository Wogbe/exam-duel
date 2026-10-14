import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import '../data/player_store.dart';
import '../services/fx.dart';
import '../services/share.dart';
import '../state/providers.dart';
import '../state/room_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/badges.dart';
import '../widgets/common.dart';
import '../widgets/eve/eve.dart';
import '../widgets/responsive.dart';

const _emotes = ['👏 Nice!', '😮 Whoa!', '😅 So close!', '😎 Too easy', '🔥 On fire', '🤝 GG'];

/// One online room: lobby → live questions → results → rematch.
/// Owns the [RoomController] and switches views by room status.
class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key, required this.controller});
  final RoomController controller;

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  RoomController get ctrl => widget.controller;
  final Set<String> _rewarded = {};
  RoomStatus? _lastStatus;
  int _lastIdx = -1;
  bool _wasRevealed = false;
  int _lastSecond = -1;
  bool _toldAboutName = false;

  @override
  void initState() {
    super.initState();
    ctrl.addListener(_onChange);
    final photo = ref.read(playerStoreProvider).photoBase64;
    // Big photos stay on this phone only (the server caps photos at 300 KB of text).
    if (photo != null && photo.length <= 300000) ctrl.sharePhoto(photo);
  }

  @override
  void dispose() {
    ctrl.removeListener(_onChange);
    ctrl.dispose();
    super.dispose();
  }

  void _onChange() {
    final store = ref.read(playerStoreProvider);
    if (ctrl.closed && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }
    _checkMyName(store);
    final r = ctrl.room;
    // Haptics on phase changes.
    if (r.status != _lastStatus || r.currentIndex != _lastIdx) {
      if (r.status == RoomStatus.question) {
        tick(store.haptics);
        Fx.play(Sfx.whoosh);
      }
      _wasRevealed = false;
      _lastSecond = -1;
    }
    // Countdown ticks for the last 3 seconds, until you answer.
    if (r.status == RoomStatus.question && ctrl.myChoice == null && ctrl.question != null) {
      final sec = ctrl.secondsLeft;
      if (sec != _lastSecond) {
        _lastSecond = sec;
        if (sec >= 1 && sec <= 3) Fx.countdown();
      }
    }
    if (r.status == RoomStatus.reveal && ctrl.question?.answer != null && !_wasRevealed) {
      _wasRevealed = true;
      final res = ctrl.myResult;
      if (ctrl.myChoice == null) {
        Fx.play(Sfx.pop); // didn't answer
      } else if (res != null && res.correct) {
        Fx.play(res.streak >= 3 ? Sfx.streak : Sfx.correct);
        tick(store.haptics, heavy: true);
        store.countCorrect(ctrl.question!.category);
        store.recordCombo(res.streak);
      } else {
        Fx.wrong();
      }
    }
    if (r.status == RoomStatus.finished && _lastStatus != RoomStatus.finished) {
      // Short wait so the final scores have streamed in.
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _grantRewards(store);
      });
    }
    _lastStatus = r.status;
    _lastIdx = r.currentIndex;
  }

  /// Someone in this room already had our nickname, so the server gave us a
  /// numbered one. Say so once, or the player wonders who "Kofi 2" is.
  void _checkMyName(PlayerStore store) {
    if (_toldAboutName || !mounted) return;
    final me = ctrl.mePlayer;
    if (me == null) return;
    _toldAboutName = true;
    final mine = store.nickname.trim();
    if (me.nickname == mine || mine.isEmpty) return;
    showToast(context, 'Someone here is already $mine, so you are ${me.nickname} in this room.');
  }

  void _grantRewards(PlayerStore store) {
    final key = '${ctrl.room.id}:${ctrl.room.phaseStartedAt}';
    if (_rewarded.contains(key) || ctrl.mePlayer == null) return;
    _rewarded.add(key);
    final ranked = ctrl.ranked;
    final rank = ranked.indexWhere((p) => p.userId == ctrl.me);
    final me = ctrl.mePlayer!;
    final coins = switch (rank) { 0 => 30, 1 => 20, 2 => 15, _ => 10 };
    Fx.celebrate(won: rank >= 0 && rank < 3);
    () async {
      await store.addReward(xp: (me.score / 10).round() + 20, coins: coins, game: true, win: rank == 0 && ranked.length > 1);
      await store.markActive();
      if (mounted) await announceBadges(context, store);
    }();
  }

  Future<bool> _confirmLeave() async {
    final c = context.c;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Leave the room?', style: T.disp(28, color: c.ink)),
            const SizedBox(height: 8),
            Text(
              ctrl.isHost ? 'Someone else becomes the host.' : 'You can rejoin with the same code.',
              style: T.body(15, color: c.muted),
            ),
            const SizedBox(height: 20),
            GoButton(label: 'Leave', icon: Icons.logout_rounded, onTap: () => Navigator.pop(ctx, true)),
            const SizedBox(height: 10),
            GhostButton(label: 'Stay', onTap: () => Navigator.pop(ctx, false)),
          ]),
        ),
      ),
    );
    return ok ?? false;
  }

  Future<void> _leave() async {
    if (!await _confirmLeave()) return;
    await ctrl.leave();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: SafeArea(
          child: ListenableBuilder(
            listenable: ctrl,
            builder: (context, _) {
              final status = ctrl.room.status;
              final Widget view = switch (status) {
                RoomStatus.lobby => _LobbyView(ctrl: ctrl, onLeave: _leave),
                RoomStatus.question || RoomStatus.reveal => _GameView(ctrl: ctrl, onLeave: _leave),
                RoomStatus.finished => _ResultsView(ctrl: ctrl, onLeave: _leave),
              };
              return PlayerPhotos(
                photos: ctrl.photos,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: KeyedSubtree(key: ValueKey(status == RoomStatus.reveal ? RoomStatus.question : status), child: view),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _EmoteBar extends ConsumerWidget {
  const _EmoteBar({required this.ctrl});
  final RoomController ctrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _emotes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Pressable(
          onTap: () {
            tick(ref.read(playerStoreProvider).haptics);
            ctrl.sendEmote(_emotes[i]);
          },
          semanticLabel: 'Send ${_emotes[i]}',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: c.line, width: 1.5),
            ),
            child: Text(_emotes[i], style: T.body(14, w: FontWeight.w700, color: c.ink)),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Pastel.badBg, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.wifi_off_rounded, size: 18, color: Pastel.ink),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: T.body(13, w: FontWeight.w600, color: Pastel.ink))),
        ]),
      );
}

/// Avatar with name, optional badge and a floating emote bubble.
class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.player, required this.isMe, this.emote, this.badge, this.size = 54, this.dim = false});
  final Player player;
  final bool isMe;
  final String? emote;
  final Widget? badge;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: size + 22,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          AnimatedOpacity(
            opacity: dim ? 0.4 : 1,
            duration: const Duration(milliseconds: 200),
            child: Avatar(initial: player.initial, index: player.avatar, size: size, ring: isMe ? c.ink : null, userId: player.userId),
          ),
          if (player.isHost)
            Positioned(
              top: -8,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: Pastel.coin, shape: BoxShape.circle, border: Border.all(color: c.bg, width: 2)),
                child: const Icon(Icons.star_rounded, size: 12, color: Pastel.ink),
              ),
            ),
          if (badge != null) Positioned(bottom: -6, right: -4, child: badge!),
          if (emote != null)
            Positioned(
              top: -34,
              child: PopIn(
                key: ValueKey(emote),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(14)),
                  child: Text(emote!, style: T.body(12, w: FontWeight.w700, color: c.onPrimary)),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        Text(
          isMe ? 'You' : player.nickname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: T.body(12, w: FontWeight.w600, color: c.ink),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Lobby
// ---------------------------------------------------------------------------

class _LobbyView extends ConsumerStatefulWidget {
  const _LobbyView({required this.ctrl, required this.onLeave});
  final RoomController ctrl;
  final VoidCallback onLeave;

  @override
  ConsumerState<_LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends ConsumerState<_LobbyView> {
  bool _starting = false;

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await widget.ctrl.start();
    } catch (e) {
      if (mounted) showToast(context, e.toString());
    }
    if (mounted) setState(() => _starting = false);
  }

  void _shareWhatsApp(String code) {
    final msg = Uri.encodeComponent('Join my Exam Duel trivia room! Code: $code');
    launchUrl(Uri.parse('https://wa.me/?text=$msg'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final ctrl = widget.ctrl;
    final room = ctrl.room;
    final players = [...ctrl.players]..sort((a, b) => a.isHost == b.isHost ? 0 : (a.isHost ? -1 : 1));
    final host = players.where((p) => p.isHost).firstOrNull;
    final line = ctrl.isHost
        ? (players.length < 2 ? 'Share the code. I’ll wait.' : 'Everyone in? Let’s go!')
        : 'Waiting for ${host?.nickname ?? 'the host'} to start…';

    final header = Row(children: [
      CircleIconButton(icon: Icons.close_rounded, label: 'Leave room', onTap: widget.onLeave),
      const SizedBox(width: 12),
      Expanded(child: Text('Lobby', style: T.disp(28, color: c.ink))),
      StatPill(icon: Icons.group_rounded, value: '${players.length}/12', label: '${players.length} players'),
    ]);

    final codeCard = Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 14, 18),
      decoration: BoxDecoration(color: c.acc, borderRadius: BorderRadius.circular(32)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ROOM CODE', style: T.micro(color: Pastel.ink)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(room.code, style: T.disp(64, color: Pastel.ink).copyWith(letterSpacing: 6)),
            ),
          ),
          CircleIconButton(
            icon: Icons.copy_rounded,
            label: 'Copy code',
            fill: Colors.white,
            onTap: () {
              Clipboard.setData(ClipboardData(text: room.code));
              showToast(context, 'Code copied');
            },
          ),
          const SizedBox(width: 8),
          CircleIconButton(icon: Icons.share_rounded, label: 'Share on WhatsApp', fill: Colors.white, onTap: () => _shareWhatsApp(room.code)),
        ]),
        const SizedBox(height: 10),
        Text(room.settings.summary, style: T.body(14, w: FontWeight.w600, color: Pastel.ink)),
        if (room.settings.hasAiBatch) ...[
          const SizedBox(height: 8),
          const Tag('Eve wrote fresh questions'),
        ],
      ]),
    );

    final eveRow = Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Eve(size: 96, iris: c.iris, mood: players.length > 1 ? EveMood.happy : EveMood.idle, outfit: store.outfit, motion: !store.reduceMotion, bob: true),
      const SizedBox(width: 8),
      Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 26), child: Bubble(line))),
    ]);

    final playerList = Wrap(
      spacing: 6,
      runSpacing: 44,
      children: [
        for (final p in players)
          PopIn(
            key: ValueKey(p.userId),
            enabled: !store.reduceMotion,
            child: _PlayerChip(player: p, isMe: p.userId == ctrl.me, emote: ctrl.emotes[p.userId]?.emote),
          ),
      ],
    );

    final controls = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _EmoteBar(ctrl: ctrl),
      const SizedBox(height: 12),
      if (ctrl.isHost)
        GoButton(
          label: players.length < 2 ? 'Start (practice alone)' : 'Start game',
          busy: _starting,
          onTap: _start,
        )
      else
        Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(999)),
          child: Text('The host starts the game', style: T.disp(17, color: c.muted)),
        ),
    ]);

    if (isWide(context)) {
      // Web / desktop: code and controls on the left, players on the right.
      return ContentWidth(
        maxWidth: 1200,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            header,
            const SizedBox(height: 20),
            if (ctrl.error != null) _ErrorBanner(ctrl.error!),
            Expanded(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(
                  width: 440,
                  child: ListView(children: [codeCard, const SizedBox(height: 22), eveRow, const SizedBox(height: 22), controls]),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(32)),
                    child: ListView(children: [
                      Text('PLAYERS · ${players.length}', style: T.micro(color: c.muted)),
                      const SizedBox(height: 44),
                      playerList,
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: header),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          children: [
            if (ctrl.error != null) _ErrorBanner(ctrl.error!),
            codeCard,
            const SizedBox(height: 18),
            eveRow,
            const SizedBox(height: 20),
            Text('PLAYERS', style: T.micro(color: c.muted)),
            const SizedBox(height: 40),
            playerList,
          ],
        ),
      ),
      Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), child: controls),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Live question + reveal
// ---------------------------------------------------------------------------

class _GameView extends ConsumerWidget {
  const _GameView({required this.ctrl, required this.onLeave});
  final RoomController ctrl;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final motion = !store.reduceMotion;
    final room = ctrl.room;
    final q = ctrl.question;
    final reveal = room.status == RoomStatus.reveal && q?.answer != null;
    final me = ctrl.mePlayer;
    final result = ctrl.myResult;
    final answered = ctrl.myChoice != null;

    final EveMood mood;
    String line;
    if (!reveal) {
      mood = answered ? EveMood.idle : EveMood.thinking;
      line = answered ? 'Locked in. ${ctrl.answeredCount}/${ctrl.players.length} answered' : 'Hmm. Think fast!';
    } else if (result == null) {
      mood = EveMood.sleepy;
      line = 'Too slow! Next one.';
    } else if (result.correct) {
      mood = result.streak >= 3 ? EveMood.fire : EveMood.happy;
      line = result.streak >= 3 ? 'Combo ×${result.streak}! Keep going!' : 'Sharp eyes!';
    } else {
      mood = EveMood.oops;
      line = 'Hmm. Let’s learn it.';
    }

    final canAnswer = q != null && !answered && room.status == RoomStatus.question;
    if (isWide(context)) {
      return AnswerKeys(
        onPick: canAnswer ? ctrl.answer : null,
        child: _wide(context, c, store.outfit, motion, room, q, reveal, me, result, answered, mood, line),
      );
    }

    // Scrolls only if the screen is too short; otherwise fills it exactly.
    return AnswerKeys(
      onPick: canAnswer ? ctrl.answer : null,
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight - 26),
            child: IntrinsicHeight(
              child: _content(context, c, store.outfit, motion, room, q, reveal, me, result, answered, mood, line),
            ),
          ),
        ),
      ),
    );
  }

  _AnswerButton _answer(Question q, int i, Room room, bool reveal, bool answered, bool motion) => _AnswerButton(
        letter: String.fromCharCode(65 + i),
        text: q.options[i],
        state: _stateFor(i, q, reveal),
        shakeKey: '${room.currentIndex}-$i',
        motion: motion,
        onTap: (!answered && !reveal) ? () => ctrl.answer(i) : null,
      );

  /// Web / desktop: question and 2×2 answers on the left, live scoreboard on the right.
  Widget _wide(BuildContext context, AppColors c, String outfit, bool motion, Room room, Question? q, bool reveal,
      Player? me, AnswerResult? result, bool answered, EveMood mood, String line) {
    return ContentWidth(
      maxWidth: 1280,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 24),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (ctrl.error != null) _ErrorBanner(ctrl.error!),
                Row(children: [
                  CircleIconButton(icon: Icons.close_rounded, label: 'Leave game', onTap: onLeave),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('QUESTION ${room.currentIndex + 1} OF ${room.questionCount}', style: T.micro(color: c.muted)),
                      const SizedBox(height: 8),
                      ProgressBar(value: (room.currentIndex + (reveal ? 1 : 0)) / room.questionCount.clamp(1, 99), striped: true, height: 10),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  reveal
                      ? SizedBox(
                          width: 84,
                          child: Column(children: [
                            Text('${me?.score ?? 0}', style: T.disp(26, color: c.ink)),
                            Text('points', style: T.body(12, color: c.muted)),
                          ]),
                        )
                      : TimerRing(fraction: ctrl.timeLeftFraction, seconds: ctrl.secondsLeft, size: 76),
                ]),
                const SizedBox(height: 28),
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 210),
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(32)),
                    child: q == null
                        ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Tag(Category.byId(q.category).name, color: Pastel.all[Category.byId(q.category).colorIndex]),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.only(right: 120),
                              child: Text(q.stem, style: T.disp(36, color: c.ink).copyWith(height: 1.12)),
                            ),
                          ]),
                  ),
                  Positioned(
                    right: 8,
                    top: -26,
                    child: IgnorePointer(
                      child: Eve(size: 120, iris: c.iris, mood: mood, outfit: outfit, motion: motion, sparkle: reveal && (result?.correct ?? false)),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerLeft, child: Bubble(line)),
                const SizedBox(height: 18),
                if (q != null)
                  for (var r = 0; r < q.options.length; r += 2) ...[
                    IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(child: _answer(q, r, room, reveal, answered, motion)),
                        const SizedBox(width: 12),
                        Expanded(child: r + 1 < q.options.length ? _answer(q, r + 1, room, reveal, answered, motion) : const SizedBox()),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 8),
                if (reveal) ...[
                  if (result != null && result.points > 0) Center(child: FloatUp(text: '+${result.points}', color: c.ink)),
                  const SizedBox(height: 8),
                  ProgressBar(value: 1 - ctrl.revealProgress, height: 4),
                ] else
                  Text('Tip: press 1–4 or A–D to answer', textAlign: TextAlign.center, style: T.body(13, color: c.muted)),
              ]),
            ),
          ),
          const SizedBox(width: 28),
          SizedBox(
            width: 340,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: _Scoreboard(ctrl: ctrl, reveal: reveal)),
              const SizedBox(height: 12),
              _EmoteBar(ctrl: ctrl),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _content(BuildContext context, AppColors c, String outfit, bool motion, Room room, Question? q, bool reveal,
      Player? me, AnswerResult? result, bool answered, EveMood mood, String line) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (ctrl.error != null) _ErrorBanner(ctrl.error!),
        Row(children: [
          CircleIconButton(icon: Icons.close_rounded, label: 'Leave game', onTap: onLeave),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('QUESTION ${room.currentIndex + 1} OF ${room.questionCount}', style: T.micro(color: c.muted)),
              const SizedBox(height: 8),
              ProgressBar(value: (room.currentIndex + (reveal ? 1 : 0)) / room.questionCount.clamp(1, 99), striped: true),
            ]),
          ),
          const SizedBox(width: 12),
          reveal
              ? SizedBox(
                  width: 64,
                  child: Column(children: [
                    Text('${me?.score ?? 0}', style: T.disp(20, color: c.ink)),
                    Text('points', style: T.body(11, color: c.muted)),
                  ]),
                )
              : TimerRing(fraction: ctrl.timeLeftFraction, seconds: ctrl.secondsLeft),
        ]),
        const SizedBox(height: 14),
        // Question card with Eve peeking.
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 150),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(28)),
            child: q == null
                ? const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Tag(Category.byId(q.category).name, color: Pastel.all[Category.byId(q.category).colorIndex]),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(right: 56),
                      child: Text(q.stem, style: T.disp(24, color: c.ink, w: FontWeight.w700).copyWith(height: 1.15)),
                    ),
                  ]),
          ),
          Positioned(
            right: -6,
            top: -18,
            child: IgnorePointer(
              child: Eve(size: 78, iris: c.iris, mood: mood, outfit: outfit, motion: motion, sparkle: reveal && (result?.correct ?? false)),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerLeft, child: Bubble(line)),
        const SizedBox(height: 12),
        if (q != null)
          for (var i = 0; i < q.options.length; i++) ...[
            _answer(q, i, room, reveal, answered, motion),
            const SizedBox(height: 10),
          ],
        const Spacer(),
        if (reveal && result != null && result.points > 0)
          Center(child: FloatUp(text: '+${result.points}', color: c.ink)),
        if (reveal) ...[
          _MiniLeaderboard(ctrl: ctrl),
          const SizedBox(height: 10),
          ProgressBar(value: 1 - ctrl.revealProgress, height: 4),
        ] else
          _AnsweredRow(ctrl: ctrl),
        const SizedBox(height: 10),
        _EmoteBar(ctrl: ctrl),
      ]);
  }

  _AnsState _stateFor(int i, Question q, bool reveal) {
    final mine = ctrl.myChoice == i;
    if (!reveal) {
      if (ctrl.myChoice == null) return _AnsState.idle;
      return mine ? _AnsState.picked : _AnsState.dim;
    }
    if (q.answer == i) return _AnsState.correct;
    if (mine) return _AnsState.wrong;
    return _AnsState.dim;
  }
}

enum _AnsState { idle, picked, dim, correct, wrong }

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.letter,
    required this.text,
    required this.state,
    required this.shakeKey,
    required this.motion,
    this.onTap,
  });
  final String letter, text, shakeKey;
  final _AnsState state;
  final bool motion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bg = switch (state) {
      _AnsState.correct => Pastel.okBg,
      _AnsState.wrong => Pastel.badBg,
      _AnsState.dim => Colors.transparent,
      _ => c.surface,
    };
    final fg = state == _AnsState.correct || state == _AnsState.wrong ? Pastel.ink : c.ink;
    final status = switch (state) {
      _AnsState.correct => (Icons.check_rounded, 'Correct'),
      _AnsState.wrong => (Icons.close_rounded, 'Yours'),
      _AnsState.picked => (Icons.lock_rounded, 'Locked'),
      _ => null,
    };

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: state == _AnsState.picked ? c.ink : (state == _AnsState.dim ? c.line : Colors.transparent),
          width: state == _AnsState.picked ? 2.5 : 1.5,
        ),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: state == _AnsState.correct ? Pastel.ink : (state == _AnsState.wrong ? Pastel.ink.withValues(alpha: .15) : c.surface2),
            shape: BoxShape.circle,
          ),
          child: Text(letter, style: T.disp(16, color: state == _AnsState.correct ? Colors.white : fg)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Opacity(
            opacity: state == _AnsState.dim ? 0.45 : 1,
            child: Text(text, style: T.body(16, w: FontWeight.w600, color: fg, height: 1.25)),
          ),
        ),
        if (status != null) ...[
          const SizedBox(width: 8),
          Icon(status.$1, size: 18, color: fg),
          const SizedBox(width: 4),
          Text(status.$2, style: T.body(13, w: FontWeight.w700, color: fg)),
        ],
      ]),
    );

    return Pressable(
      onTap: onTap,
      scale: 0.95,
      semanticLabel: 'Answer $letter: $text${status == null ? '' : ', ${status.$2}'}',
      child: state == _AnsState.wrong ? Shake(trigger: shakeKey, enabled: motion, child: button) : button,
    );
  }
}

/// During a question: who has answered (no choices shown).
class _AnsweredRow extends StatelessWidget {
  const _AnsweredRow({required this.ctrl});
  final RoomController ctrl;

  @override
  Widget build(BuildContext context) {
    final idx = ctrl.room.currentIndex;
    return SizedBox(
      height: 112,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: 34),
        children: [
          for (final p in ctrl.players)
            _PlayerChip(
              player: p,
              isMe: p.userId == ctrl.me,
              size: 40,
              dim: p.answeredIndex < idx,
              emote: ctrl.emotes[p.userId]?.emote,
              badge: p.answeredIndex >= idx
                  ? Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Pastel.ink, shape: BoxShape.circle, border: Border.all(color: context.c.bg, width: 2)),
                      child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

/// Web / desktop sidebar: every player, live.
class _Scoreboard extends StatelessWidget {
  const _Scoreboard({required this.ctrl, required this.reveal});
  final RoomController ctrl;
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final ranked = ctrl.ranked;
    final idx = ctrl.room.currentIndex;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(28)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('SCOREBOARD', style: T.micro(color: c.muted)),
          const Spacer(),
          if (!reveal) Text('${ctrl.answeredCount}/${ctrl.players.length} answered', style: T.body(12, color: c.muted)),
        ]),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: ranked.length,
            itemBuilder: (_, i) {
              final p = ranked[i];
              final isMe = p.userId == ctrl.me;
              final done = p.answeredIndex >= idx;
              final emote = ctrl.emotes[p.userId]?.emote;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: isMe ? c.accSoft : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  SizedBox(width: 22, child: Text('${i + 1}', style: T.disp(15, color: c.muted))),
                  Avatar(initial: p.initial, index: p.avatar, size: 32, userId: p.userId),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isMe ? 'You' : p.nickname, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body(14, w: FontWeight.w600, color: c.ink)),
                      if (emote != null) Text(emote, style: T.body(12, w: FontWeight.w700, color: c.muted)),
                    ]),
                  ),
                  if (!reveal)
                    Icon(done ? Icons.check_circle_rounded : Icons.more_horiz_rounded, size: 18, color: done ? c.ink : c.muted)
                  else ...[
                    if (p.streak >= 2) ...[
                      const Icon(Icons.local_fire_department_rounded, size: 16, color: Pastel.coral),
                      Text('${p.streak}', style: T.body(12, w: FontWeight.w700, color: c.ink)),
                      const SizedBox(width: 6),
                    ],
                    if (p.lastPoints > 0) Text('+${p.lastPoints}', style: T.body(12, w: FontWeight.w700, color: c.muted)),
                  ],
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 56,
                    child: CountUp(value: p.score, style: T.disp(17, color: c.ink), duration: const Duration(milliseconds: 700)),
                  ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// After the reveal: top players with points just earned.
class _MiniLeaderboard extends StatelessWidget {
  const _MiniLeaderboard({required this.ctrl});
  final RoomController ctrl;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final ranked = ctrl.ranked;
    final myRank = ranked.indexWhere((p) => p.userId == ctrl.me);
    final shown = ranked.take(3).toList();
    if (myRank >= 3) shown.add(ranked[myRank]);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        for (final p in shown)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              SizedBox(width: 22, child: Text('${ranked.indexOf(p) + 1}', style: T.disp(16, color: c.muted))),
              Avatar(initial: p.initial, index: p.avatar, size: 30, ring: p.userId == ctrl.me ? c.ink : null, userId: p.userId),
              const SizedBox(width: 10),
              Expanded(
                child: Text(p.userId == ctrl.me ? 'You' : p.nickname,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body(15, w: FontWeight.w600, color: c.ink)),
              ),
              if (p.lastPoints > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text('+${p.lastPoints}', style: T.body(13, w: FontWeight.w700, color: c.muted)),
                ),
              if (p.streak >= 2)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(children: [
                    const Icon(Icons.local_fire_department_rounded, size: 16, color: Pastel.coral),
                    Text('${p.streak}', style: T.body(13, w: FontWeight.w700, color: c.ink)),
                  ]),
                ),
              CountUp(value: p.score, style: T.disp(18, color: c.ink), duration: const Duration(milliseconds: 700)),
            ]),
          ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

class _ResultsView extends ConsumerStatefulWidget {
  const _ResultsView({required this.ctrl, required this.onLeave});
  final RoomController ctrl;
  final VoidCallback onLeave;

  @override
  ConsumerState<_ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends ConsumerState<_ResultsView> {
  bool _starting = false;
  final _cardKey = GlobalKey();

  void _shareScore() {
    final ctrl = widget.ctrl;
    final ranked = ctrl.ranked;
    final rank = ranked.indexWhere((p) => p.userId == ctrl.me);
    final score = ctrl.mePlayer?.score ?? 0;
    final place = rank == 0 ? 'won' : (rank > 0 ? 'came #${rank + 1} of ${ranked.length}' : 'played');
    final text = 'I $place in Exam Duel with $score points! 🦉 Think you can beat me? Play free: $appLink';
    shareCard(context, _cardKey, text);
  }

  Future<void> _rematch() async {
    setState(() => _starting = true);
    try {
      await widget.ctrl.start();
    } catch (e) {
      if (mounted) showToast(context, e.toString());
    }
    if (mounted) setState(() => _starting = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final motion = !store.reduceMotion;
    final ctrl = widget.ctrl;
    final ranked = ctrl.ranked;
    final myRank = ranked.indexWhere((p) => p.userId == ctrl.me);
    final winner = ranked.isEmpty ? null : ranked.first;
    final iWon = myRank == 0;
    final title = winner == null ? 'Game over' : (iWon ? 'You won!' : '${winner.nickname} wins!');
    final mood = iWon ? EveMood.cheering : (myRank >= 0 && myRank < 3 ? EveMood.proud : EveMood.sad);
    final line = iWon ? 'YES! You did it!' : (myRank < 3 ? 'Look how far you’ve come.' : 'So close. Rematch?');
    final coins = switch (myRank) { 0 => 30, 1 => 20, 2 => 15, _ => 10 };
    final xp = ((ctrl.mePlayer?.score ?? 0) / 10).round() + 20;

    return Stack(children: [
      if (motion && myRank >= 0 && myRank < 3) const Positioned.fill(child: ConfettiBurst()),
      ContentWidth(
        maxWidth: isWide(context) ? 760 : double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              // Captured as an image when sharing the score.
              RepaintBoundary(
                key: _cardKey,
                child: Container(
                  color: c.bg,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('RESULTS · EXAM DUEL', style: T.micro(color: c.muted)),
                          const SizedBox(height: 6),
                          Text(title, style: T.disp(40, color: c.ink)),
                          const SizedBox(height: 10),
                          Bubble(line),
                        ]),
                      ),
                      Eve(size: 120, iris: c.iris, mood: mood, outfit: store.outfit, motion: motion),
                    ]),
                    const SizedBox(height: 28),
                    _Podium(ranked: ranked, me: ctrl.me, motion: motion),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 3; i < ranked.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    SizedBox(width: 26, child: Text('${i + 1}', style: T.disp(16, color: c.muted))),
                    Avatar(initial: ranked[i].initial, index: ranked[i].avatar, size: 32, userId: ranked[i].userId),
                    const SizedBox(width: 10),
                    Expanded(child: Text(ranked[i].userId == ctrl.me ? 'You' : ranked[i].nickname, style: T.body(15, w: FontWeight.w600, color: c.ink))),
                    Text('${ranked[i].score}', style: T.disp(18, color: c.ink)),
                  ]),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: c.accSoft, borderRadius: BorderRadius.circular(24)),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('YOU EARNED', style: T.micro(color: c.muted)),
                      const SizedBox(height: 8),
                      Row(children: [
                        CountUp(value: xp, prefix: '+', style: T.disp(26, color: c.ink)),
                        Text(' XP', style: T.body(15, w: FontWeight.w600, color: c.muted)),
                        const SizedBox(width: 18),
                        const Icon(Icons.toll_rounded, color: Pastel.coin, size: 22),
                        const SizedBox(width: 4),
                        CountUp(value: coins, prefix: '+', style: T.disp(26, color: c.ink)),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (ctrl.isHost)
              GoButton(label: 'Rematch', icon: Icons.replay_rounded, busy: _starting, onTap: _rematch)
            else
              Container(
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(999)),
                child: Text('Waiting for a rematch…', style: T.disp(17, color: c.muted)),
              ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: GhostButton(label: 'Share', icon: Icons.ios_share_rounded, onTap: _shareScore)),
              const SizedBox(width: 10),
              Expanded(child: GhostButton(label: 'Leave', icon: Icons.logout_rounded, onTap: widget.onLeave)),
            ]),
          ]),
        ),
      ]),
      ),
    ]);
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.ranked, required this.me, required this.motion});
  final List<Player> ranked;
  final String? me;
  final bool motion;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // Visual order: 2nd, 1st, 3rd.
    final slots = [1, 0, 2];
    const heights = [110.0, 150.0, 84.0];
    const colors = [Pastel.sky, Pastel.peach, Pastel.pink];
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      for (var s = 0; s < 3; s++)
        Expanded(
          child: slots[s] < ranked.length
              ? PopIn(
                  enabled: motion,
                  delay: Duration(milliseconds: 250 * (2 - slots[s])),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(children: [
                      Avatar(
                        initial: ranked[slots[s]].initial,
                        index: ranked[slots[s]].avatar,
                        size: slots[s] == 0 ? 62 : 50,
                        ring: ranked[slots[s]].userId == me ? c.ink : null,
                        userId: ranked[slots[s]].userId,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ranked[slots[s]].userId == me ? 'You' : ranked[slots[s]].nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: T.body(13, w: FontWeight.w700, color: c.ink),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: heights[s],
                        width: double.infinity,
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: colors[s],
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        ),
                        child: Column(children: [
                          Text('${slots[s] + 1}', style: T.num(40, color: Pastel.ink)),
                          const SizedBox(height: 4),
                          Text('${ranked[slots[s]].score}', style: T.disp(15, color: Pastel.ink)),
                        ]),
                      ),
                    ]),
                  ),
                )
              : const SizedBox(),
        ),
    ]);
  }
}
