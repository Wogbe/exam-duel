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
- [x] Snap screen (typed + paste real, photo/file still sample stubs; wait/error/offline states, tested; ui-review and security-check run 2026-10-12): type/paste/snap input, offline-safe, with AI-wait error and offline states — done when it runs on sample data and failure states show; run ui-review
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
- 2026-10-12 Prototype graduated into the app's folders (screens, widgets, data, state, theme); no 'proto' names left. Preview entry is `lib/main_preview.dart`. Behaviour unchanged.

## Release gates
- [ ] Builds cleanly; analyze/lint passes (3 info issues open); tests pass
- [ ] security-check clean
- [ ] No secrets in git
- [ ] Store requirements (store-checklist)
- [ ] Versioning/changelog, rollback
- [ ] Production backend ready (deferred)
- [ ] Owner tried on a real device
