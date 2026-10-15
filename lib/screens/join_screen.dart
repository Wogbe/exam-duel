import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/fx.dart';
import '../state/providers.dart';
import '../state/room_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import '../widgets/eve/eve.dart';
import 'room_screen.dart';

class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key, this.initialCode});

  /// Filled in when the screen was opened from a shared link.
  final String? initialCode;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  late final _code = TextEditingController(text: widget.initialCode ?? '');
  bool _busy = false;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    // Arrived by link: join without making them tap anything. Offline, the
    // code is simply filled in, so nobody sees an error they did not ask for.
    if (widget.initialCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(gameRepoProvider).enabled) _join();
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final repo = ref.read(gameRepoProvider);
    final store = ref.read(playerStoreProvider);
    setState(() => _busy = true);
    try {
      await repo.ensureSignedIn();
      final room = await repo.joinRoom(_code.text, store.nickname, store.avatar);
      await store.rememberRoom(room.code);
      if (!mounted) return;
      tick(store.haptics, heavy: true);
      Fx.play(Sfx.go);
      Navigator.of(context).pushReplacement(softRoute(RoomScreen(controller: RoomController(repo, room))));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _shake++;
      });
      Fx.wrong();
      showToast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final ready = _code.text.trim().length == 5;
    final last = store.lastRoomCode;
    return Scaffold(
      body: PageBody(maxWidth: 560,
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 28),
              child: IntrinsicHeight(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              CircleIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
            ]),
            const Spacer(),
            Center(
              child: Eve(
                size: MediaQuery.viewInsetsOf(context).bottom > 0 ? 100 : 160,
                iris: c.iris,
                mood: _shake > 0 && !_busy ? EveMood.oops : (ready ? EveMood.happy : EveMood.idle),
                outfit: store.outfit,
                motion: !store.reduceMotion,
                lookY: 0.6,
              ),
            ),
            const SizedBox(height: 20),
            Text('Enter the room code', style: T.disp(34, color: c.ink), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Ask the host for the 5-letter code.', style: T.body(15, color: c.muted), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Shake(
              trigger: _shake,
              enabled: !store.reduceMotion && _shake > 0,
              child: TextField(
                controller: _code,
                autofocus: widget.initialCode == null,
                maxLength: 5,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                  TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
                ],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => ready ? _join() : null,
                style: T.disp(44, color: c.ink).copyWith(letterSpacing: 12),
                decoration: InputDecoration(
                  hintText: 'ABCDE',
                  hintStyle: T.disp(44, color: c.line).copyWith(letterSpacing: 12),
                  counterText: '',
                  filled: true,
                  fillColor: c.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 22),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            if (last != null && last != _code.text.trim()) ...[
              const SizedBox(height: 14),
              Center(
                child: Pressable(
                  onTap: () => setState(() {
                    _code.text = last;
                    _code.selection = TextSelection.collapsed(offset: last.length);
                  }),
                  semanticLabel: 'Use your last room code, $last',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: c.line, width: 1.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.replay_rounded, size: 17, color: c.muted),
                      const SizedBox(width: 7),
                      Text('Last room: $last', style: T.body(14, w: FontWeight.w700, color: c.ink)),
                    ]),
                  ),
                ),
              ),
            ],
            const Spacer(flex: 2),
            GoButton(label: 'Join room', busy: _busy, onTap: ready ? _join : null),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
