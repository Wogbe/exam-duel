---
name: backend
description: Build, change, check and battle-test Exam Duel's Supabase backend - Postgres schema and migrations, RLS, security-definer game functions (rooms, scoring, reveal, host hand-off), Realtime, anonymous auth, and the generate-questions edge function - plus the Dart side that calls it (lib/data/game_repository.dart, lib/state/room_controller.dart). Use when changing migrations, RPCs, RLS, auth or the edge function, or when the user asks to test or harden the backend. Not for quick questions about the backend (use research). Runs on Opus.
model: opus
effort: high
argument-hint: <task, or "battle-test" for a full test pass>
---

# Backend, database and auth

Task: $ARGUMENTS

## Ground rules

- **Never touch a hosted Supabase project** (`supabase db push`, `functions deploy`,
  `secrets set`, SQL in the dashboard) without the user's explicit OK for that step.
  Work locally.
- The design: clients never write tables; every change goes through `security
  definer` functions in `supabase/migrations/`. Answer keys live in
  `room_question_keys`, which no client may read. The server's clock decides scoring.
  Keep all of that true.
- Schema changes go in a **new** timestamped migration file. Only edit
  `20261009000000_init.sql` if the user confirms it has never been applied anywhere.
- Every `security definer` function: `set search_path = ''` (or `public`),
  fully qualified names, `_require_user()` first, membership/host checks before
  any write, and `revoke ... from public, anon` / `grant execute` only where intended.
- Look up current Supabase, PostgREST, Realtime, Deno and supabase_flutter
  behaviour with Context7 before relying on memory.
- Hand routine sub-steps (finding call sites, running test suites) to a
  `quick-helper` or `worker` agent; keep design and review here.

## Local setup

Prefer `supabase start` + `supabase db reset` (applies migrations and `seed.sql`).
If Docker or the CLI is missing, use a local PostgreSQL 16 with small stubs for
`auth.uid()`, the `anon`/`authenticated` roles and the `supabase_realtime`
publication, as the README describes. Put tests in `supabase/tests/` (pgTAP with
`supabase test db`, or plain SQL scripts that `raise exception` on failure) so they
can be re-run.

## Battle-test checklist

Simulate different users by setting `request.jwt.claims` / `role` per session.
1. **RLS**: for every table, try select/insert/update/delete as anon, as a
   non-member, as a member and as the host. Only intended reads succeed;
   `room_question_keys` and future `room_questions` rows are never readable.
2. **Function auth**: call every RPC for a room you're not in, as a non-host for
   host-only actions, with forged ids, and with null or oversized arguments.
3. **Game rules**: scoring (500 + speed, streak bonus cap), duplicate and late
   answers, early reveal when everyone answers, timeout reveal, 12 s advance
   fallback, host leaving, rematch, the 12-player limit, AI batch ordering.
4. **Concurrency**: run racing sessions in parallel (two `psql` processes or a
   small script): simultaneous `submit_answer` from one player, two players
   triggering `reveal_question`/`next_question` at once, join while starting,
   host leaving during reveal. There must be no double scoring, skipped
   questions or stuck rooms. Check row locks (`for update`) and idempotency.
5. **Abuse**: room-code guessing, nickname injection and length, settings JSON
   outside `_clean_settings`, flooding RPCs, the edge function's JWT and host
   check, the 120-questions/hour limit, prompt injection in the topic, and
   malformed model output.
6. **Client**: `game_repository.dart` handles every RPC error, Realtime
   reconnects and server-time sync. The app never ships a service-role key.
7. **Load**: a quick burst (e.g. 50 rooms × 8 players answering) to spot slow
   queries; check indexes with `explain analyze`.

## Finish

Run all tests and report: what changed (`path:line`), what was tested and
passed, what failed or is untested, and anything that needs the owner (deploys,
secrets, dashboard settings).
