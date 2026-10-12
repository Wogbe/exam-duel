import 'package:exam_duel/main_preview.dart';
import 'package:exam_duel/preview/style_board.dart';
import 'package:exam_duel/screens/snap_screen.dart';
import 'package:exam_duel/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('the preview app opens on the style board', (t) async {
    await t.binding.setSurfaceSize(const Size(480, 1000));
    await t.pumpWidget(const PreviewApp());
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(StyleBoard), findsOneWidget);
  });

  testWidgets('study screens work without a ViewSettings above them', (t) async {
    await t.binding.setSurfaceSize(const Size(480, 1000));
    await t.pumpWidget(MaterialApp(theme: buildTheme(dark: false, accent: AccentChoice.aqua), home: const SnapScreen()));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Paste notes'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2)); // let the typewriter's last delay run out
  });
}
