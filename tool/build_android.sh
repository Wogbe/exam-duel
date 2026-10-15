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
# Where the web app lives. Tapping one of its room links opens this app.
LINK_HOST="${LINK_HOST:-wogbe.github.io}"
LINK_PATH="${LINK_PATH:-/exam-duel}"

# 1. Create the android/ folder once. Existing lib/ and pubspec.yaml are kept.
# All three platforms are created together because the icon tool writes to each.
if [ ! -d android ] || [ ! -d ios ] || [ ! -d web ]; then
  echo "› Creating platform project files"
  flutter create . --platforms=android,ios,web --project-name exam_duel --org "$ORG"
fi
# flutter create adds a counter-app test that doesn't match this app.
if [ -f test/widget_test.dart ] && grep -q "MyApp" test/widget_test.dart; then
  rm test/widget_test.dart
fi

# 2. App name, internet permission, and "open a shared room link in the app".
MANIFEST=android/app/src/main/AndroidManifest.xml
python3 - "$MANIFEST" "$APP_NAME" "$LINK_HOST" "$LINK_PATH" <<'PY'
import re, sys
path, name, host, prefix = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
s = open(path).read()
s = re.sub(r'android:label="[^"]*"', f'android:label="{name}"', s, count=1)
if 'android.permission.INTERNET' not in s:
    s = s.replace('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application', 1)

# Tapping https://<host><prefix>?code=ABCDE offers to open Exam Duel.
# autoVerify is left off on purpose: verifying needs the release signing
# fingerprint in a .well-known/assetlinks.json file, which this debug-signed
# build has not got. Without it Android shows a chooser, which still works.
if 'flutter_deeplinking_enabled' not in s:
    block = (
        '\n                <meta-data android:name="flutter_deeplinking_enabled" android:value="true"/>\n'
        '                <intent-filter>\n'
        '                    <action android:name="android.intent.action.VIEW"/>\n'
        '                    <category android:name="android.intent.category.DEFAULT"/>\n'
        '                    <category android:name="android.intent.category.BROWSABLE"/>\n'
        f'                    <data android:scheme="https" android:host="{host}" android:pathPrefix="{prefix}"/>\n'
        '                </intent-filter>'
    )
    # Put it at the end of the MainActivity <activity> block.
    m = re.search(r'(<activity[^>]*\.MainActivity[^>]*>)(.*?)(</activity>)', s, re.S)
    if m:
        s = s[:m.end(2)] + block + '\n            ' + s[m.end(2):]
    else:
        print('! Could not find MainActivity; deep links not set up', file=sys.stderr)
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
