# Exam Duel plan
Updated: 2026-10-12
Stage: Build   Current focus: turn the approved prototype into the real Snap screen

Direction: AI-powered gamified learning for anyone, user-supplied content. UI first; no Supabase/auth/backend until the owner asks.
Signature feature: Snap -> Map -> Duel.

## Milestones
### UI: Snap -> Map -> Duel real screens (Design -> Build)
- [x] Owner reviews prototype and gives a verdict — keep as is (2026-10-12)
- [ ] Pick app name (Study Duel / Hoot / Owlduel) — deferred by owner, decide later; working name Exam Duel
- [ ] Commit current work (.claude/, docs/, prototype, global changes) — done when owner approves and tree is clean
- [ ] Snap screen real: type/paste/snap input, offline-safe, with AI-wait error and offline states — done when it runs on sample data and failure states show; run ui-review
- [ ] Map screen + topic tiles (New/Shaky/Solid/Ready) with "Show me where" and Report on every question — done when tiles update from sample answers; ui-review
- [ ] Solo practice and Duel/Results screens wired to the map — done when a tile can be practised solo and sent as a duel on sample data; ui-review
- [ ] Accessibility fixes: keyboard/focus on `Pressable`, TimerRing low-time contrast — done when keyboard-only flow works and contrast passes; ui-review
- [ ] Neutral starter content (less West-Africa-leaning) and README rewrite to new direction — done when no regional bias remains; security-check after code tasks

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
