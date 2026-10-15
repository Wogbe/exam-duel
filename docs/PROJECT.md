# Exam Duel plan
Updated: 2026-10-12
Stage: Build   Current focus: UI milestone complete; owner to review and choose next (open ui-review items, app name, real device test, backend)

Direction: AI-powered gamified learning for anyone, user-supplied content. UI first; no Supabase/auth/backend until the owner asks.
Signature feature: Snap -> Map -> Duel.

## Milestones
### UI: Snap -> Map -> Duel real screens (Design -> Build)
- [x] Owner reviews prototype and gives a verdict — keep as is (2026-10-12)
- [ ] Pick app name (Study Duel / Hoot / Owlduel) — deferred by owner, decide later; working name Exam Duel
- [x] Commit current work — committed dc67ee7 (docs/STATUS.md left out: shows a local path)
- [x] Snap screen (typed + paste real; photo/file buttons removed 2026-10-15 as they only faked a build; wait/error/offline states, tested; ui-review and security-check run 2026-10-12): type/paste/snap input, offline-safe, with AI-wait error and offline states — done when it runs on sample data and failure states show; run ui-review
- [x] Map screen + topic tiles: tiles, readiness and Eve's suggestion update from duel/solo results via `progress` (in memory); "Show me where" and Report were already on the duel reveal. ui-review and security-check run; open items below
- [x] Solo practice and Duel/Results wired to the map: tile -> solo/duel -> results -> map shows the new level (end-to-end test). Streak unified, caption and Eve prompt fixed. Questions are still the same 3 samples for every tile (the AI writes them per topic later)
- [x] Accessibility fixes: `Pressable` is keyboard-focusable (Tab, Enter/Space, visible ring); TimerRing low-time text 4.6:1 in light mode (tests); ui-review and security-check run. Not yet checked: a full keyboard-only walk through the app, 48 dp target size on all 35 Pressables
- [x] Neutral starter content and README rewrite: 21 Ghana/West-Africa-specific questions and 8 facts replaced with general-knowledge ones (still 99 questions, 38 facts; seed.sql regenerated); README now describes the learning-app direction, the preview and how to run it. Kept: Mansa Musa, Kilimanjaro, Nile, Sahara, Wakanda (world knowledge). Content only, so no security-check

### UI review leftovers (fixed 2026-10-12)
- Leave-duel confirms once an answer is given; light haptic on the last 3 seconds; reveal card scrolls into view
- Dot chart has a spoken summary; stat cards and topic hero grow with text size; "Preview uses…" copy reworded
- Timer warn colour is `Pastel.coralDeep`; its scale animation respects reduce-motion
- Lime "Show me where" box is solid lime (the 45% version was 3.9:1 in dark mode)
- Not changed: readiness already counts up (it counts from 0 on a freshly opened map); timer label does not announce every tick (no live region)

### Home ui-review (open)
- Your maps shows only 3 with no "See all"; on web it sits below the fold; list could be a 2-3 column grid at wide widths
- Greeting headline and the Learn anything hero say nearly the same thing on phone
- Hero and Play with friends tile share the accent colour; Eve's gaze target is hard-coded; no empty-state hint for maps on phone

### Before real user content goes into maps (security-check, 2026-10-12)
- Saved maps/progress are plain JSON in shared_preferences: exclude them from Android backup (`allowBackup` / data extraction rules) or move to file/DB storage
- Map ids must be unique per generated map (UUID); maps and progress are keyed by `StudySet.id`
- `MapBuilder` becomes a trust boundary: length limit on the notes, validate the AI's output, keep notes apart from instructions

## Blocked on the owner
- Permission to commit (app name is deferred).
- To-do: `sudo apt remove adb` in a real terminal.

## Decisions
- 2026-10-12 Pivot to global AI learning app, user-supplied content (not exam-only, not country-specific).
- 2026-10-12 UI before backend (identity and look first).
- 2026-10-12 Signature feature: Snap -> Map -> Duel (Sure-or-Maybe betting and Eve-as-rival kept as optional ideas).
- 2026-10-12 Kente details replaced with the app's own pastel colours (no country-specific styling).

- 2026-10-12 Owner approves the prototype look as is; UI tweaks later when they are not satisfied.
- 2026-10-12 App name deferred; keep working name Exam Duel.
- 2026-10-12 Snap -> Map -> Duel is linked into the app: a "Learn anything" card on Home (phone and wide layouts) opens Snap; the app passes the Reduce motion / dark settings to the study screens. Still sample data, in-memory progress; map nav Duels/Me show "Coming soon".
- 2026-10-12 Saved maps + resume: maps (as JSON) and progress persist in shared_preferences (`state/library.dart`, `state/progress.dart`, loaded in main); Home shows "Your maps" (3 most recent). No delete yet; a corrupt save is skipped, not fatal.
- 2026-10-12 Home reframed around learning: headline "What are you learning today?", Learn anything is the hero, then Your maps, then Play with friends / Join a room / Quick Fire / Fact of the day tiles; How it works describes Snap -> Map -> Duel. Maps can be removed (menu, with Undo; progress is kept). Owner to react to the preview.
- 2026-10-12 Prototype graduated into the app's folders (screens, widgets, data, state, theme); no 'proto' names left. Preview entry is `lib/main_preview.dart`. Behaviour unchanged.
- 2026-10-14 v0.2.0 party-game upgrades on owner request: sound effects (`lib/services/fx.dart`, off in tests until `main()` calls `Fx.init`) and a Sound toggle; fact reactions cheer and pay +5 XP once a day; "Another fact"; random unread fact per player (no longer one per day for everyone); profile photos (base64 in prefs, shared per room via `room_player_photos`); share score cards (share_plus, RepaintBoundary capture); Bible category (64 questions) and 130 more questions overall; Survival mode and a 50/50 lifeline in solo; 15 badges paying 20 coins.
- 2026-10-14 Question variety: migration `20261014000000_variety_photos.sql` tracks seen questions per player (`user_seen_questions`) so games prefer unseen ones; solo pulls from the shared bank via `practice_questions`; `import_opentdb()` + pg_cron grow the bank from opentdb.com (CC BY-SA 4.0, credited in Profile). `seed.sql` now only adds missing questions (no delete), so it keeps seen history.
- 2026-10-14 v0.2.1: `join_room` makes nicknames unique per room ("Kofi 2") and spreads avatar colours, both in `20261014120000_unique_names.sql`; helpers `_unique_nickname` / `_free_avatar` are revoked from clients. The renamed player gets one toast in the room. Bible grew to 166 questions (331 in all).
- 2026-10-15 Nothing in the study flow pretends any more. Snap's photo and file tiles are gone (no OCR or AI behind them); paste is now one clear card. The map's FloatingNav opens real screens: Duels to HostSetupScreen, Me to ProfileScreen. Eve's wardrobe tiles are taller, with an icon and pastel per outfit (`_wardrobe` in profile_screen.dart) and a Wearing / Tap to wear / price line.
- 2026-10-15 Bundled bank grew to 693 questions: Bible 375, Random 174. Wardrobe tiles rebuilt: solid pastel card, white icon window, one status pill. The dot pattern is gone (it fought the rest of the UI), and the grid uses `mainAxisExtent: 178` instead of `childAspectRatio`, so every tile — "No outfit" included — is exactly the same size on every screen.
- 2026-10-15 The fact of the day shares as a picture, not text: `ShareFactCard` (lib/widgets/fact_card.dart) is the same fixed 360x450 shape as `ShareScoreCard`, laid out off-screen in a `RepaintBoundary` and captured by `shareCard`, so a shared fact and a shared score look like a pair.
- 2026-10-15 v0.2.4 cheap batch: join-by-link (`lib/services/deep_link.dart`, read in `main()`, routed from splash and onboarding; Android gets an unverified https intent-filter written by `tool/build_android.sh`, no new package), last-room chip on Join, level-up sheet inside `announceBadges`, volume slider, About screen, per-category question counts in host setup.
- 2026-10-15 Marketing art in `marketing/`, drawn from the app's own palette with Eve ported to SVG: og.png (1200x630), status.png (1080x1920), square.png (1080x1080) and three phone promo frames. `tool/build_web.sh` now publishes og.png and writes Open Graph and Twitter tags, so a shared link stops previewing blank. Type is Poppins and Inter, standing in for Urbanist and Figtree, which are not installed here.

## Release gates
- [ ] Builds cleanly; analyze/lint passes (3 info issues open); tests pass
- [ ] security-check clean
- [ ] No secrets in git
- [ ] Store requirements (store-checklist)
- [ ] Versioning/changelog, rollback
- [ ] Production backend ready (deferred)
- [ ] Owner tried on a real device
