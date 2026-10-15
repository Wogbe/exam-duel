import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../services/fx.dart';
import '../state/providers.dart';
import '../state/room_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import '../widgets/eve/eve.dart';
import 'room_screen.dart';

/// Host picks categories, length and timer, plus an optional AI topic.
class HostSetupScreen extends ConsumerStatefulWidget {
  const HostSetupScreen({super.key});

  @override
  ConsumerState<HostSetupScreen> createState() => _HostSetupScreenState();
}

class _HostSetupScreenState extends ConsumerState<HostSetupScreen> {
  final Set<String> _cats = {};
  int _count = 10;
  int _seconds = 15;
  final _topic = TextEditingController();
  String? _busy; // status line while creating

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final repo = ref.read(gameRepoProvider);
    final store = ref.read(playerStoreProvider);
    final topic = _topic.text.trim();
    setState(() => _busy = 'Opening your room…');
    try {
      await repo.ensureSignedIn();
      final room = await repo.createRoom(
        store.nickname,
        store.avatar,
        RoomSettings(count: _count, seconds: _seconds, categories: _cats.toList()),
      );
      await store.rememberRoom(room.code);
      final ctrl = RoomController(repo, room);
      if (topic.isNotEmpty) {
        setState(() => _busy = 'Eve is writing questions about “$topic”…');
        try {
          final n = await ctrl.addAiQuestions(topic, _count.clamp(3, 20));
          if (mounted) showToast(context, 'Eve wrote $n questions about $topic');
        } catch (e) {
          if (mounted) showToast(context, '$e Using the question bank instead.');
        }
      }
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      Fx.play(Sfx.go);
      Navigator.of(context).pushReplacement(softRoute(RoomScreen(controller: ctrl)));
    } catch (e) {
      if (mounted) {
        setState(() => _busy = null);
        showToast(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = ref.watch(playerStoreProvider);
    final online = ref.watch(gameRepoProvider).enabled;
    final counts = ref.watch(localBankProvider).countsByCategory;
    final motion = !store.reduceMotion;

    if (_busy != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Eve(size: 180, iris: c.iris, mood: EveMood.thinking, outfit: store.outfit, motion: motion, bob: true),
              const SizedBox(height: 24),
              Text(_busy!, style: T.disp(24, color: c.ink), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(width: 160, child: LinearProgressIndicator(color: c.ink, backgroundColor: c.line, minHeight: 6, borderRadius: BorderRadius.circular(99))),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      body: PageBody(maxWidth: 820,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(children: [
              CircleIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: 12),
              Expanded(child: Text('New room', style: T.disp(28, color: c.ink))),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                if (!online) _offlineCard(c),
                Row(children: [
                  Text('CATEGORIES', style: T.micro(color: c.muted)),
                  const Spacer(),
                  Text(_cats.isEmpty ? 'All mixed' : '${_cats.length} picked', style: T.body(13, color: c.muted)),
                ]),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: isWide(context) ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.3,
                  children: [for (final cat in Category.all) _catTile(c, cat, counts[cat.id] ?? 0)],
                ),
                const SizedBox(height: 22),
                Text('QUESTIONS', style: T.micro(color: c.muted)),
                const SizedBox(height: 10),
                _chips(c, const [5, 10, 15, 20], _count, (v) => setState(() => _count = v), (v) => '$v'),
                const SizedBox(height: 22),
                Text('SECONDS PER QUESTION', style: T.micro(color: c.muted)),
                const SizedBox(height: 10),
                _chips(c, const [10, 15, 20, 30], _seconds, (v) => setState(() => _seconds = v), (v) => '${v}s'),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(28)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Tag('Optional · AI', color: c.accSoft, dark: true),
                          const SizedBox(height: 8),
                          Text('Ask Eve to write questions', style: T.disp(20, color: c.ink)),
                        ]),
                      ),
                      Eve(size: 70, iris: c.iris, mood: _topic.text.isEmpty ? EveMood.idle : EveMood.surprised, motion: motion),
                    ]),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _topic,
                      maxLength: 80,
                      onChanged: (_) => setState(() {}),
                      style: T.body(16, color: c.ink),
                      decoration: InputDecoration(
                        hintText: 'e.g. Afrobeats, Premier League, Marvel',
                        counterText: '',
                        filled: true,
                        fillColor: c.bg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Eve’s questions come first, then the bank fills the rest.', style: T.body(13, color: c.muted)),
                  ]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: GoButton(label: 'Create room', onTap: online ? _create : null),
          ),
        ]),
      ),
    );
  }

  Widget _offlineCard(AppColors c) => Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Pastel.peach, borderRadius: BorderRadius.circular(24)),
        child: Text(
          'Online rooms are not connected yet. Add your Supabase URL and key (see README), then rebuild. Quick Fire works offline.',
          style: T.body(14, w: FontWeight.w600, color: Pastel.ink),
        ),
      );

  Widget _catTile(AppColors c, Category cat, int count) {
    final on = _cats.contains(cat.id);
    return Pressable(
      onTap: () {
        tick(ref.read(playerStoreProvider).haptics);
        setState(() => on ? _cats.remove(cat.id) : _cats.add(cat.id));
      },
      semanticLabel: '${cat.name}${on ? ', selected' : ''}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Pastel.all[cat.colorIndex],
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: on ? c.ink : Colors.transparent, width: 2.5),
        ),
        child: Row(children: [
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body(14, w: FontWeight.w700, color: Pastel.ink, height: 1.15)),
              if (count > 0) Text('$count questions', style: T.body(11, w: FontWeight.w600, color: Pastel.ink)),
            ]),
          ),
          AnimatedScale(
            scale: on ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: Pastel.ink, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chips(AppColors c, List<int> values, int selected, ValueChanged<int> onPick, String Function(int) label) => Row(
        children: [
          for (final v in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Pressable(
                  onTap: () => onPick(v),
                  semanticLabel: '${label(v)}${v == selected ? ', selected' : ''}',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: v == selected ? c.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: v == selected ? c.primary : c.line, width: 1.5),
                    ),
                    child: Text(label(v), style: T.body(15, w: FontWeight.w600, color: v == selected ? c.onPrimary : c.ink)),
                  ),
                ),
              ),
            ),
        ],
      );
}
