import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/player_store.dart';
import '../theme/app_theme.dart';
import '../widgets/badges.dart';
import '../widgets/common.dart';

/// Opens a sheet to take, choose or remove the profile photo, then saves it.
/// Photos are shrunk to 256 px so they stay small on the phone and online.
Future<void> editPhoto(BuildContext context, PlayerStore store) async {
  final c = context.c;
  final source = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Profile photo', style: T.disp(28, color: c.ink)),
          const SizedBox(height: 6),
          Text('Friends see it in rooms and on the podium.', style: T.body(15, color: c.muted)),
          const SizedBox(height: 20),
          GoButton(label: 'Choose from gallery', onTap: () => Navigator.pop(ctx, 'gallery')),
          if (!kIsWeb) ...[
            const SizedBox(height: 10),
            GhostButton(label: 'Take a photo', icon: Icons.photo_camera_rounded, onTap: () => Navigator.pop(ctx, 'camera')),
          ],
          if (store.hasPhoto) ...[
            const SizedBox(height: 10),
            GhostButton(label: 'Remove photo', icon: Icons.delete_outline_rounded, onTap: () => Navigator.pop(ctx, 'remove')),
          ],
        ]),
      ),
    ),
  );
  if (source == null || !context.mounted) return;

  if (source == 'remove') {
    await store.clearPhoto();
    if (context.mounted) showToast(context, 'Photo removed');
    return;
  }

  try {
    final file = await ImagePicker().pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 75,
      preferredCameraDevice: CameraDevice.front,
    );
    if (file == null) return; // cancelled
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > 400 * 1024) {
      if (context.mounted) showToast(context, 'That photo is too big. Try another one.');
      return;
    }
    await store.setPhoto(bytes);
    if (!context.mounted) return;
    showToast(context, 'Looking good!');
    await announceBadges(context, store);
  } catch (_) {
    if (context.mounted) showToast(context, 'Couldn’t open your photos. Check the app’s permissions.');
  }
}
