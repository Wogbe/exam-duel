import 'package:flutter/material.dart';

/// Motion and dark-mode switches shared by the study screens. The app (or the preview) puts one
/// above its screens. Without one, screens fall back to motion on and the system's reduce-motion.
class ViewSettings extends InheritedWidget {
  const ViewSettings({
    super.key,
    required this.motionOn,
    required this.dark,
    required this.toggleMotion,
    required this.toggleDark,
    required super.child,
  });

  final bool motionOn, dark;
  final VoidCallback toggleMotion, toggleDark;

  static ViewSettings? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ViewSettings>();

  static ViewSettings of(BuildContext context) => maybeOf(context)!;

  @override
  bool updateShouldNotify(ViewSettings old) => old.motionOn != motionOn || old.dark != dark;
}

extension ViewSettingsX on BuildContext {
  /// False when motion is switched off or the OS asks for reduced motion.
  bool get motion => (ViewSettings.maybeOf(this)?.motionOn ?? true) && !MediaQuery.disableAnimationsOf(this);
}
