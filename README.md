# Exam Duel

An AI-powered, gamified learning app for anyone learning anything, anywhere, hosted by Eve the owl. You bring your own material (type a topic, paste notes, snap a photo), Eve turns it into a map of topics, and you practise alone or duel a friend to turn each topic from New to Ready. Built with Flutter and Supabase (pastel bento, Urbanist + Figtree, Eve's moods and outfits).

## Where the project is

The new direction, **Snap → Map → Duel**, runs on sample data. In the app it opens from the big **Learn anything** card at the top of Home (the party game is now two tiles below it: Play with friends and Join a room); the preview below opens it on its own. There is no AI or backend behind it yet; that comes after the look and feel are settled. The plan and decisions live in `docs/PROJECT.md`.

```bash
flutter run -d chrome -t lib/main_preview.dart
```

- **Snap:** type or paste what you're learning (photo and file are sample stubs). It has waiting, offline and error states; add `?fail=offline` or `?fail=error` to the web URL to preview them.
- **Map:** one tile per topic (New, Shaky, Solid, Ready). Tiles, readiness and Eve's suggestion update as you practise.
- **Your maps:** every map you build is saved on the device with its progress, and Home lists the three most recent under "Your maps" so you can pick up where you left off. The "…" menu on a map removes it, with Undo. (The preview entry keeps everything in memory only.)
- **Topic → Duel or solo → Results:** two right answers move a topic up a level. "Show me where" shows the line in your material that backs the answer, and Report flags a question.
- **Deep links on web:** `?screen=board|snap|thinking|map|topic|duel|results&set=bio|fr|drive&dark=1&motion=0`.

The sections below describe the party-trivia game and Supabase backend that are already in the repo. They are on hold and will be reshaped around the new direction.

## What's in the party game today

- **Play with friends (online rooms):** the host creates a room and shares a 5-letter code (copy or WhatsApp). 2–12 friends join from their own phones. Everyone gets the same question at the same moment, with a live timer, "who has answered" avatars, emote reactions ("👏 Nice!", "😮 Whoa!"), a reveal with a mini leaderboard, a podium with confetti, and rematches.
- **Fair scoring:** the server scores every answer with its own clock: 500 points for a correct answer, up to 500 more for speed, and +10% per streak step (max +50%). Players can't see the answer until the reveal.
- **Ask Eve (AI questions):** the host types a topic (e.g. "Space exploration", "Premier League") and Eve writes fresh questions with Claude. The bank fills the rest.
- **Question bank:** 99 starter questions in 7 categories: History, Science, Geography, Sports, Music & Movies, Tech, Random. They are general-knowledge and not tied to one country.
- **Fact of the Day:** a flip card when you open the app, with "Knew it" / "Mind blown" reactions and WhatsApp sharing. Reading it keeps your streak.
- **Streaks:** a weekly strip, celebration screen, and streak freezes (earn one per 7 days, hold 2).
- **Quick Fire (solo, offline):** 60 seconds, combos, personal best.
- **Progress:** XP and levels, coins, and Eve's wardrobe (glasses, striped scarf, headphones, graduation cap, jersey, tie).
- **Settings:** dark mode, Reduce motion, haptics, and Eve's eye colour (Honey, Aqua, Lavender).

## 1. Run it (offline mode, 5 minutes)

You need Flutter 3.27 or newer.

```bash
cd exam_duel
flutter create . --platforms=android,ios --project-name exam_duel --org com.mctech   # adds android/ and ios/; keeps lib/
rm -f test/widget_test.dart          # the counter-app test flutter create adds
dart run flutter_launcher_icons      # applies the app icon
flutter pub get
flutter analyze
flutter test
flutter run
```

Without Supabase keys, the app runs offline: onboarding, Fact of the Day, streaks, Quick Fire, profile and wardrobe all work. "Play with friends" shows a setup notice.

## 2. Turn on online rooms (Supabase, free tier is enough)

1. Create a project at supabase.com.
2. **Auth › Providers (or Sign In / Up) › Anonymous sign-ins:** turn it on. Players never need an account.
3. **Create the database:** open the SQL editor, paste `supabase/migrations/20261009000000_init.sql`, and run it. With the Supabase CLI you can instead run `supabase init` (keep the existing files), `supabase link`, then `supabase db push`.
4. **Load the questions:** run `node tool/build_seed.mjs` (it regenerates `supabase/seed.sql` from `assets/data/questions.json`), then paste `supabase/seed.sql` into the SQL editor and run it.
5. **Check Realtime:** the migration adds `rooms` and `room_players` to the `supabase_realtime` publication. In the dashboard, Database › Publications should list both.
6. Run the app with your project URL and anon key (Project Settings › API):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY
```

Test with two phones (or a phone and an emulator): host on one, join with the code on the other.

## 3. Turn on "Ask Eve" (AI questions)

```bash
supabase functions deploy generate-questions
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
# optional: supabase secrets set ANTHROPIC_MODEL=<model id>
```

The function checks the caller is signed in and is the room host. It limits each user to 120 AI questions per hour, validates every question (4 distinct options, 1 answer), and stores them as a one-game batch. If you skip this step, rooms still work with the bank. Hosts just see a toast if they type a topic.

## 4. Build the Android APK

The app icon ("Face-off": two rival eyes on lime and lavender) lives in `assets/icon/`. The build script applies it as a full Android adaptive icon, with a themed monochrome version for Android 13+.

**Option A: on your computer.** You need Flutter, plus Android Studio for the Android SDK. Run `flutter doctor` until the Android line is green, then:

```bash
export SUPABASE_URL=https://YOUR-PROJECT.supabase.co    # optional, for online rooms
export SUPABASE_ANON_KEY=YOUR-ANON-KEY                  # optional
./tool/build_android.sh
```

The script:
- creates the platform folders;
- names the app "Exam Duel" (app id `com.mctech.exam_duel`);
- adds the internet permission;
- generates the icons;
- builds the APK.

The output is `build/app/outputs/flutter-apk/app-release.apk`.

**Option B: in the cloud with GitHub (no installs).**
1. Push this folder to a new GitHub repository.
2. Optional: add `SUPABASE_URL` and `SUPABASE_ANON_KEY` under Settings › Secrets and variables › Actions.
3. Open the **Actions** tab, then **Android APK**, then **Run workflow**. A run takes about 6–8 minutes.
4. Download **exam-duel-apk** from the finished run.

**Installing:** send the APK to a phone (WhatsApp, Drive, USB), open it, and allow "Install unknown apps" when Android asks.

**Google Play:** the APK above is signed with Flutter's debug key, which is fine for sharing with friends. For the Play Store, create an upload key and a `key.properties` file (see Flutter's "Build and release an Android app" guide), then run `flutter build appbundle`.

**Other notes:**
- **Fonts:** Google Fonts download at first launch and are cached afterwards.
- **Room cleanup:** `select public.cleanup_rooms();` removes rooms older than a day. Schedule it with pg_cron (see the comment in the migration).

## 5. Web app (same code, GitHub Pages)

The web version is the same Flutter app with its own desktop layout, and phone and browser players can join the same rooms. On screens 900 px or wider:

- **Home** becomes a full page: a top bar with navigation, streak and coins; a big "Play with friends" card where Eve follows the mouse; a bento grid with Join, Quick Fire, Fact of the day, level and "How it works".
- **Lobby** shows the room code and controls on the left, and players on the right.
- **Live game** puts the question and a 2×2 answer grid on the left, with a live scoreboard and emotes on the right. Players can answer with the keys 1–4 or A–D.
- **Forms** (onboarding, join, host setup, profile, Quick Fire) are centred columns, and the grids get more columns.
- **Buttons and cards** lift on hover and show a pointer cursor.

1. Add `.github/workflows/web.yml` to the repo (create it on GitHub if the upload skips hidden folders).
2. Go to **Settings › Pages** and set **Source** to **GitHub Actions**.
3. Open **Actions › Web app › Run workflow**. Every later push to `main` redeploys automatically.
4. The site goes live at `https://<your-username>.github.io/<repo-name>/`.

To build it locally, run `BASE_HREF=/ ./tool/build_web.sh` and upload `build/web/` to any static host (Netlify, Vercel, Firebase Hosting).

## How online play works

```
host: create_room ─► lobby ◄─ join_room (friends, by code)
host: start_game  ─► picks N questions (AI batch first, then bank)
every client:     ─► sees status=question, fetches room_questions[idx]
player:           ─► submit_answer → server scores with its own clock
all answered OR timer ends ─► reveal (correct answer copied to players)
host after 4.5 s  ─► next_question … ─► finished ─► rematch = start_game
```

- Clients never write tables. Every change goes through `security definer` functions in the migration.
- Answer keys live in `room_question_keys`, which no client can read. A question row is only visible once the room reaches it.
- Any player can trigger the reveal when time runs out, and anyone can advance after 12 s if the host drops. If the host leaves, the next player becomes host.
- Clients sync to server time (`server_now()`), so timers match on every phone.

## Project layout

```
lib/
  main_preview.dart           entry point for the Snap → Map → Duel preview (sample data)
  preview/style_board.dart    one-page visual direction, the preview's home page
  main.dart, app.dart, config.dart
  theme/app_theme.dart        colours, accents, type styles (from the design system)
  theme/mastery.dart          New / Shaky / Solid / Ready and their colours
  data/
    models.dart               Question, Room, Player, Category…
    study_set.dart            StudySet, StudyTopic, StudyQuestion (the learning map's content)
    sample_sets.dart          sample sets the preview runs on
    map_builder.dart          MapBuilder seam where the AI call will plug in, plus the sample builder
    duel_result.dart          how a duel or solo round went
    local_bank.dart           bundled questions + facts (offline)
    player_store.dart         profile, streak, XP, coins, outfits, settings
    game_repository.dart      Supabase RPCs, realtime streams, emotes, AI
  state/
    providers.dart            Riverpod providers
    room_controller.dart      live room state, timers, auto reveal/advance
    progress.dart             topic mastery and readiness earned so far (saved on the device)
    library.dart              the maps you have built, newest first (saved on the device)
  widgets/
    eve/eve.dart              Eve, animated CustomPainter port of the design SVG
    common.dart               spring buttons, timer ring, confetti, colour-stripe bar…
    week_strip.dart
    study_widgets.dart        pills, number display, nav, skeletons and motion helpers for the study screens
    mastery_tile.dart         one topic tile on the map
    view_settings.dart        motion and dark-mode switches, and `context.motion`
  screens/                    splash, onboarding, fact, streak, home, host setup,
                              join, room (lobby/game/results), solo, profile,
                              snap, map, topic, duel, results (Snap → Map → Duel)
assets/data/                  questions.json (99), facts.json (38)
assets/icon/                  app icon: master, adaptive layers, monochrome
.github/workflows/            android-apk.yml (cloud APK build)
tool/build_android.sh         one-command APK build
tool/build_web.sh             one-command web build
lib/widgets/responsive.dart   breakpoint, centred layouts, keyboard answers
.github/workflows/web.yml     web build + GitHub Pages deploy
supabase/
  migrations/…_init.sql       schema, RLS, game functions, realtime
  seed.sql                    generated question bank
  functions/generate-questions/index.ts
tool/build_seed.mjs
supabase/tests/               SQL rules tests (PGlite)
test/                         streak/wardrobe, Snap states, map progress, room controller, keyboard and contrast
```

## Adding content

- **Questions:** add lines to `assets/data/questions.json` in the form `{"c":"science","q":"…","a":"correct","w":["wrong1","wrong2","wrong3"]}`, then re-run `node tool/build_seed.mjs` and the seed SQL. Options are shuffled automatically.
- **Facts:** add `{"c":"science","t":"…"}` to `assets/data/facts.json`. One fact per day, the same for everyone.
- **Emotes:** edit `_emotes` in `lib/screens/room_screen.dart`.

## Testing status

- The SQL migration was run on PostgreSQL 16 against stubs of Supabase's auth and realtime setup. These all passed:
  - creating, joining and starting rooms;
  - blocking a non-host from starting;
  - keeping answer keys hidden;
  - scoring, and rejecting duplicate and late answers;
  - early reveal when everyone has answered, and timeout reveal;
  - host advance and the 12 s fallback;
  - rematch, AI batch ordering, host hand-off and room cleanup.
- The Flutter code now runs: `flutter analyze` reports 3 info-level notices and `flutter test` passes.
- The preview has widget tests for Snap's error states, map progress (including a tile → solo practice → results → map flow), keyboard use of buttons, and timer contrast.
- The room controller has unit tests against a fake repository (timers, reveal and advance, answers, rematch, removal).
- `supabase/tests/` runs the migration on an in-memory Postgres (PGlite) and checks the game rules: joining and limits, host-only actions, hidden answers, scoring and streaks, early and timeout reveal, host hand-off and cleanup. Run `cd supabase/tests && npm install && npm test`.
- CI runs `flutter analyze` and `flutter test` before each build, and the SQL tests in their own workflow.
- Not tried yet: a real device, and the online rooms against a live Supabase project (PGlite is not a full Supabase, so Realtime and the edge function are untested).

## Ideas for next

Sound effects, push invites, a deep link that opens the join screen with the code filled in, a Rive version of Eve, category leaderboards, and a daily challenge (same 10 questions for everyone).
