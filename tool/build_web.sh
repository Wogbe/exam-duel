#!/usr/bin/env bash
# Builds Exam Duel for the web (same code as the phone app).
#
# Usage (from the project folder):
#   ./tool/build_web.sh                 # site served at the domain root
#   BASE_HREF=/exam-duel/ ./tool/build_web.sh   # GitHub Pages project site
# Online rooms (optional): export SUPABASE_URL and SUPABASE_ANON_KEY first.
#
# Output: build/web/  (upload this folder to any static host)
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Exam Duel"
BASE_HREF="${BASE_HREF:-/}"

# 1. Create the web/ folder once.
# All three platforms are created together because the icon tool writes to each.
if [ ! -d android ] || [ ! -d ios ] || [ ! -d web ]; then
  echo "› Creating platform project files"
  flutter create . --platforms=android,ios,web --project-name exam_duel --org com.mctech
fi
if [ -f test/widget_test.dart ] && grep -q "MyApp" test/widget_test.dart; then
  rm test/widget_test.dart
fi

# 2. Title, install name, colours and a loading screen that matches the app.
python3 - "$APP_NAME" <<'PY'
import json, re, sys
name = sys.argv[1]

p = 'web/index.html'
s = open(p).read()
s = re.sub(r'<title>.*?</title>', f'<title>{name}</title>', s, count=1, flags=re.S)
s = re.sub(r'(<meta name="apple-mobile-web-app-title" content=")[^"]*', rf'\g<1>{name}', s)
s = re.sub(r'(<meta name="description" content=")[^"]*', r'\g<1>Trivia with friends, hosted by Eve the owl.', s)
if 'id="ed-loading"' not in s:
    loader = (
        '<style>html,body{margin:0;height:100%;background:#F4F2EC}'
        '#ed-loading{position:fixed;inset:0;display:flex;flex-direction:column;align-items:center;'
        'justify-content:center;gap:16px;font:600 16px system-ui,sans-serif;color:#15202B}'
        '#ed-loading img{width:96px;height:96px;border-radius:22px;animation:ed 1.4s ease-in-out infinite}'
        '@keyframes ed{50%{transform:translateY(-8px)}}</style>'
    )
    s = s.replace('</head>', loader + '\n</head>', 1)
    s = s.replace('<body>', '<body>\n  <div id="ed-loading"><img src="icons/Icon-192.png" alt=""><span>Loading Exam Duel…</span></div>', 1)
    # Hide the loader once Flutter draws its first frame.
    s = s.replace('</body>', '<script>window.addEventListener("flutter-first-frame",function(){var l=document.getElementById("ed-loading");if(l)l.remove();});</script>\n</body>', 1)
open(p, 'w').write(s)

p = 'web/manifest.json'
m = json.load(open(p))
m.update(name=name, short_name=name, description='Trivia with friends, hosted by Eve the owl.',
         background_color='#F4F2EC', theme_color='#15202B', orientation='portrait-primary')
json.dump(m, open(p, 'w'), indent=2)
PY

# 3. Packages, icons (favicon + install icons), build.
flutter pub get
dart run flutter_launcher_icons

DEFINES=()
if [ -n "${SUPABASE_URL:-}" ] && [ -n "${SUPABASE_ANON_KEY:-}" ]; then
  DEFINES+=(--dart-define=SUPABASE_URL="$SUPABASE_URL" --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY")
  echo "› Online rooms: ON"
else
  echo "› Online rooms: OFF (no SUPABASE_URL / SUPABASE_ANON_KEY set)"
fi
flutter build web --release --base-href "$BASE_HREF" "${DEFINES[@]+"${DEFINES[@]}"}"

echo
echo "✓ Web app ready in build/web/"
