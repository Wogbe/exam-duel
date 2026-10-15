import 'package:flutter/widgets.dart';

/// A room code that came in from a shared link, waiting to be used once.
String? _pending;

/// A link that opens the join screen with the code already filled in.
String joinLink(String code) => 'https://wogbe.github.io/exam-duel/?code=${code.toUpperCase()}';

/// Reads `?code=ABCDE` from the link that opened the app.
///
/// On the web that is the address bar. On Android it is the intent Flutter
/// hands over, which needs the intent-filter that `tool/build_android.sh`
/// writes into the manifest. Call once, from `main()`, after the binding is
/// ready. Never throws: a malformed link simply leaves no code waiting.
void readLinkCode() {
  try {
    _pending = _codeIn(Uri.base) ?? _codeIn(Uri.tryParse(WidgetsBinding.instance.platformDispatcher.defaultRouteName));
  } catch (_) {
    _pending = null;
  }
}

String? _codeIn(Uri? uri) {
  final raw = uri?.queryParameters['code'];
  if (raw == null) return null;
  final code = raw.trim().toUpperCase();
  // Room codes are five letters or digits. Anything else is somebody's typo.
  return RegExp(r'^[A-Z0-9]{5}$').hasMatch(code) ? code : null;
}

/// True while a code from a link is still waiting.
bool get hasLinkCode => _pending != null;

/// Returns the waiting code and forgets it, so one link opens one room.
String? takeLinkCode() {
  final code = _pending;
  _pending = null;
  return code;
}
