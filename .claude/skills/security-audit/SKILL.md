---
name: security-audit
description: Full security review of Exam Duel on Opus - Supabase RLS and security-definer functions, auth, the AI edge function, secrets in the app and CI, client trust and cheating, privacy. Run it with /security-audit before a release or store submission, or after big backend or auth changes. Covers the whole app, not just the diff (the built-in /security-review only checks pending changes).
model: opus
effort: high
disable-model-invocation: true
argument-hint: <optional area, e.g. "edge function", "rls", "ci">
---

# Security audit

Scope: $ARGUMENTS (empty means the whole app). Read the code. Don't assume a
check exists because the README says so.

## Threat model

Players are anonymous Supabase users holding the public anon key. Anyone can
decompile the APK or read the web build, call any RPC directly, open many
accounts, and modify local storage. The attacker's goals: see answers early,
inflate scores, hijack or wreck other people's rooms, burn the Anthropic budget,
get offensive content shown to friends, or read other people's data.

## Check

1. **Database** (`supabase/migrations/`): RLS on every table with no
   over-broad policies; `room_question_keys` unreadable; a question row only
   visible once the room reaches it. Every `security definer` function sets
   `search_path`, checks `auth.uid()`, membership and host role, and validates
   inputs. Grants: no `execute` to `anon`/`public` on internal `_` functions.
   Realtime publications don't leak hidden columns.
2. **Game integrity**: server-side timing and scoring; no client-supplied score,
   time or correctness; duplicate and late answers rejected; races
   (`for update`); room-code entropy and join brute-force.
3. **Edge function** (`supabase/functions/generate-questions`): JWT verified
   and host checked server-side; per-user rate limit can't be bypassed with new
   anonymous accounts (is there a global cap?); topic length and prompt-injection
   handling; output validated and moderated before other players see it; no API
   key or stack trace in responses; CORS.
4. **Secrets**: `git grep -nE "sk-ant|service_role|eyJhbGci|SUPABASE_SERVICE|password"`
   across the whole history (`git log -p`), the `.github/workflows` files (secrets
   only via `${{ secrets.* }}`, no `pull_request_target` with checkout of PR code,
   pinned action versions), and `--dart-define`, which must carry only the anon key.
5. **Client** (`lib/`): nothing trusts local values for anything shared (coins
   and XP are local, so tampering is a low risk, but note it); `url_launcher`
   and WhatsApp share text are built safely; deep links; no debug logging of tokens.
6. **Privacy**: what's collected (anon id, nickname, answers, AI topics sent to
   Anthropic), how long rooms and answers are kept (`cleanup_rooms`), whether
   data can be deleted. This feeds the store privacy forms.

Use Context7 for current Supabase security guidance. Delegate pure searches
(e.g. listing every RPC) to a `quick-helper` agent.

## Report

Rank findings, most severe first. For each: severity (Critical/High/Medium/Low),
`path:line`, the concrete attack (who does what, and what happens), and the fix.
Then list what you checked and found sound. Don't change code unless the user
asks; then fix Critical and High first, with a test for each fix (see the `backend` skill).
