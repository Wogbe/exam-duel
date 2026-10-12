import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/eve/eve.dart';
import '../widgets/responsive.dart';
import 'map_screen.dart';
import 'proto_data.dart';
import 'proto_kit.dart';

/// Step 1: tell Eve what you're learning. Then Eve "thinks" and builds the map.
class SnapScreen extends StatefulWidget {
  const SnapScreen({super.key, this.autoStart});

  /// Skip straight to the thinking sequence (used by the ?screen=thinking link).
  final StudySet? autoStart;

  @override
  State<SnapScreen> createState() => _SnapScreenState();
}

class _SnapScreenState extends State<SnapScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  late StudySet? _building = widget.autoStart;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _start(StudySet set) {
    FocusScope.of(context).unfocus();
    tick(true);
    setState(() => _building = set);
  }

  void _submitTyped() {
    final t = _text.text.trim().toLowerCase();
    if (t.isEmpty) return;
    final id = t.contains('fren')
        ? 'fr'
        : (t.contains('driv') || t.contains('road') ? 'drive' : (t.contains('bio') || t.contains('cell') ? 'bio' : null));
    if (id == null) showToast(context, 'Preview: showing a sample map');
    _start(setById(id));
  }

  void _done() => Navigator.of(context).pushReplacement(softRoute(MapScreen(set: _building!, fresh: true)));

  @override
  Widget build(BuildContext context) {
    final building = _building;
    return Scaffold(
      body: PageBody(
        maxWidth: 520,
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: context.motion ? 450 : 0),
          switchInCurve: Curves.easeOutCubic,
          child: building == null
              ? _input(context)
              : _Thinking(key: ValueKey(building.id), set: building, onDone: _done, onCancel: () => setState(() => _building = null)),
        ),
      ),
    );
  }

  Widget _input(BuildContext context) {
    final c = context.c;
    final canPop = Navigator.of(context).canPop();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(children: [
          if (canPop) CircleIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
          const Spacer(),
          const ProtoPill('Sample data', bg: Pastel.lime),
        ]),
        const SizedBox(height: 18),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Eve(mood: EveMood.happy, size: 96, iris: c.iris, bob: true, motion: context.motion),
          const SizedBox(width: 10),
          const Expanded(child: Padding(padding: EdgeInsets.only(bottom: 34), child: Bubble('Give me anything. I\'ll make it a game.'))),
        ]),
        const SizedBox(height: 16),
        FadeRise(blur: true, child: Text('What are you\nlearning?', style: T.disp(40, color: c.ink))),
        const SizedBox(height: 18),
        FadeRise(delay: const Duration(milliseconds: 120), child: _typeBox(context)),
        const SizedBox(height: 12),
        FadeRise(
          delay: const Duration(milliseconds: 220),
          child: Row(children: [
            for (final (icon, label, colour, from) in [
              (Icons.photo_camera_rounded, 'Snap a photo', Pastel.lav, 'bio'),
              (Icons.content_paste_rounded, 'Paste notes', Pastel.sky, 'bio'),
              (Icons.description_rounded, 'Add a file', Pastel.peach, 'bio'),
            ])
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: label == 'Add a file' ? 0 : 10),
                  child: Pressable(
                    onTap: () => _start(setById(from)),
                    semanticLabel: label,
                    child: Container(
                      height: 108,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(22)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), shape: BoxShape.circle),
                          child: Icon(icon, size: 20, color: Pastel.ink),
                        ),
                        const Spacer(),
                        Text(label, style: T.disp(15, color: Pastel.ink)),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 22),
        FadeRise(
          delay: const Duration(milliseconds: 320),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('OR TRY A SAMPLE', style: mono(color: c.muted)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in studySets)
                Pressable(
                  onTap: () => _start(s),
                  semanticLabel: s.title,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: c.line, width: 1.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(s.topics.first.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(s.title, style: T.body(15, w: FontWeight.w700, color: c.ink)),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
      ],
    );
  }

  Widget _typeBox(BuildContext context) {
    final c = context.c;
    final showGhost = _text.text.isEmpty && !_focus.hasFocus;
    return Container(
      height: 64,
      padding: const EdgeInsets.only(left: 20, right: 7),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: c.line, width: 1.5)),
      child: Row(children: [
        Expanded(
          child: Stack(alignment: Alignment.centerLeft, children: [
            if (showGhost)
              IgnorePointer(
                child: Row(children: [
                  Text('Try: ', style: T.body(17, w: FontWeight.w600, color: c.muted.withValues(alpha: 0.7))),
                  Expanded(
                    child: Typewriter(
                      lines: const ['Cell biology', 'French A2', 'Driving theory', 'My lecture slides', 'Algebra basics', 'World history'],
                      style: T.body(17, w: FontWeight.w600, color: c.muted.withValues(alpha: 0.7)),
                    ),
                  ),
                ]),
              ),
            TextField(
              controller: _text,
              focusNode: _focus,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _submitTyped(),
              style: T.body(17, w: FontWeight.w600, color: c.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: _focus.hasFocus ? 'A subject, topic or exam' : null,
                hintStyle: T.body(17, w: FontWeight.w600, color: c.muted.withValues(alpha: 0.7)),
              ),
            ),
          ]),
        ),
        Pressable(
          onTap: _text.text.trim().isEmpty ? null : _submitTyped,
          semanticLabel: 'Build my map',
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
            child: Icon(Icons.arrow_forward_rounded, color: c.onPrimary),
          ),
        ),
      ]),
    );
  }
}

/// Eve reads, a checklist ticks, skeleton tiles turn into the map.
class _Thinking extends StatefulWidget {
  const _Thinking({super.key, required this.set, required this.onDone, required this.onCancel});
  final StudySet set;
  final VoidCallback onDone, onCancel;

  @override
  State<_Thinking> createState() => _ThinkingState();
}

class _ThinkingState extends State<_Thinking> {
  final _timers = <Timer>[];
  int _step = 0; // checklist items done
  int _revealed = 0; // skeleton tiles turned into real tiles
  bool _started = false;

  List<String> get _steps => [
        'Reading ${widget.set.from}',
        'Found ${widget.set.topics.length} topics',
        'Writing questions',
        'Building your map',
      ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final slow = context.motion;
    final stepMs = slow ? 700 : 150;
    for (var i = 1; i <= 4; i++) {
      _timers.add(Timer(Duration(milliseconds: 400 + stepMs * i), () => setState(() => _step = i)));
    }
    final tilesAt = 400 + stepMs * 4;
    final n = widget.set.topics.length;
    for (var i = 1; i <= n; i++) {
      _timers.add(Timer(Duration(milliseconds: tilesAt + (slow ? 70 : 0) * i), () => setState(() => _revealed = i)));
    }
    _timers.add(Timer(Duration(milliseconds: tilesAt + (slow ? 70 * n + 900 : 400)), widget.onDone));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Center(
          child: Ambient(
            period: const Duration(milliseconds: 2400),
            builder: (context, t) {
              final breathe = context.motion ? math.sin(t * 2 * math.pi) : 0.0;
              return Container(
                width: 190,
                height: 190,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Pastel.lav.withValues(alpha: 0.55 + 0.2 * breathe),
                    Pastel.sky.withValues(alpha: 0.25),
                    Pastel.sky.withValues(alpha: 0),
                  ], stops: [
                    0,
                    0.6 + 0.08 * breathe,
                    1
                  ]),
                ),
                child: Eve(mood: EveMood.thinking, size: 132, iris: c.iris, glow: true, motion: context.motion),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Typewriter(
            lines: ['Eve is reading ${widget.set.from}…'],
            loop: false,
            style: T.disp(20, color: c.ink),
          ),
        ),
        const SizedBox(height: 22),
        for (var i = 0; i < _steps.length; i++)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: i <= _step ? 1 : 0.3,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                AnimatedSwitcher(
                  duration: Duration(milliseconds: context.motion ? 300 : 0),
                  transitionBuilder: (child, a) =>
                      ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: child),
                  child: i < _step
                      ? Container(
                          key: const ValueKey('done'),
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(color: Proto.right, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, size: 17, color: Pastel.ink),
                        )
                      : Container(
                          key: const ValueKey('todo'),
                          width: 26,
                          height: 26,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.line, width: 2)),
                          child: i == _step ? CircularProgressIndicator(strokeWidth: 2, color: c.ink) : null,
                        ),
                ),
                const SizedBox(width: 12),
                Text(_steps[i], style: T.body(16, w: FontWeight.w600, color: c.ink)),
              ]),
            ),
          ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (var i = 0; i < widget.set.topics.length; i++)
              AnimatedSwitcher(
                duration: Duration(milliseconds: context.motion ? 420 : 0),
                transitionBuilder: (child, a) =>
                    ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: child),
                child: i < _revealed
                    ? Container(
                        key: const ValueKey('tile'),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.line, width: 1.5),
                        ),
                        child: Text(widget.set.topics[i].emoji, style: const TextStyle(fontSize: 22)),
                      )
                    : const SkeletonBox(key: ValueKey('skel'), radius: 16),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: widget.onCancel,
            child: Text('Cancel', style: T.body(15, w: FontWeight.w700, color: c.muted)),
          ),
        ),
      ],
    );
  }
}
