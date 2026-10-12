# Exam Duel plan
Updated: 2026-10-12
Stage: Build   Current focus: Solo practice and Duel/Results wiring (topic param done; per-topic questions still sample)

Direction: AI-powered gamified learning for anyone, user-supplied content. UI first; no Supabase/auth/backend until the owner asks.
Signature feature: Snap -> Map -> Duel.

## Milestones
### UI: Snap -> Map -> Duel real screens (Design -> Build)
- [x] Owner reviews prototype and gives a verdict — keep as is (2026-10-12)
- [ ] Pick app name (Study Duel / Hoot / Owlduel) — deferred by owner, decide later; working name Exam Duel
- [x] Commit current work — committed dc67ee7 (docs/STATUS.md left out: shows a local path)
- [x] Snap screen (typed + paste real, photo/file still sample stubs; wait/error/offline states, tested; ui-review and security-check run 2026-10-12): type/paste/snap input, offline-safe, with AI-wait error and offline states — done when it runs on sample data and failure states show; run ui-review
- [x] Map screen + topic tiles: tiles, readiness and Eve's suggestion update from duel/solo results via `progress` (in memory); "Show me where" and Report were already on the duel reveal. ui-review and security-check run; open items below
- [ ] Solo practice and Duel/Results screens wired to the map — done when a tile can be practised solo and sent as a duel on sample data; ui-review
- [ ] Accessibility fixes: keyboard/focus on `Pressable`, TimerRing low-time contrast — done when keyboard-only flow works and contrast passes; ui-review
- [ ] Neutral starter content (less West-Africa-leaning) and README rewrite to new direction — done when no regional bias remains; security-check after code tasks

### Open from the Map ui-review
- Streak shown as 4 / "4-day" / "5 days" on different screens; use one value
- "Sample: how your map looks…" caption stays after real progress
- Eve prompt when nothing is shaky is a dead button with no next action
- Readiness number jumps without counting up; dot chart has no semantics

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

## Release gates
- [ ] Builds cleanly; analyze/lint passes (3 info issues open); tests pass
- [ ] security-check clean
- [ ] No secrets in git
- [ ] Store requirements (store-checklist)
- [ ] Versioning/changelog, rollback
- [ ] Production backend ready (deferred)
- [ ] Owner tried on a real device
