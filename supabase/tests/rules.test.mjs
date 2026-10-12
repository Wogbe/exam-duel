// Runs the migration on an in-memory Postgres (PGlite) with stubs for Supabase's auth and
// realtime pieces, then checks the game rules. Run: cd supabase/tests && npm install && npm test
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { before, describe, test } from 'node:test';
import { PGlite } from '@electric-sql/pglite';

const migration = readFileSync(new URL('../migrations/20261009000000_init.sql', import.meta.url), 'utf8');
const [A, B, C] = ['aaaaaaaa-0000-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000002', 'cccccccc-0000-0000-0000-000000000003'];

const db = new PGlite();

/** Runs sql as a signed-in user (or anonymous when uid is null), then goes back to superuser. */
async function as(uid, sql, params) {
  await db.query("select set_config('request.jwt.claim.sub', $1, false)", [uid ?? '']);
  await db.exec('set role authenticated');
  try {
    return (await db.query(sql, params)).rows;
  } finally {
    await db.exec('reset role');
  }
}

const one = async (uid, sql, params) => (await as(uid, sql, params))[0];
const rpc = async (uid, fn, args = []) => {
  const marks = args.map((_, i) => `$${i + 1}`).join(',');
  const row = (await as(uid, `select * from public.${fn}(${marks}) as r`, args))[0];
  return row.r ?? row;
};
const expire = (room, secs) =>
  db.query("update public.rooms set phase_started_at = now() - make_interval(secs => $2) where id = $1", [room, secs]);

before(async () => {
  await db.exec(`
    create role anon nologin; create role authenticated nologin;
    create schema auth;
    create function auth.uid() returns uuid language sql stable as
      $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
    grant usage on schema public, auth to anon, authenticated;
    grant execute on function auth.uid() to anon, authenticated;
    create publication supabase_realtime;
    -- Supabase gives anon/authenticated full access to new tables in public, so row-level
    -- security is the only thing that stops them. Copy that, or these tests prove nothing.
    alter default privileges in schema public grant all on tables to anon, authenticated;
    alter default privileges in schema public grant all on sequences to anon, authenticated;
  `);
  // PGlite has no pgcrypto, and the migration only needs gen_random_uuid(), which core Postgres has.
  await db.exec(migration.replace('create extension if not exists pgcrypto;', ''));
  for (let i = 0; i < 6; i++) {
    await db.query(
      "insert into public.questions (category, stem, options, correct_index) values ($1, $2, $3::jsonb, 1)",
      [i < 3 ? 'science' : 'history', `Q${i}`, JSON.stringify(['a', 'b', 'c', 'd'])],
    );
  }
});

async function newRoom(settings = { count: 3, seconds: 15 }) {
  const room = await rpc(A, 'create_room', ['Ama', 1, JSON.stringify(settings)]);
  await rpc(B, 'join_room', [room.code, 'Kofi', 2]);
  return room;
}

describe('rooms', () => {
  test('creating needs a signed-in user', async () => {
    await assert.rejects(rpc(null, 'create_room', ['x', 0, '{}']), /not signed in/);
  });

  test('create_room clamps settings and returns a 5-letter code', async () => {
    const room = await rpc(A, 'create_room', ['  Ama  ', 1, JSON.stringify({ count: 999, seconds: 1, topic: 'x'.repeat(200) })]);
    assert.match(room.code, /^[A-Z0-9]{5}$/);
    assert.equal(room.settings.count, 30);
    assert.equal(room.settings.seconds, 5);
    assert.equal(room.settings.topic.length, 80);
    const [me] = await as(A, 'select nickname, is_host from public.room_players where room_id = $1', [room.id]);
    assert.deepEqual(me, { nickname: 'Ama', is_host: true });
  });

  test('joining: unknown code, case-insensitive code, rejoin, full room', async () => {
    const room = await rpc(A, 'create_room', ['Ama', 1, '{}']);
    await assert.rejects(rpc(B, 'join_room', ['ZZZZZ', 'Kofi', 0]), /room not found/);
    await rpc(B, 'join_room', [room.code.toLowerCase(), 'Kofi', 0]);
    await rpc(B, 'join_room', [room.code, 'Kofi 2', 0]); // rejoin keeps one seat
    for (let i = 0; i < 10; i++) {
      await rpc(`dddddddd-0000-0000-0000-${String(i).padStart(12, '0')}`, 'join_room', [room.code, `P${i}`, 0]);
    }
    await assert.rejects(rpc(C, 'join_room', [room.code, 'Late', 0]), /room is full/);
  });

  test('host leaving hands the room to the earliest player; last one out deletes it', async () => {
    const room = await newRoom();
    await rpc(A, 'leave_room', [room.id]);
    const [r] = await db.query('select host_id from public.rooms where id = $1', [room.id]).then((x) => x.rows);
    assert.equal(r.host_id, B);
    await rpc(B, 'leave_room', [room.id]);
    const left = await db.query('select 1 from public.rooms where id = $1', [room.id]);
    assert.equal(left.rows.length, 0);
  });
});

describe('a game', () => {
  let room;
  before(async () => {
    room = await newRoom();
  });

  test('only the host starts, and only settings from the host are accepted', async () => {
    await assert.rejects(rpc(B, 'start_game', [room.id]), /only the host/);
    await assert.rejects(rpc(B, 'update_room_settings', [room.id, '{}']), /only the host/);
  });

  test('starting fills the room with questions and hides the answers', async () => {
    const started = await rpc(A, 'start_game', [room.id]);
    assert.equal(started.status, 'question');
    assert.equal(started.question_count, 3);
    assert.equal(started.current_index, 0);
    await assert.rejects(rpc(B, 'start_game', [room.id]), /only the host/);
    await assert.rejects(rpc(A, 'start_game', [room.id]), /already running/);

    const seen = await as(B, 'select idx, revealed_index from public.room_questions where room_id = $1', [room.id]);
    assert.deepEqual(seen, [{ idx: 0, revealed_index: null }], 'only the current question, no answer');
    assert.equal((await as(B, 'select * from public.room_question_keys')).length, 0, 'answer keys are never readable');
    await assert.rejects(as(B, "insert into public.rooms (code, host_id) values ('HACKS', $1)", [B]), /row-level security/);
    await as(B, 'update public.room_players set score = 99999');
    await as(B, 'delete from public.room_answers');
    const [top] = (await db.query('select max(score) as m from public.room_players')).rows;
    assert.ok(top.m < 99999, 'clients cannot edit scores');
  });

  test('outsiders see nothing of the room', async () => {
    assert.equal((await as(C, 'select 1 from public.rooms where id = $1', [room.id])).length, 0);
    await assert.rejects(rpc(C, 'submit_answer', [room.id, 0, 1]), /not in this room/);
  });

  test('scoring: right answer earns 500-1000, a repeat is ignored, wrong answer earns nothing', async () => {
    const right = await rpc(A, 'submit_answer', [room.id, 0, 1]);
    assert.equal(right.accepted, true);
    assert.equal(right.correct, true);
    assert.ok(right.points >= 500 && right.points <= 1000, `points ${right.points}`);
    assert.equal(right.streak, 1);
    assert.equal((await rpc(A, 'submit_answer', [room.id, 0, 1])).accepted, false, 'duplicate');
    assert.equal((await rpc(A, 'submit_answer', [room.id, 5, 1])).accepted, false, 'wrong question index');

    const wrong = await rpc(B, 'submit_answer', [room.id, 0, 3]);
    assert.deepEqual([wrong.accepted, wrong.correct, wrong.points, wrong.streak], [true, false, 0, 0]);
  });

  test('everyone answered, so the room reveals early and the answer becomes readable', async () => {
    const [r] = await db.query('select status from public.rooms where id = $1', [room.id]).then((x) => x.rows);
    assert.equal(r.status, 'reveal');
    const [q] = await as(B, 'select revealed_index from public.room_questions where room_id = $1 and idx = 0', [room.id]);
    assert.equal(q.revealed_index, 1);
  });

  test('next question: a guest must wait 12 s, the host can go on straight away', async () => {
    assert.equal((await rpc(B, 'next_question', [room.id, 0])).status, 'reveal');
    assert.equal((await rpc(A, 'next_question', [room.id, 0])).status, 'question');
    assert.equal((await rpc(A, 'next_question', [room.id, 0])).current_index, 1, 'stale index is a no-op');
  });

  test('timeout: reveal is refused early, then allowed; late answers are rejected; streak resets', async () => {
    assert.equal((await rpc(B, 'reveal_question', [room.id, 1])).status, 'question', 'timer still running');
    await rpc(A, 'submit_answer', [room.id, 1, 1]); // A answers, B stays silent
    await expire(room.id, 20);
    assert.equal((await rpc(B, 'submit_answer', [room.id, 1, 1])).accepted, false, 'late answer');
    assert.equal((await rpc(B, 'reveal_question', [room.id, 1])).status, 'reveal');
    const [b] = await db.query('select streak, last_points from public.room_players where user_id = $1 and room_id = $2', [B, room.id]).then((x) => x.rows);
    assert.deepEqual(b, { streak: 0, last_points: 0 });
  });

  test('a guest can move on after 12 s, and the last question ends the game', async () => {
    await expire(room.id, 13);
    assert.equal((await rpc(B, 'next_question', [room.id, 1])).current_index, 2);
    await rpc(A, 'submit_answer', [room.id, 2, 1]);
    await rpc(B, 'submit_answer', [room.id, 2, 1]);
    assert.equal((await rpc(A, 'next_question', [room.id, 2])).status, 'finished');
  });

  test('rematch resets scores and picks new questions', async () => {
    const again = await rpc(A, 'start_game', [room.id]);
    assert.equal(again.status, 'question');
    const scores = await db.query('select score, streak from public.room_players where room_id = $1', [room.id]);
    assert.ok(scores.rows.every((s) => s.score === 0 && s.streak === 0));
  });

  test('streak bonus: 3 right in a row score more than 1 right', async () => {
    const r = await newRoom({ count: 3, seconds: 60 });
    await rpc(A, 'start_game', [r.id]);
    const pts = [];
    for (let i = 0; i < 3; i++) {
      pts.push((await rpc(A, 'submit_answer', [r.id, i, 1])).points);
      await rpc(B, 'submit_answer', [r.id, i, 1]);
      await rpc(A, 'next_question', [r.id, i]);
    }
    assert.ok(pts[2] > pts[0], `points by round: ${pts}`);
  });
});

describe('cleanup', () => {
  test('old rooms are removed, and clients cannot call the cleanup', async () => {
    const room = await newRoom();
    // A trigger stamps updated_at on every update, so switch triggers off to backdate it.
    await db.exec('set session_replication_role = replica');
    await db.query("update public.rooms set updated_at = now() - interval '2 days' where id = $1", [room.id]);
    await db.exec('set session_replication_role = origin');
    await assert.rejects(rpc(A, 'cleanup_rooms'), /permission denied/);
    const removed = (await db.query('select public.cleanup_rooms() as n')).rows[0].n;
    assert.ok(removed >= 1);
  });
});
