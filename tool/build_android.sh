#!/usr/bin/env bash
# Builds the Exam Duel Android APK with the official icon.
#
# Usage (from the project folder):
#   ./tool/build_android.sh
# Online rooms (optional): set these first, or the APK runs in offline mode.
#   export SUPABASE_URL=https://YOUR-PROJECT.supabase.co
#   export SUPABASE_ANON_KEY=YOUR-ANON-KEY
#
# Output: build/app/outputs/flutter-apk/app-release.apk
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Exam Duel"
ORG="com.mctech"            # app id becomes com.mctech.exam_duel

# 1. Create the android/ folder once. Existing lib/ and pubspec.yaml are kept.
if [ ! -d android ]; then
  echo "› Creating Android project files"
  flutter create . --platforms=android,ios --project-name exam_duel --org "$ORG"
fi
# flutter create adds a counter-app test that doesn't match this app.
if [ -f test/widget_test.dart ] && grep -q "MyApp" test/widget_test.dart; then
  rm test/widget_test.dart
fi

# 2. App name on the home screen + internet permission for release builds.
MANIFEST=android/app/src/main/AndroidManifest.xml
python3 - "$MANIFEST" "$APP_NAME" <<'PY'
import re, sys
path, name = sys.argv[1], sys.argv[2]
s = open(path).read()
s = re.sub(r'android:label="[^"]*"', f'android:label="{name}"', s, count=1)
if 'android.permission.INTERNET' not in s:
    s = s.replace('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application', 1)
open(path, 'w').write(s)
PY

# 3. Packages and the launcher icon (adaptive + themed monochrome).
flutter pub get
dart run flutter_launcher_icons

# 4. Build. Signed with the debug key: fine for sharing with friends.
#    For Google Play, set up an upload key first (see README).
DEFINES=()
if [ -n "${SUPABASE_URL:-}" ] && [ -n "${SUPABASE_ANON_KEY:-}" ]; then
  DEFINES+=(--dart-define=SUPABASE_URL="$SUPABASE_URL" --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY")
  echo "› Online rooms: ON"
else
  echo "› Online rooms: OFF (no SUPABASE_URL / SUPABASE_ANON_KEY set)"
fi
flutter build apk --release "${DEFINES[@]+"${DEFINES[@]}"}"

echo
echo "✓ APK ready: build/app/outputs/flutter-apk/app-release.apk"
