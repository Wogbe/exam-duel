import 'package:flutter/material.dart';

import '../data/player_store.dart';
import '../theme/app_theme.dart';

/// Mon–Sun pills; a dot marks days you played, today is filled.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.activeDays});
  final Set<String> activeDays;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          Flexible(child: Builder(builder: (_) {
            final d = monday.add(Duration(days: i));
            final isToday = i == now.weekday - 1;
            final done = activeDays.contains(PlayerStore.dayKey(d));
            return Semantics(
              label: '${labels[i]} ${d.day}${done ? ', played' : ''}${isToday ? ', today' : ''}',
              child: Container(
                width: 42,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                height: 64,
                decoration: BoxDecoration(
                  color: isToday ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: isToday ? c.primary : c.line, width: 1.5),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: done ? (isToday ? Pastel.lime : c.ink) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(labels[i], style: T.body(12, color: isToday ? c.onPrimary.withValues(alpha: .7) : c.muted)),
                  Text('${d.day}', style: T.disp(16, color: isToday ? c.onPrimary : c.ink)),
                ]),
              ),
            );
          })),
      ],
    );
  }
}
