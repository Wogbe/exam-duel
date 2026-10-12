---
name: project-state
description: Give a quick, factual state of the Exam Duel project (what's built, what's changed recently, whether analyze/tests pass, open TODOs, what's blocked, sensible next steps) and save it to docs/STATUS.md. Use at the start of a work session, when the user asks "where are we", or before planning the next step. Runs on Haiku in a separate context.
model: haiku
context: fork
background: false
---

# Project state

Gather facts with commands; don't guess. Don't change any file except `docs/STATUS.md`.

## 1. Collect

Run these from the repo root and note the results:
- `git status --short`, `git log --oneline -15`, `git branch --show-current`
- `command -v flutter`: if present, run `flutter analyze` and `flutter test` and
  record pass/fail counts. If Flutter isn't installed, write "not run (no Flutter
  SDK)" instead of failing.
- `ls android ios web 2>&1`: do the platform folders exist yet?
- `ls supabase/migrations supabase/functions supabase/tests 2>&1`
- `grep -rn "TODO\|FIXME\|HACK" lib supabase tool test | head -30`
- `ls .github/workflows`
- Read the README's "Ideas for next" and "Testing status" sections and the
  previous `docs/STATUS.md` (if any) to see what changed since then.
- `ls docs` for other reports (store checklist, feature ideas, design references).

## 2. Write `docs/STATUS.md` (overwrite it)

```
# Exam Duel status, <YYYY-MM-DD>
## Working
## Changed since last status
## Health        (analyze, tests, CI workflows)
## Open issues   (TODOs, failing checks, missing pieces)
## Blocked on the owner   (keys, accounts, decisions)
## Suggested next 3 steps
```

Keep each section to short bullets with `path:line` where useful.

## 3. Reply

Reply with the "Suggested next 3 steps" and any red flags in at most 10 lines.
