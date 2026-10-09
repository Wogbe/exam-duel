# Exam Duel

A party trivia game for friends, hosted by Eve the owl. Built with Flutter and Supabase, following the Exam Duel design (pastel bento, Urbanist + Figtree, Eve's moods and outfits).

## What's in it

- **Play with friends (online rooms):** the host creates a room and shares a 5-letter code (copy or WhatsApp). 2–12 friends join from their own phones. Everyone gets the same question at the same moment, with a live timer, "who has answered" avatars, emote reactions ("Chale!", "Eii!"), a reveal with a mini leaderboard, a podium with confetti, and rematches.
- **Fair scoring:** the server scores every answer with its own clock: 500 points for a correct answer, up to 500 more for speed, and +10% per streak step (max +50%). Players can't see the answer until the reveal.
- **Ask Eve (AI questions):** the host types a topic (e.g. "Afrobeats", "Premier League") and Eve writes fresh questions with Claude. The bank fills the rest.
- **Question bank:** 99 hand-checked questions in 8 categories: Ghana & Africa, History, Science, Geography, Sports, Music & Movies, Tech, Random.
- **Fact of the Day:** a flip card when you open the app, with "Knew it" / "Mind blown" reactions and WhatsApp sharing. Reading it keeps your streak.
- **Streaks:** a weekly strip, celebration screen, and streak freezes (earn one per 7 days, hold 2).
- **Quick Fire (solo, offline):** 60 seconds, combos, personal best.
- **Progress:** XP and levels, coins, and Eve's wardrobe (glasses, kente scarf, headphones, graduation cap, jersey, tie).
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
  main.dart, app.dart, config.dart
  theme/app_theme.dart        colours, accents, type styles (from the design system)
  data/
    models.dart               Question, Room, Player, Category…
    local_bank.dart           bundled questions + facts (offline)
    player_store.dart         profile, streak, XP, coins, outfits, settings
    game_repository.dart      Supabase RPCs, realtime streams, emotes, AI
  state/
    providers.dart            Riverpod providers
    room_controller.dart      live room state, timers, auto reveal/advance
  widgets/
    eve/eve.dart              Eve, animated CustomPainter port of the design SVG
    common.dart               spring buttons, timer ring, confetti, kente bar…
    week_strip.dart
  screens/                    splash, onboarding, fact, streak, home, host setup,
                              join, room (lobby/game/results), solo, profile
assets/data/                  questions.json (99), facts.json (38)
assets/icon/                  app icon: master, adaptive layers, monochrome
.github/workflows/            android-apk.yml (cloud APK build)
tool/build_android.sh         one-command APK build
supabase/
  migrations/…_init.sql       schema, RLS, game functions, realtime
  seed.sql                    generated question bank
  functions/generate-questions/index.ts
tool/build_seed.mjs
test/player_store_test.dart   streak, freeze, wardrobe, settings tests
```

## Adding content

- **Questions:** add lines to `assets/data/questions.json` in the form `{"c":"science","q":"…","a":"correct","w":["wrong1","wrong2","wrong3"]}`, then re-run `node tool/build_seed.mjs` and the seed SQL. Options are shuffled automatically.
- **Facts:** add `{"c":"ghana","t":"…"}` to `assets/data/facts.json`. One fact per day, the same for everyone.
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
- The Flutter code was written and reviewed without a Flutter SDK, which couldn't be installed in the build environment. Run `flutter analyze` and `flutter test` first, and fix any small API mismatches with your Flutter version.

## Ideas for next

Sound effects, push invites, a deep link that opens the join screen with the code filled in, a Rive version of Eve, category leaderboards, and a daily challenge (same 10 questions for everyone).
