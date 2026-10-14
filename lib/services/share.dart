import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/common.dart';

/// Where friends can play. Shared with every score.
const appLink = 'https://wogbe.github.io/exam-duel/';

/// Shares [text] with the system share sheet. Where there is none (most
/// desktop browsers), copies it instead.
Future<void> shareText(BuildContext context, String text) async {
  Share.downloadFallbackEnabled = false;
  try {
    final r = await Share.share(text);
    if (r.status != ShareResultStatus.unavailable || !kIsWeb) return;
  } catch (_) {
    // No share sheet here: copy instead.
  }
  if (context.mounted) await _copy(context, text);
}

/// Shares a picture of the widget under [boundaryKey] (a [RepaintBoundary])
/// with [text]. If images can't be shared here, shares the text alone (or
/// copies it).
Future<void> shareCard(BuildContext context, GlobalKey boundaryKey, String text) async {
  Share.downloadFallbackEnabled = false;
  final png = await _capture(boundaryKey);
  if (png != null) {
    try {
      final r = await Share.shareXFiles(
        [XFile.fromData(png, mimeType: 'image/png', name: 'exam-duel-score.png')],
        text: text,
        fileNameOverrides: const ['exam-duel-score.png'],
      );
      if (r.status != ShareResultStatus.unavailable || !kIsWeb) return;
    } catch (_) {
      // Fall through to text.
    }
  }
  if (context.mounted) await shareText(context, text);
}

Future<Uint8List?> _capture(GlobalKey key) async {
  try {
    final boundary = key.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return null;
    final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

Future<void> _copy(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showToast(context, 'Copied. Paste it in your chat!');
}
